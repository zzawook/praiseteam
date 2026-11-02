import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth.dart';
import '../teams/teams_providers.dart';
import 'rotation_providers.dart';
import 'rotation_repository.dart';

/// Dates a member can't serve. Leaders also see everyone's, to plan.
class BlockoutsScreen extends ConsumerWidget {
  const BlockoutsScreen({super.key, required this.teamId});
  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentUserIdProvider);
    final isLeader = ref.watch(activeMembershipProvider(teamId))?.role.isLeader ?? false;
    final blockouts = ref.watch(blockoutsProvider(teamId));
    final names = {
      for (final m in ref.watch(teamMembersProvider(teamId)).value ?? const []) m.userId: m.profile.displayName,
    };

    Future<void> add() async {
      final now = ref.read(teamTimeProvider(teamId)).now();
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: DateTime(now.year + 2),
      );
      if (range == null || !context.mounted) return;
      final note = TextEditingController();
      final save = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: TextField(
            controller: note,
            maxLength: 200,
            decoration: InputDecoration(labelText: l10n.blockoutNote),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
          ],
        ),
      );
      if (save != true || !context.mounted) return;
      if (await runGuarded(
        context,
        () => ref.read(rotationRepositoryProvider).addBlockout(teamId, range.start, range.end, note.text),
      )) {
        ref.invalidate(blockoutsProvider(teamId));
      }
    }

    Widget row(Blockout b, {required bool mine}) {
      final f = DateFormats(context);
      final when = b.from == b.to ? f.calendarDate(b.from) : '${f.calendarDate(b.from)} – ${f.calendarDate(b.to)}';
      return ListTile(
        title: Text(mine ? when : '${names[b.userId] ?? ''}  $when'),
        subtitle: b.note == null ? null : Text(b.note!),
        trailing: mine
            ? IconButton(
                tooltip: l10n.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (await runGuarded(context, () => ref.read(rotationRepositoryProvider).deleteBlockout(b.id))) {
                    ref.invalidate(blockoutsProvider(teamId));
                  }
                },
              )
            : null,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.blockouts)),
      body: AsyncBody(
        value: blockouts,
        onRetry: () => ref.invalidate(blockoutsProvider(teamId)),
        data: (all) {
          final time = ref.watch(teamTimeProvider(teamId));
          final today = time.date(time.now());
          final upcoming = all.where((b) => !b.to.isBefore(today)).toList();
          final mine = upcoming.where((b) => b.userId == me).toList();
          final others = upcoming.where((b) => b.userId != me).toList();
          return ContentWidth(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                SectionHeader(
                  l10n.myBlockouts,
                  trailing: AddButton(label: l10n.addBlockout, onPressed: add),
                ),
                if (mine.isEmpty)
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(l10n.noBlockouts)),
                for (final b in mine) row(b, mine: true),
                if (isLeader) ...[
                  SectionHeader(l10n.teamBlockouts),
                  if (others.isEmpty)
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(l10n.noBlockouts)),
                  for (final b in others) row(b, mine: false),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
