import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth.dart';
import '../sessions/models.dart';
import '../teams/models.dart';
import '../teams/teams_providers.dart';
import 'auto_assign.dart';
import 'rotation_providers.dart';
import 'rotation_repository.dart';

String statusLabel(AppLocalizations l10n, AssignmentStatus s) => switch (s) {
      AssignmentStatus.draft => l10n.statusDraft,
      AssignmentStatus.pending => l10n.statusPending,
      AssignmentStatus.accepted => l10n.statusAccepted,
      AssignmentStatus.declined => l10n.statusDeclined,
    };

/// Where a serving request stands, in the same color and icon everywhere:
/// drafts in pencil, waiting in amber, accepted in green, declined in red.
(Color, IconData) statusLook(BuildContext context, AssignmentStatus status) {
  final palette = AppPalette.of(context);
  return switch (status) {
    AssignmentStatus.draft => (palette.draft, Icons.edit_outlined),
    AssignmentStatus.pending => (palette.pending, Icons.schedule),
    AssignmentStatus.accepted => (palette.accepted, Icons.check),
    AssignmentStatus.declined => (palette.declined, Icons.close),
  };
}

/// The schedule for the coming weeks: who serves where. Leaders fill it
/// (by hand or auto-assign), edit drafts freely, then send; members answer
/// and swap.
class RotationScreen extends ConsumerWidget {
  const RotationScreen({super.key, required this.teamId});
  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isLeader = ref.watch(activeMembershipProvider(teamId))?.role.isLeader ?? false;
    final board = ref.watch(rotationBoardProvider(teamId));
    final parts = ref.watch(teamPartsProvider(teamId)).value ?? const <Part>[];
    final drafts = board.value?.assignments.where((a) => a.status == AssignmentStatus.draft).toList() ?? const [];

    Future<void> autoAssign() async {
      var count = 0;
      if (await runGuarded(context, () async => count = await autoFill(ref, teamId)) && context.mounted) {
        showMessage(context, l10n.autoAssignDone(count));
      }
    }

    Future<void> send() async {
      final ok = await confirm(context, message: l10n.sendDraftsConfirm(drafts.length), confirmLabel: l10n.sendDrafts(drafts.length));
      if (!ok || !context.mounted) return;
      var count = 0;
      final sessions = {for (final d in drafts) d.sessionId}.toList();
      if (await runGuarded(context, () async => count = await ref.read(rotationRepositoryProvider).send(sessions))) {
        ref.invalidate(rotationBoardProvider(teamId));
        if (context.mounted) showMessage(context, l10n.sent(count));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rotation),
        actions: [
          TextButton(onPressed: () => context.push('/t/$teamId/blockouts'), child: Text(l10n.blockouts)),
          if (isLeader)
            PopupMenuButton<String>(
              onSelected: (v) => v == 'auto' ? autoAssign() : _editDefaults(context, ref, parts),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'auto', child: Text(l10n.autoAssign)),
                PopupMenuItem(value: 'defaults', child: Text(l10n.defaultNeeded)),
              ],
            ),
        ],
      ),
      bottomNavigationBar: isLeader && drafts.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: ContentWidth(child: FilledButton(onPressed: send, child: Text(l10n.sendDrafts(drafts.length)))),
              ),
            )
          : null,
      body: AsyncBody(
        value: board,
        onRetry: () => ref.invalidate(rotationBoardProvider(teamId)),
        data: (b) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(rotationBoardProvider(teamId)),
          child: ContentWidth(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 48),
              children: [
                if (isLeader && b.sessions.isNotEmpty && b.slots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: OutlinedButton(onPressed: () => _editDefaults(context, ref, parts), child: Text(l10n.defaultNeeded)),
                  ),
                for (final s in b.sessions) _SessionBlock(teamId: teamId, session: s, board: b, parts: parts, isLeader: isLeader),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editDefaults(BuildContext context, WidgetRef ref, List<Part> parts) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(rotationRepositoryProvider);
    final current = await repo.defaultSlots(teamId);
    if (!context.mounted) return;
    final counts = {for (final p in parts) p.id: current[p.id] ?? 0};
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.defaultNeeded),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.defaultNeededHint),
              const SizedBox(height: 8),
              for (final p in parts)
                Row(
                  children: [
                    Expanded(child: Text(p.name)),
                    IconButton(onPressed: counts[p.id]! > 0 ? () => setState(() => counts[p.id] = counts[p.id]! - 1) : null, icon: const Icon(Icons.remove)),
                    SizedBox(width: 24, child: Text('${counts[p.id]}', textAlign: TextAlign.center)),
                    IconButton(onPressed: counts[p.id]! < 20 ? () => setState(() => counts[p.id] = counts[p.id]! + 1) : null, icon: const Icon(Icons.add)),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    await runGuarded(context, () async {
      for (final p in parts) {
        if ((current[p.id] ?? 0) != counts[p.id]) await repo.setDefaultSlot(teamId, p.id, counts[p.id]!);
      }
      // Sessions on the board without any slots yet get the new defaults.
      final board = await ref.read(rotationBoardProvider(teamId).future);
      for (final s in board.sessions) {
        if (!board.slots.keys.any((k) => k.$1 == s.id)) {
          for (final p in parts) {
            if (counts[p.id]! > 0) await repo.setSlot(teamId, s.id, p.id, counts[p.id]!);
          }
        }
      }
    });
    ref.invalidate(rotationBoardProvider(teamId));
  }
}

