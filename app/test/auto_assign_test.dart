import 'package:flutter_test/flutter_test.dart';
import 'package:praiseteam/features/rotation/auto_assign.dart';

const keys = 1, vocals = 2, drums = 3;

final members = [
  const Candidate(userId: 'a', name: '가은', partIds: {keys}),
  const Candidate(userId: 'b', name: '나래', partIds: {keys, vocals}),
  const Candidate(userId: 'c', name: '다인', partIds: {vocals}),
  const Candidate(userId: 'd', name: '라희', partIds: {vocals, drums}),
];

DateTime d(int day) => DateTime(2026, 11, day);

void main() {
  final today = d(1);

  test('rotates keys fairly across four Sundays', () {
    final needs = [for (final day in [8, 15, 22, 29]) SlotNeed(sessionId: day, day: d(day), partId: keys, count: 1)];
    final plan = proposeAssignments(needs: needs, members: members, unavailable: const [], history: const [], existing: const [], today: today);
    expect([for (final p in plan) p.userId], ['a', 'b', 'a', 'b'], reason: 'equal load alternates, names break the first tie');
  });

  test('past services in the window count; older ones do not', () {
    final needs = [SlotNeed(sessionId: 8, day: d(8), partId: keys, count: 1)];
    final history = [
      Serving(userId: 'a', sessionId: 100, partId: keys, day: d(1).subtract(const Duration(days: 7))),
      Serving(userId: 'b', sessionId: 101, partId: keys, day: d(1).subtract(const Duration(days: 120))),
    ];
    final plan = proposeAssignments(needs: needs, members: members, unavailable: const [], history: history, existing: const [], today: today);
    expect(plan.single.userId, 'b', reason: 'a served recently; b only outside the fairness window');
  });

  test('skips people who are unavailable that day', () {
    final needs = [SlotNeed(sessionId: 8, day: d(8), partId: keys, count: 1)];
    final plan = proposeAssignments(
      needs: needs,
      members: members,
      unavailable: [Unavailable(userId: 'a', from: d(7), to: d(9))],
      history: const [],
      existing: const [],
      today: today,
    );
    expect(plan.single.userId, 'b');
  });

  test('never puts one person in two parts of the same session', () {
    final needs = [
      SlotNeed(sessionId: 8, day: d(8), partId: keys, count: 1),
      SlotNeed(sessionId: 8, day: d(8), partId: vocals, count: 3),
    ];
    final plan = proposeAssignments(needs: needs, members: members, unavailable: const [], history: const [], existing: const [], today: today);
    final people = [for (final p in plan) p.userId];
    expect(people.toSet().length, people.length);
    expect(plan.where((p) => p.partId == vocals).length, 3, reason: 'a takes keys (first by name); b, c and d sing');
  });

  test('fills only what is still open and leaves existing people alone', () {
    final needs = [SlotNeed(sessionId: 8, day: d(8), partId: vocals, count: 2)];
    final existing = [Serving(userId: 'c', sessionId: 8, partId: vocals, day: d(8))];
    final plan = proposeAssignments(needs: needs, members: members, unavailable: const [], history: const [], existing: existing, today: today);
    expect(plan.length, 1);
    expect(plan.single.userId, isNot('c'));
  });

  test('stops when nobody is left instead of double-booking', () {
    final needs = [SlotNeed(sessionId: 8, day: d(8), partId: drums, count: 2)];
    final plan = proposeAssignments(needs: needs, members: members, unavailable: const [], history: const [], existing: const [], today: today);
    expect([for (final p in plan) p.userId], ['d']);
  });

  test('same input, same plan', () {
    final needs = [for (final day in [8, 15]) SlotNeed(sessionId: day, day: d(day), partId: vocals, count: 2)];
    List<Proposal> run() => proposeAssignments(needs: needs, members: members, unavailable: const [], history: const [], existing: const [], today: today);
    expect(run(), run());
  });
}
