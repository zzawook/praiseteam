import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/providers.dart';
import '../teams/models.dart';
import '../teams/teams_providers.dart';
import 'auto_assign.dart';
import 'rotation_repository.dart';

part 'rotation_providers.g.dart';

/// How far ahead the rotation board looks.
const boardWeeks = 8;

@Riverpod(keepAlive: true)
RotationRepository rotationRepository(Ref ref) => RotationRepository(ref.watch(supabaseProvider));

DateTime _startOfToday() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

@riverpod
Future<RotationBoard> rotationBoard(Ref ref, int teamId) {
  final from = _startOfToday();
  return ref.watch(rotationRepositoryProvider).board(teamId, from: from, to: from.add(const Duration(days: 7 * boardWeeks)));
}

/// Visible blockouts: your own, and everyone's for leaders (RLS).
@riverpod
Future<List<Blockout>> blockouts(Ref ref, int teamId) => ref.watch(rotationRepositoryProvider).blockouts(teamId);

/// Fills every open place on the board with drafts; returns how many.
Future<int> autoFill(WidgetRef ref, int teamId) async {
  final repo = ref.read(rotationRepositoryProvider);
  final today = _startOfToday();
  final (board, members, history, blocked) = await (
    ref.read(rotationBoardProvider(teamId).future),
    ref.read(teamMembersProvider(teamId).future),
    repo.history(teamId, since: today.subtract(fairnessWindow), before: today),
    repo.blockouts(teamId),
  ).wait;

  DateTime dayOf(DateTime t) => DateTime(t.toLocal().year, t.toLocal().month, t.toLocal().day);
  final sessionDay = {for (final s in board.sessions) s.id: dayOf(s.startsAt)};

  final proposals = proposeAssignments(
    needs: [
      for (final MapEntry(key: (sessionId, partId), value: count) in board.slots.entries)
        if (count > 0) SlotNeed(sessionId: sessionId, day: sessionDay[sessionId]!, partId: partId, count: count),
    ],
    members: [
      for (final m in members)
        if (m.status == MemberStatus.active) Candidate(userId: m.userId, name: m.profile.displayName, partIds: m.partIds.toSet()),
    ],
    unavailable: [for (final b in blocked) Unavailable(userId: b.userId, from: b.from, to: b.to)],
    history: history,
    existing: [
      for (final a in board.assignments)
        if (a.status != AssignmentStatus.declined)
          Serving(userId: a.userId, sessionId: a.sessionId, partId: a.partId, day: sessionDay[a.sessionId]!),
    ],
    today: today,
  );
  await repo.addDrafts(teamId, proposals, source: 'auto');
  ref.invalidate(rotationBoardProvider(teamId));
  return proposals.length;
}
