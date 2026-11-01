import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'models.dart';
import 'teams_providers.dart';

String partKindLabel(AppLocalizations l10n, PartKind kind) => switch (kind) {
  PartKind.vocal => l10n.partKindVocal,
  PartKind.instrument => l10n.partKindInstrument,
  PartKind.tech => l10n.partKindTech,
};

/// Bottom sheet to choose which parts a member can serve.
Future<void> showPartsPicker(
  BuildContext context, {
  required int teamId,
  required String userId,
  required List<int> selected,
  String? title, // defaults to "My parts"; leaders editing others pass the name
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _PartsPicker(teamId: teamId, userId: userId, initial: selected.toSet(), title: title),
);

class _PartsPicker extends ConsumerStatefulWidget {
  const _PartsPicker({required this.teamId, required this.userId, required this.initial, this.title});
  final int teamId;
  final String userId;
  final Set<int> initial;
  final String? title;

  @override
  ConsumerState<_PartsPicker> createState() => _PartsPickerState();
}

class _PartsPickerState extends ConsumerState<_PartsPicker> {
  late final Set<int> _selected = {...widget.initial};
  bool _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    final ok = await runGuarded(
      context,
      () => ref.read(teamsRepositoryProvider).setMemberParts(widget.teamId, widget.userId, _selected),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ref.invalidate(teamMembersProvider(widget.teamId));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final parts = ref.watch(teamPartsProvider(widget.teamId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: AsyncBody(
          value: parts,
          onRetry: () => ref.invalidate(teamPartsProvider(widget.teamId)),
          data: (parts) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title ?? l10n.myParts, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(l10n.partsPickerHint, style: theme.textTheme.bodyMedium),
              for (final kind in PartKind.values)
                if (parts.any((p) => p.kind == kind)) ...[
                  const SizedBox(height: 20),
                  Text(partKindLabel(l10n, kind), style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final part in parts.where((p) => p.kind == kind))
                        FilterChip(
                          label: Text(part.name),
                          selected: _selected.contains(part.id),
                          onSelected: (on) => setState(() => on ? _selected.add(part.id) : _selected.remove(part.id)),
                        ),
                    ],
                  ),
                ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _busy ? null : _save, child: Text(l10n.save)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Leaders add, rename and hide parts.
class PartsScreen extends ConsumerWidget {
  const PartsScreen({super.key, required this.teamId});
  final int teamId;

  Future<String?> _askName(BuildContext context, {String initial = ''}) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: InputDecoration(labelText: l10n.partName),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l10n.save)),
        ],
      ),
    );
  }

  /// Name of the new part and the part chats it joins. Chats made only of
  /// parts of the same kind (싱어팀 for a new vocal part) start ticked.
  Future<({String name, Set<int> chatIds})?> _askNewPart(
    BuildContext context,
    WidgetRef ref,
    PartKind kind,
    List<Part> parts,
  ) async {
    final l10n = AppLocalizations.of(context);
    final chats = await runGuardedValue(context, () => ref.read(teamsRepositoryProvider).partChats(teamId));
    if (chats == null || !context.mounted) return null;
    final kinds = {for (final p in parts) p.id: p.kind};
    final picked = {
      for (final c in chats)
        if (c.partIds.isNotEmpty && c.partIds.every((id) => kinds[id] == kind)) c.id,
    };
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.addPart),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                maxLength: 30,
                decoration: InputDecoration(labelText: l10n.partName),
              ),
              if (chats.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(l10n.partChatsToJoin, style: Theme.of(context).textTheme.labelLarge),
                for (final c in chats)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.name),
                    value: picked.contains(c.id),
                    onChanged: (on) => setState(() => on == true ? picked.add(c.id) : picked.remove(c.id)),
                  ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, name.text.trim().isNotEmpty), child: Text(l10n.save)),
          ],
        ),
      ),
    );
    return ok == true ? (name: name.text, chatIds: picked) : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final parts = ref.watch(teamPartsProvider(teamId));
    final repo = ref.read(teamsRepositoryProvider);
    void refresh() => ref.invalidate(teamPartsProvider(teamId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageParts)),
      body: AsyncBody(
        value: parts,
        onRetry: refresh,
        data: (parts) => ContentWidth(
          child: ListView(
            children: [
              for (final kind in PartKind.values) ...[
                SectionHeader(
                  partKindLabel(l10n, kind),
                  trailing: IconButton(
                    tooltip: l10n.addPart,
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      final added = await _askNewPart(context, ref, kind, parts);
                      if (added == null || !context.mounted) return;
                      if (await runGuarded(
                        context,
                        () => repo.addPart(teamId, added.name, kind, chatIds: added.chatIds),
                      )) {
                        refresh();
                      }
                    },
                  ),
                ),
                for (final part in parts.where((p) => p.kind == kind)) ...[
                  ListTile(
                    title: Text(part.name),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'rename') {
                          final name = await _askName(context, initial: part.name);
                          if (name == null || name.trim().isEmpty || !context.mounted) return;
                          if (await runGuarded(context, () => repo.renamePart(part.id, name))) refresh();
                        } else if (action == 'hide') {
                          if (await runGuarded(context, () => repo.hidePart(part.id))) refresh();
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'rename', child: Text(l10n.renamePart)),
                        PopupMenuItem(value: 'hide', child: Text(l10n.hidePart)),
                      ],
                    ),
                  ),
                  const Divider(indent: 20),
                ],
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
