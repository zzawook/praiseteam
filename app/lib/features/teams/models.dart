import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

enum TeamRole {
  owner,
  leader,
  member;

  bool get isLeader => this == owner || this == leader;
}

enum MemberStatus { pending, active }

enum PartKind { vocal, instrument, tech }

@freezed
abstract class Team with _$Team {
  const factory Team({
    required int id,
    required String name,
    required String timezone,
    required String inviteCode,
    required bool joinRequiresApproval,
  }) = _Team;

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);
}

/// One of the signed-in user's own team memberships.
@freezed
abstract class Membership with _$Membership {
  const Membership._();

  const factory Membership({
    required int teamId,
    required TeamRole role,
    required MemberStatus status,
    @JsonKey(name: 'teams') required Team team,
  }) = _Membership;

  bool get isActive => status == MemberStatus.active;

  factory Membership.fromJson(Map<String, dynamic> json) => _$MembershipFromJson(json);
}

@freezed
abstract class ProfileSummary with _$ProfileSummary {
  const factory ProfileSummary({required String displayName, String? avatarPath}) =
      _ProfileSummary;

  factory ProfileSummary.fromJson(Map<String, dynamic> json) =>
      _$ProfileSummaryFromJson(json);
}

/// A row of the team roster.
@freezed
abstract class Member with _$Member {
  const factory Member({
    required String userId,
    required TeamRole role,
    required MemberStatus status,
    required DateTime joinedAt,
    @JsonKey(name: 'profiles') required ProfileSummary profile,
    @JsonKey(name: 'member_parts', fromJson: _partIdsFromJson, toJson: _partIdsToJson)
    @Default(<int>[])
    List<int> partIds,
  }) = _Member;

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
}

List<int> _partIdsFromJson(List<dynamic>? rows) =>
    [for (final row in rows ?? const []) (row as Map<String, dynamic>)['part_id'] as int];

List<Map<String, dynamic>> _partIdsToJson(List<int> ids) => [for (final id in ids) {'part_id': id}];

@freezed
abstract class Part with _$Part {
  const factory Part({
    required int id,
    required int teamId,
    required String name,
    required PartKind kind,
    required int sortOrder,
  }) = _Part;

  factory Part.fromJson(Map<String, dynamic> json) => _$PartFromJson(json);
}