class _SessionBlock extends ConsumerWidget {
  const _SessionBlock({required this.teamId, required this.session, required this.board, required this.parts, required this.isLeader});
  final int teamId;
  final Session session;
  final RotationBoard board;
  final List<Part> parts;
  final bool isLeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formats = DateFormats(context);
    final theme = Theme.of(context);
    final local = session.startsAt.toLocal();
    final shown = parts.where((p) => (board.slots[(session.id, p.id)] ?? 0) > 0 || board.of(session.id, p.id).isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => context.push('/t/$teamId/sessions/${session.id}'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
            child: Row(
              children: [
                Expanded(child: Text(session.title, style: theme.textTheme.titleMedium)),
                Text('${formats.dayWithWeekday(local)} ${formats.time(local)}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        for (final part in shown)
          _PartRow(
            teamId: teamId,
            session: session,
            part: part,
            needed: board.slots[(session.id, part.id)] ?? 0,
            people: board.of(session.id, part.id),
            swaps: board.swaps,
            isLeader: isLeader,
          ),
        const Divider(indent: 20),
      ],
    );
  }
}

class _PartRow extends ConsumerWidget {
  const _PartRow({
    required this.teamId,
    required this.session,
    required this.part,
    required this.needed,
    required this.people,
    required this.swaps,
    required this.isLeader,
  });
  final int teamId;
  final Session session;
  final Part part;
  final int needed;
  final List<Assignment> people;
  final Map<int, SwapRequest> swaps;
  final bool isLeader;

  void _refresh(WidgetRef ref) => ref.invalidate(rotationBoardProvider(teamId));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final me = ref.watch(currentUserIdProvider);
    final active = people.where((a) => a.status != AssignmentStatus.declined).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: InkWell(
              onTap: isLeader ? () => _editNeeded(context, ref) : null,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${part.name}  ${l10n.needed(needed)}', style: theme.textTheme.bodySmall),
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final a in people)
                  _PersonChip(
                    teamId: teamId,
                    assignment: a,
                    swap: swaps[a.id],
                    isMe: a.userId == me,
                    isLeader: isLeader,
                    part: part,
                    pickPerson: (exclude) => _pickPerson(context, ref, exclude: exclude),
                  ),
                if (isLeader && active < needed)
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(l10n.addPerson),
                    onPressed: () async {
                      final userId = await _pickPerson(context, ref, exclude: {for (final a in people) a.userId});
                      if (userId == null || !context.mounted) return;
                      final repo = ref.read(rotationRepositoryProvider);
                      final place = Proposal(sessionId: session.id, partId: part.id, userId: userId);
                      if (await runGuarded(context, () => repo.addDrafts(teamId, [place], source: 'manual'))) {
                        _refresh(ref);
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editNeeded(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    var count = needed;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${part.name} ${l10n.setNeeded}'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: count > 0 ? () => setState(() => count--) : null, icon: const Icon(Icons.remove)),
              Text('$count', style: Theme.of(context).textTheme.headlineSmall),
              IconButton(onPressed: count < 20 ? () => setState(() => count++) : null, icon: const Icon(Icons.add)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    if (await runGuarded(context, () => ref.read(rotationRepositoryProvider).setSlot(teamId, session.id, part.id, count))) _refresh(ref);
  }

  /// Members who play this part; unavailable or already-serving people are
  /// shown but disabled.
  Future<String?> _pickPerson(BuildContext context, WidgetRef ref, {required Set<String> exclude}) async {
    final l10n = AppLocalizations.of(context);
    final members = await ref.read(teamMembersProvider(teamId).future);
    final blocked = await ref.read(blockoutsProvider(teamId).future);
    final board = await ref.read(rotationBoardProvider(teamId).future);
    final local = session.startsAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final serving = {for (final a in board.assignments) if (a.sessionId == session.id && a.status != AssignmentStatus.declined) a.userId};
    final candidates = members.where((m) => m.status == MemberStatus.active && m.partIds.contains(part.id)).toList();
    if (!context.mounted) return null;
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final m in candidates)
              Builder(builder: (context) {
                final unavailable = blocked.any((b) => b.userId == m.userId && !day.isBefore(b.from) && !day.isAfter(b.to));
                final busy = serving.contains(m.userId) || exclude.contains(m.userId);
                return ListTile(
                  enabled: !unavailable && !busy,
                  title: Text(m.profile.displayName),
                  subtitle: unavailable ? Text(l10n.unavailableThatDay) : (busy ? Text(l10n.alreadyServing) : null),
                  onTap: () => Navigator.pop(context, m.userId),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _PersonChip extends ConsumerWidget {
  const _PersonChip({
    required this.teamId,
    required this.assignment,
    required this.swap,
    required this.isMe,
    required this.isLeader,
    required this.part,
    required this.pickPerson,
  });
  final int teamId;
  final Assignment assignment;
  final SwapRequest? swap;
  final bool isMe;
  final bool isLeader;
  final Part part;

  /// Opens the person picker of this part, excluding the given people.
  final Future<String?> Function(Set<String> exclude) pickPerson;

  void _refresh(WidgetRef ref) => ref.invalidate(rotationBoardProvider(teamId));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final a = assignment;
    final repo = ref.read(rotationRepositoryProvider);

    final (color, icon) = statusLook(context, a.status);

    final actions = <(String, Future<void> Function())>[
      if (isMe && a.status != AssignmentStatus.draft) ...[
        if (a.status != AssignmentStatus.accepted) (l10n.accept, () => repo.respond(a.id, accept: true)),
        if (a.status != AssignmentStatus.declined)
          (l10n.decline, () async {
            final reason = await _ask(context, l10n.declineReason);
            if (reason != null) await repo.respond(a.id, accept: false, reason: reason);
          }),
        if (swap == null && a.status != AssignmentStatus.declined)
          (l10n.requestSwap, () async {
            final message = await _ask(context, l10n.swapMessage);
            if (message != null) await repo.requestSwap(a.id, message);
          }),
        if (swap != null) (l10n.cancelSwap, () => repo.cancelSwap(swap!.id)),
      ],
      if (!isMe && swap != null) (l10n.takeSwap, () => repo.acceptSwap(swap!.id)),
      if (isLeader) ...[
        (l10n.replacePerson, () async {
          final userId = await pickPerson({a.userId});
          if (userId == null) return;
          a.status == AssignmentStatus.draft ? await repo.replaceDraft(a.id, userId) : await repo.reassign(a.id, userId);
        }),
        (l10n.removePerson, () => a.status == AssignmentStatus.draft ? repo.deleteDraft(a.id) : repo.remove(a.id)),
      ],
    ];

    return InputChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(swap == null ? a.userName : '${a.userName} (${l10n.swapOpen})'),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
        decoration: a.status == AssignmentStatus.declined ? TextDecoration.lineThrough : null,
      ),
      // Accepted is settled, so it is filled; the rest are open questions.
      backgroundColor: a.status == AssignmentStatus.accepted ? color.withValues(alpha: 0.14) : null,
      side: BorderSide(color: color.withValues(alpha: a.status == AssignmentStatus.accepted ? 0.0 : 0.6)),
      tooltip: statusLabel(l10n, a.status),
      onPressed: actions.isEmpty
          ? null
          : () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (sheet) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(title: Text('${a.userName}  ${part.name}'), subtitle: Text(statusLabel(l10n, a.status))),
                      for (final (label, run) in actions)
                        ListTile(
                          title: Text(label),
                          onTap: () async {
                            Navigator.pop(sheet);
                            if (await runGuarded(context, run)) _refresh(ref);
                          },
                        ),
                    ],
                  ),
                ),
              ),
    );
  }

  Future<String?> _ask(BuildContext context, String label) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(controller: controller, autofocus: true, maxLength: 200, decoration: InputDecoration(labelText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l10n.save)),
        ],
      ),
    );
  }
}
