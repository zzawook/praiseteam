import 'package:supabase_flutter/supabase_flutter.dart' hide Session;

import '../sessions/models.dart';
import 'auto_assign.dart';

enum AssignmentStatus { draft, pending, accepted, declined }

class Assignment {
  const Assignment({
    required this.id,
    required this.sessionId,
    required this.partId,
    required this.userId,
    required this.userName,
    required this.status,
    this.declineReason,
  });

  factory Assignment.fromRow(Map<String, dynamic> r) => Assignment(
        id: r['id'] as int,
        sessionId: r['session_id'] as int,
        partId: r['part_id'] as int,
        userId: r['user_id'] as String,
        userName: ((r['team_members'] as Map?)?['profiles'] as Map?)?['display_name'] as String? ?? '',
        status: AssignmentStatus.values.byName(r['status'] as String),
        declineReason: r['decline_reason'] as String?,
      );

  final int id;
  final int sessionId;
  final int partId;
  final String userId;
  final String userName;
  final AssignmentStatus status;
  final String? declineReason;
}

class SwapRequest {
  const SwapRequest({required this.id, required this.assignmentId, required this.requestedBy, this.message});
  factory SwapRequest.fromRow(Map<String, dynamic> r) => SwapRequest(
        id: r['id'] as int,
        assignmentId: r['assignment_id'] as int,
        requestedBy: r['requested_by'] as String,
        message: r['message'] as String?,
      );
  final int id;
  final int assignmentId;
  final String requestedBy;
  final String? message;
}

class Blockout {
  const Blockout({required this.id, required this.userId, required this.from, required this.to, this.note});
  factory Blockout.fromRow(Map<String, dynamic> r) => Blockout(
        id: r['id'] as int,
        userId: r['user_id'] as String,
        from: DateTime.parse(r['starts_on'] as String),
        to: DateTime.parse(r['ends_on'] as String),
        note: r['note'] as String?,
      );
  final int id;
  final String userId;
  final DateTime from;
  final DateTime to;
  final String? note;
}

/// Everything the rotation screens show for a range of sessions.
class RotationBoard {
  const RotationBoard({
    required this.sessions,
    required this.slots,
    required this.assignments,
    required this.swaps,
  });
  final List<Session> sessions;

  /// (session, part) -> people needed
  final Map<(int, int), int> slots;
  final List<Assignment> assignments;

  /// Open swap requests by assignment id.
  final Map<int, SwapRequest> swaps;

  List<Assignment> of(int sessionId, int partId) =>
      [for (final a in assignments) if (a.sessionId == sessionId && a.partId == partId) a];
}

class RotationRepository {
  RotationRepository(this._db);
  final SupabaseClient _db;

  static const _assignmentColumns =
      'id, session_id, part_id, user_id, status, decline_reason, team_members(profiles(display_name))';

  Future<RotationBoard> board(int teamId, {required DateTime from, required DateTime to}) async {
    final sessions = (await _db
            .from('sessions')
            .select('id, team_id, title, starts_at, location, theme, notes, setlist_status, published_at')
            .eq('team_id', teamId)
            .gte('starts_at', from.toUtc().toIso8601String())
            .lt('starts_at', to.toUtc().toIso8601String())
            .order('starts_at', ascending: true))
        .map(Session.fromJson)
        .toList();
    final ids = [for (final s in sessions) s.id];
    if (ids.isEmpty) return const RotationBoard(sessions: [], slots: {}, assignments: [], swaps: {});

    final (slots, assignments, swaps) = await (
      _db.from('session_slots').select('session_id, part_id, count').inFilter('session_id', ids),
      _db.from('assignments').select(_assignmentColumns).inFilter('session_id', ids),
      _db.from('swap_requests').select('id, assignment_id, requested_by, message').eq('team_id', teamId).eq('status', 'open'),
    ).wait;
    return RotationBoard(
      sessions: sessions,
      slots: {for (final r in slots) (r['session_id'] as int, r['part_id'] as int): r['count'] as int},
      assignments: assignments.map(Assignment.fromRow).toList(),
      swaps: {for (final r in swaps) r['assignment_id'] as int: SwapRequest.fromRow(r)},
    );
  }

