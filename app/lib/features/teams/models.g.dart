// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Team _$TeamFromJson(Map<String, dynamic> json) => _Team(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  timezone: json['timezone'] as String,
  inviteCode: json['invite_code'] as String,
  joinRequiresApproval: json['join_requires_approval'] as bool,
);

Map<String, dynamic> _$TeamToJson(_Team instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'timezone': instance.timezone,
  'invite_code': instance.inviteCode,
  'join_requires_approval': instance.joinRequiresApproval,
};

_Membership _$MembershipFromJson(Map<String, dynamic> json) => _Membership(
  teamId: (json['team_id'] as num).toInt(),
  role: $enumDecode(_$TeamRoleEnumMap, json['role']),
  status: $enumDecode(_$MemberStatusEnumMap, json['status']),
  team: Team.fromJson(json['teams'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MembershipToJson(_Membership instance) =>
    <String, dynamic>{
      'team_id': instance.teamId,
      'role': _$TeamRoleEnumMap[instance.role]!,
      'status': _$MemberStatusEnumMap[instance.status]!,
      'teams': instance.team.toJson(),
    };

const _$TeamRoleEnumMap = {
  TeamRole.owner: 'owner',
  TeamRole.leader: 'leader',
  TeamRole.member: 'member',
};

const _$MemberStatusEnumMap = {
  MemberStatus.pending: 'pending',
  MemberStatus.active: 'active',
};

_ProfileSummary _$ProfileSummaryFromJson(Map<String, dynamic> json) =>
    _ProfileSummary(
      displayName: json['display_name'] as String,
      avatarPath: json['avatar_path'] as String?,
    );

Map<String, dynamic> _$ProfileSummaryToJson(_ProfileSummary instance) =>
    <String, dynamic>{
      'display_name': instance.displayName,
      'avatar_path': instance.avatarPath,
    };

_Member _$MemberFromJson(Map<String, dynamic> json) => _Member(
  userId: json['user_id'] as String,
  role: $enumDecode(_$TeamRoleEnumMap, json['role']),
  status: $enumDecode(_$MemberStatusEnumMap, json['status']),
  joinedAt: DateTime.parse(json['joined_at'] as String),
  profile: ProfileSummary.fromJson(json['profiles'] as Map<String, dynamic>),
  partIds: json['member_parts'] == null
      ? const <int>[]
      : _partIdsFromJson(json['member_parts'] as List?),
);

Map<String, dynamic> _$MemberToJson(_Member instance) => <String, dynamic>{
  'user_id': instance.userId,
  'role': _$TeamRoleEnumMap[instance.role]!,
  'status': _$MemberStatusEnumMap[instance.status]!,
  'joined_at': instance.joinedAt.toIso8601String(),
  'profiles': instance.profile.toJson(),
  'member_parts': _partIdsToJson(instance.partIds),
};

_Part _$PartFromJson(Map<String, dynamic> json) => _Part(
  id: (json['id'] as num).toInt(),
  teamId: (json['team_id'] as num).toInt(),
  name: json['name'] as String,
  kind: $enumDecode(_$PartKindEnumMap, json['kind']),
  sortOrder: (json['sort_order'] as num).toInt(),
);

Map<String, dynamic> _$PartToJson(_Part instance) => <String, dynamic>{
  'id': instance.id,
  'team_id': instance.teamId,
  'name': instance.name,
  'kind': _$PartKindEnumMap[instance.kind]!,
  'sort_order': instance.sortOrder,
};

const _$PartKindEnumMap = {
  PartKind.vocal: 'vocal',
  PartKind.instrument: 'instrument',
  PartKind.tech: 'tech',
};
