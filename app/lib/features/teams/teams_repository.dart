import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/offline/offline_store.dart';
import 'models.dart';

/// Team, membership and part data. Multi-step changes go through the
/// database RPCs, which enforce the role rules (see foundation migration).
class TeamsRepository {
  TeamsRepository(this._db, this._offline);
  final SupabaseClient _db;
  final ReadThrough _offline;

  static const _teamColumns = 'id, name, timezone, invite_code, join_requires_approval';

  /// Kept on the device: without it the app could not open offline.
  Future<List<Membership>> myMemberships(String userId) async {
    final rows = await _offline.list(
      'memberships',
      () => _db
          .from('team_members')
          .select('team_id, role, status, teams($_teamColumns)')
          .eq('user_id', userId)
          .order('joined_at', ascending: true),
    );
    return rows.map(Membership.fromJson).toList();
  }

  Future<int> createTeam(String name) async =>
      await _db.rpc('create_team', params: {'p_name': name.trim()}) as int;

  Future<int> joinTeam(String inviteCode) async =>
      await _db.rpc('join_team', params: {'p_invite_code': inviteCode}) as int;

  Future<List<Member>> members(int teamId) async {
    final rows = await _db
        .from('team_members')
        .select('user_id, role, status, joined_at, '
            'profiles(display_name, avatar_path), member_parts(part_id)')
        .eq('team_id', teamId)
        .order('joined_at', ascending: true);
    return rows.map(Member.fromJson).toList();
  }

  Future<void> approve(int teamId, String userId) =>
      _db.rpc('approve_member', params: {'p_team_id': teamId, 'p_user_id': userId});

  Future<void> reject(int teamId, String userId) =>
      _db.rpc('reject_member', params: {'p_team_id': teamId, 'p_user_id': userId});

  Future<void> setRole(int teamId, String userId, TeamRole role) => _db.rpc(
        'set_member_role',
        params: {'p_team_id': teamId, 'p_user_id': userId, 'p_role': role.name},
      );

  Future<void> remove(int teamId, String userId) =>
      _db.rpc('remove_member', params: {'p_team_id': teamId, 'p_user_id': userId});

  Future<void> leave(int teamId) => _db.rpc('leave_team', params: {'p_team_id': teamId});

  Future<String> rotateInviteCode(int teamId) async =>
      await _db.rpc('rotate_invite_code', params: {'p_team_id': teamId}) as String;

  Future<void> setMemberParts(int teamId, String userId, Iterable<int> partIds) => _db.rpc(
        'set_member_parts',
        params: {'p_team_id': teamId, 'p_user_id': userId, 'p_part_ids': partIds.toList()},
      );

  Future<void> updateTeam(int teamId, {String? name, bool? joinRequiresApproval}) => _db
      .from('teams')
      .update({
        'name': ?name,
        'join_requires_approval': ?joinRequiresApproval,
      })
      .eq('id', teamId);

  Future<List<Part>> parts(int teamId) async {
    final rows = await _db
        .from('parts')
        .select('id, team_id, name, kind, sort_order')
        .eq('team_id', teamId)
        .isFilter('archived_at', null)
        .order('sort_order', ascending: true)
        .order('id', ascending: true);
    return rows.map(Part.fromJson).toList();
  }

  /// Adds a part, listed last, and links it to the given part chats in the
  /// same step (add_part).
  Future<void> addPart(int teamId, String name, PartKind kind, {Iterable<int> chatIds = const []}) => _db.rpc(
    'add_part',
    params: {'p_team_id': teamId, 'p_name': name.trim(), 'p_kind': kind.name, 'p_channel_ids': chatIds.toList()},
  );

  /// The team's part chats (e.g. 싱어팀) and the parts each one is for.
  Future<List<({int id, String name, Set<int> partIds})>> partChats(int teamId) async {
    final rows = await _db
        .from('channels')
        .select('id, name, channel_parts(part_id)')
        .eq('team_id', teamId)
        .eq('kind', 'parts')
        .isFilter('archived_at', null)
        .order('id', ascending: true);
    return [
      for (final r in rows)
        (
          id: r['id'] as int,
          name: r['name'] as String,
          partIds: {for (final p in r['channel_parts'] as List) (p as Map)['part_id'] as int},
        ),
    ];
  }

  Future<void> renamePart(int partId, String name) =>
      _db.from('parts').update({'name': name.trim()}).eq('id', partId);

  /// Parts stay in the database (past rotations refer to them); hidden
  /// parts just stop showing up.
  Future<void> hidePart(int partId) => _db
      .from('parts')
      .update({'archived_at': DateTime.now().toUtc().toIso8601String()})
      .eq('id', partId);
}