  /// Sent (non-draft, not declined) services before [before], for fairness.
  Future<List<Serving>> history(int teamId, {required DateTime since, required DateTime before}) async {
    final rows = await _db
        .from('assignments')
        .select('user_id, session_id, part_id, sessions!inner(starts_at)')
        .eq('team_id', teamId)
        .inFilter('status', ['pending', 'accepted'])
        .gte('sessions.starts_at', since.toUtc().toIso8601String())
        .lt('sessions.starts_at', before.toUtc().toIso8601String());
    return [
      for (final r in rows)
        Serving(
          userId: r['user_id'] as String,
          sessionId: r['session_id'] as int,
          partId: r['part_id'] as int,
          day: DateTime.parse((r['sessions'] as Map)['starts_at'] as String).toLocal(),
        ),
    ];
  }

  Future<List<Blockout>> blockouts(int teamId) async =>
      (await _db.from('blockouts').select('id, user_id, starts_on, ends_on, note').eq('team_id', teamId).order('starts_on', ascending: true))
          .map(Blockout.fromRow)
          .toList();

  Future<void> addBlockout(int teamId, DateTime from, DateTime to, String? note) => _db.from('blockouts').insert({
        'team_id': teamId,
        'starts_on': _date(from),
        'ends_on': _date(to),
        'note': ?(note == null || note.trim().isEmpty ? null : note.trim()),
      });

  Future<void> deleteBlockout(int id) => _db.from('blockouts').delete().eq('id', id);

  Future<void> setSlot(int teamId, int sessionId, int partId, int count) => _db.from('session_slots').upsert(
        {'team_id': teamId, 'session_id': sessionId, 'part_id': partId, 'count': count},
        onConflict: 'session_id,part_id',
      );

  Future<Map<int, int>> defaultSlots(int teamId) async => {
        for (final r in await _db.from('default_slots').select('part_id, count').eq('team_id', teamId))
          r['part_id'] as int: r['count'] as int,
      };

  Future<void> setDefaultSlot(int teamId, int partId, int count) => count <= 0
      ? _db.from('default_slots').delete().eq('team_id', teamId).eq('part_id', partId)
      : _db.from('default_slots').upsert({'team_id': teamId, 'part_id': partId, 'count': count}, onConflict: 'team_id,part_id');

  Future<void> addDrafts(int teamId, Iterable<Proposal> proposals, {required String source}) {
    final rows = [
      for (final p in proposals)
        {'team_id': teamId, 'session_id': p.sessionId, 'part_id': p.partId, 'user_id': p.userId, 'source': source},
    ];
    return rows.isEmpty ? Future.value() : _db.from('assignments').insert(rows);
  }

  Future<void> deleteDraft(int id) => _db.from('assignments').delete().eq('id', id);

  Future<void> replaceDraft(int id, String userId) =>
      _db.from('assignments').update({'user_id': userId, 'source': 'manual'}).eq('id', id);

  Future<int> send(List<int> sessionIds) async =>
      await _db.rpc('send_assignments', params: {'p_session_ids': sessionIds}) as int;

  Future<void> reassign(int id, String userId) =>
      _db.rpc('reassign_assignment', params: {'p_assignment_id': id, 'p_user_id': userId});

  Future<void> remove(int id) => _db.rpc('remove_assignment', params: {'p_assignment_id': id});

  Future<void> respond(int id, {required bool accept, String? reason}) => _db.rpc(
        'respond_assignment',
        params: {'p_assignment_id': id, 'p_accept': accept, 'p_reason': reason},
      );

  Future<void> requestSwap(int assignmentId, String? message) =>
      _db.rpc('request_swap', params: {'p_assignment_id': assignmentId, 'p_message': message});

  Future<void> acceptSwap(int swapId) => _db.rpc('accept_swap', params: {'p_swap_id': swapId});

  Future<void> cancelSwap(int swapId) => _db.rpc('cancel_swap', params: {'p_swap_id': swapId});

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
