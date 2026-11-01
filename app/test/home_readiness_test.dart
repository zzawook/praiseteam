import 'package:flutter_test/flutter_test.dart';
import 'package:praiseteam/features/home/home_providers.dart';
import 'package:praiseteam/features/rotation/rehearsals.dart';
import 'package:praiseteam/features/rotation/rotation_repository.dart';
import 'package:praiseteam/features/sessions/models.dart';

Session session(int id) =>
    Session(id: id, teamId: 1, title: 'S$id', startsAt: DateTime(2026, 11, 8, 11), setlistStatus: SetlistStatus.draft);

Assignment assignment(int id, int session, String user, AssignmentStatus status) =>
    Assignment(id: id, sessionId: session, partId: 1, userId: user, userName: user, status: status);

void main() {
  test('readiness counts one service: places, answers, drafts', () {
    final board = RotationBoard(
      sessions: [session(1), session(2)],
      slots: {(1, 1): 2, (1, 2): 3, (2, 1): 1},
      assignments: [
        assignment(1, 1, 'a', AssignmentStatus.accepted),
        assignment(2, 1, 'b', AssignmentStatus.accepted),
        assignment(3, 1, 'c', AssignmentStatus.pending),
        assignment(4, 1, 'd', AssignmentStatus.declined),
        assignment(5, 1, 'e', AssignmentStatus.draft),
        assignment(6, 2, 'a', AssignmentStatus.accepted),
      ],
      swaps: const {},
    );
    final r = Readiness.of(session(1), board);
    expect((r.needed, r.accepted, r.waiting, r.declined, r.unsent), (5, 2, 1, 1, 1));
    expect(r.filled, 4, reason: 'a decline leaves its place open');
    expect(r.complete, isFalse);
    expect(Readiness.of(session(2), board).complete, isTrue);
  });

  test('a service without places is never complete', () {
    const board = RotationBoard(sessions: [], slots: {}, assignments: [], swaps: {});
    expect(Readiness.of(session(1), board).complete, isFalse);
  });

  test('rehearsal answers count only the people serving, late as coming', () {
    final rehearsal = Rehearsal(
      id: 1,
      startsAt: DateTime(2026, 11, 7, 19),
      sessionId: 1,
      responses: {
        'a': (rsvp: Rsvp.going, attendance: null),
        'b': (rsvp: Rsvp.late, attendance: null),
        'c': (rsvp: Rsvp.notGoing, attendance: null),
        'z': (rsvp: Rsvp.going, attendance: null), // not serving: not counted
      },
    );
    final tally = RsvpTally.of(rehearsal, ['a', 'b', 'c', 'd', 'd']);
    expect((tally.coming, tally.notComing, tally.noAnswer, tally.total), (2, 1, 1, 4));
  });
}
