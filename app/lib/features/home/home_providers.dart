import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/providers.dart';
import '../rotation/rehearsals.dart';
import '../rotation/rotation_providers.dart';
import '../rotation/rotation_repository.dart';
import '../sessions/models.dart';

part 'home_providers.g.dart';

/// How far ahead "my schedule" looks.
const scheduleWindow = Duration(days: 28);

/// How far ahead rehearsal answers count as a to-do.
const rsvpWindow = Duration(days: 14);

/// Rehearsals in the next four weeks, for to-dos and my schedule.
@riverpod
Future<List<Rehearsal>> upcomingRehearsals(Ref ref, int teamId) {
  ref.watch(onlineStatusProvider.select((s) => s.epoch));
  return ref.watch(rehearsalsRepositoryProvider).upcoming(teamId, until: DateTime.now().add(scheduleWindow));
}

/// Times each person was asked to serve (sent requests) in the last 8 weeks.
@riverpod
Future<Map<String, int>> servingCounts(Ref ref, int teamId) async {
  final now = DateTime.now();
  final history = await ref
      .watch(rotationRepositoryProvider)
      .history(teamId, since: now.subtract(const Duration(days: 56)), before: now);
  final counts = <String, int>{};
  for (final s in history) {
    counts[s.userId] = (counts[s.userId] ?? 0) + 1;
  }
  return counts;
}

/// Where one service's rotation stands, for leaders.
class Readiness {
  const Readiness({
    required this.needed,
    required this.accepted,
    required this.waiting,
    required this.declined,
    required this.unsent,
  });

  /// Places to fill (the service's slots).
  final int needed;
  final int accepted;
  final int waiting;
  final int declined;

  /// Drafts not sent yet.
  final int unsent;

  /// People in place, answered or not (declines leave a gap).
  int get filled => accepted + waiting + unsent;
  bool get complete => needed > 0 && accepted >= needed;

  factory Readiness.of(Session session, RotationBoard board) {
    var needed = 0;
    board.slots.forEach((key, count) {
      if (key.$1 == session.id) needed += count;
    });
    final here = board.assignments.where((a) => a.sessionId == session.id).toList();
    int count(AssignmentStatus status) => here.where((a) => a.status == status).length;
    return Readiness(
      needed: needed,
      accepted: count(AssignmentStatus.accepted),
      waiting: count(AssignmentStatus.pending),
      declined: count(AssignmentStatus.declined),
      unsent: count(AssignmentStatus.draft),
    );
  }
}

/// Rehearsal answers from the people serving at its service.
class RsvpTally {
  const RsvpTally({required this.coming, required this.notComing, required this.noAnswer});
  final int coming;
  final int notComing;
  final int noAnswer;
  int get total => coming + notComing + noAnswer;

  /// Late still counts as coming.
  factory RsvpTally.of(Rehearsal rehearsal, Iterable<String> serving) {
    var coming = 0, notComing = 0, noAnswer = 0;
    for (final userId in serving.toSet()) {
      switch (rehearsal.responses[userId]?.rsvp) {
        case Rsvp.going || Rsvp.late:
          coming++;
        case Rsvp.notGoing:
          notComing++;
        case null:
          noAnswer++;
      }
    }
    return RsvpTally(coming: coming, notComing: notComing, noAnswer: noAnswer);
  }
}
