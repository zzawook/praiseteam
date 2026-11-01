import 'package:flutter_test/flutter_test.dart';
import 'package:praiseteam/features/notifications/notifications_providers.dart';
import 'package:praiseteam/features/teams/models.dart';

/// Shapes below are what PostgREST returns for the selects in
/// TeamsRepository / NotificationsRepository.
void main() {
  test('membership with embedded team', () {
    final m = Membership.fromJson({
      'team_id': 7,
      'role': 'leader',
      'status': 'active',
      'teams': {
        'id': 7,
        'name': '청년부 찬양팀',
        'timezone': 'Asia/Singapore',
        'invite_code': 'K7Q2M9XA',
        'join_requires_approval': true,
      },
    });
    expect(m.isActive, isTrue);
    expect(m.role.isLeader, isTrue);
    expect(m.team.inviteCode, 'K7Q2M9XA');
  });

  test('roster row with profile and part ids', () {
    final member = Member.fromJson({
      'user_id': '00000000-0000-0000-0000-00000000000a',
      'role': 'member',
      'status': 'active',
      'joined_at': '2026-10-31T09:00:00+00:00',
      'profiles': {'display_name': 'Alice', 'avatar_path': null},
      'member_parts': [
        {'part_id': 3},
        {'part_id': 5},
      ],
    });
    expect(member.profile.displayName, 'Alice');
    expect(member.partIds, [3, 5]);
  });

  test('roster row without parts', () {
    final member = Member.fromJson({
      'user_id': 'u',
      'role': 'owner',
      'status': 'pending',
      'joined_at': '2026-10-31T09:00:00Z',
      'profiles': {'display_name': 'Bob'},
      'member_parts': <dynamic>[],
    });
    expect(member.partIds, isEmpty);
    expect(member.status, MemberStatus.pending);
  });

  test('part kinds map to the database values', () {
    final part = Part.fromJson({'id': 1, 'team_id': 7, 'name': '드럼', 'kind': 'instrument', 'sort_order': 80});
    expect(part.kind, PartKind.instrument);
  });

  test('notification params survive as a map', () {
    final n = AppNotification.fromJson({
      'id': 11,
      'team_id': 7,
      'category': 'member_join_request',
      'params': {'user_name': 'Bob', 'team_name': 'T'},
      'created_at': '2026-10-31T09:00:00Z',
      'read_at': null,
    });
    expect(n.params['user_name'], 'Bob');
    expect(n.readAt, isNull);
  });
}
