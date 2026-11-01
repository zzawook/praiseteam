/// Rotation proposal: fills open slots fairly. Pure and deterministic, so
/// the same inputs always give the same plan (and it runs anywhere,
/// including the web build). The result is a set of drafts that a leader
/// reviews and edits before sending.
library;

/// A part of a session that needs [count] people; [day] is the session's
/// date in the team's time zone (blockouts are dates too).
class SlotNeed {
  const SlotNeed({required this.sessionId, required this.day, required this.partId, required this.count});
  final int sessionId;
  final DateTime day;
  final int partId;
  final int count;
}

class Candidate {
  const Candidate({required this.userId, required this.name, required this.partIds});
  final String userId;
  final String name;
  final Set<int> partIds;
}

/// Inclusive date range a person cannot serve.
class Unavailable {
  const Unavailable({required this.userId, required this.from, required this.to});
  final String userId;
  final DateTime from;
  final DateTime to;

  bool covers(DateTime day) => !day.isBefore(from) && !day.isAfter(to);
}

/// Someone serving (or asked to serve) on a day: past services within the
/// fairness window, and people already placed in the planned sessions.
class Serving {
  const Serving({required this.userId, required this.sessionId, required this.partId, required this.day});
  final String userId;
  final int sessionId;
  final int partId;
  final DateTime day;
}

class Proposal {
  const Proposal({required this.sessionId, required this.partId, required this.userId});
  final int sessionId;
  final int partId;
  final String userId;

  @override
  bool operator ==(Object other) =>
      other is Proposal && other.sessionId == sessionId && other.partId == partId && other.userId == userId;

  @override
  int get hashCode => Object.hash(sessionId, partId, userId);

  @override
  String toString() => 'Proposal($sessionId, $partId, $userId)';
}

/// How far back past services count toward fairness.
const fairnessWindow = Duration(days: 56);

/// Proposes people for every open place in [needs].
///
/// For each place, in session order: among members who play the part, are
/// not unavailable that day and are not already serving in that session,
/// pick whoever has served least (past [fairnessWindow] plus this batch),
/// then whoever served longest ago, then by name.
List<Proposal> proposeAssignments({
  required List<SlotNeed> needs,
  required List<Candidate> members,
  required List<Unavailable> unavailable,
  required List<Serving> history,
  required List<Serving> existing,
  required DateTime today,
}) {
  final windowStart = today.subtract(fairnessWindow);
  final load = <String, int>{};
  final lastServed = <String, DateTime>{};
  for (final s in history) {
    if (s.day.isBefore(windowStart)) continue;
    load[s.userId] = (load[s.userId] ?? 0) + 1;
    final last = lastServed[s.userId];
    if (last == null || s.day.isAfter(last)) lastServed[s.userId] = s.day;
  }

  final inSession = <int, Set<String>>{};
  final filled = <(int, int), int>{};
  for (final e in existing) {
    inSession.putIfAbsent(e.sessionId, () => {}).add(e.userId);
    filled[(e.sessionId, e.partId)] = (filled[(e.sessionId, e.partId)] ?? 0) + 1;
  }

  final ordered = [...needs]..sort((a, b) {
      final byDay = a.day.compareTo(b.day);
      if (byDay != 0) return byDay;
      final bySession = a.sessionId.compareTo(b.sessionId);
      return bySession != 0 ? bySession : a.partId.compareTo(b.partId);
    });

  final proposals = <Proposal>[];
  for (final need in ordered) {
    var open = need.count - (filled[(need.sessionId, need.partId)] ?? 0);
    while (open > 0) {
      final taken = inSession.putIfAbsent(need.sessionId, () => {});
      final pool = members
          .where((m) =>
              m.partIds.contains(need.partId) &&
              !taken.contains(m.userId) &&
              !unavailable.any((u) => u.userId == m.userId && u.covers(need.day)))
          .toList();
      if (pool.isEmpty) break;
      pool.sort((a, b) {
        final byLoad = (load[a.userId] ?? 0).compareTo(load[b.userId] ?? 0);
        if (byLoad != 0) return byLoad;
        final never = DateTime(1900);
        final byLast = (lastServed[a.userId] ?? never).compareTo(lastServed[b.userId] ?? never);
        if (byLast != 0) return byLast;
        final byName = a.name.compareTo(b.name);
        return byName != 0 ? byName : a.userId.compareTo(b.userId);
      });
      final pick = pool.first;
      proposals.add(Proposal(sessionId: need.sessionId, partId: need.partId, userId: pick.userId));
      taken.add(pick.userId);
      load[pick.userId] = (load[pick.userId] ?? 0) + 1;
      lastServed[pick.userId] = need.day;
      open--;
    }
  }
  return proposals;
}
