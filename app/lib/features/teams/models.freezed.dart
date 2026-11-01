// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Team {

 int get id; String get name; String get timezone; String get inviteCode; bool get joinRequiresApproval;
/// Create a copy of Team
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamCopyWith<Team> get copyWith => _$TeamCopyWithImpl<Team>(this as Team, _$identity);

  /// Serializes this Team to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Team;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Team&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.timezone, _this.timezone) || other.timezone == _this.timezone)&&(identical(other.inviteCode, _this.inviteCode) || other.inviteCode == _this.inviteCode)&&(identical(other.joinRequiresApproval, _this.joinRequiresApproval) || other.joinRequiresApproval == _this.joinRequiresApproval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Team;
  return Object.hash(runtimeType,_this.id,_this.name,_this.timezone,_this.inviteCode,_this.joinRequiresApproval);
}

@override
String toString() {
  final _this = this as Team;
  return 'Team(id: ${_this.id}, name: ${_this.name}, timezone: ${_this.timezone}, inviteCode: ${_this.inviteCode}, joinRequiresApproval: ${_this.joinRequiresApproval})';
}


}

/// @nodoc
abstract mixin class $TeamCopyWith<$Res>  {
  factory $TeamCopyWith(Team value, $Res Function(Team) _then) = _$TeamCopyWithImpl;
@useResult
$Res call({
 int id, String name, String timezone, String inviteCode, bool joinRequiresApproval
});




}
/// @nodoc
class _$TeamCopyWithImpl<$Res>
    implements $TeamCopyWith<$Res> {
  _$TeamCopyWithImpl(this._self, this._then);

  final Team _self;
  final $Res Function(Team) _then;

/// Create a copy of Team
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? timezone = null,Object? inviteCode = null,Object? joinRequiresApproval = null,}) {
  return _then(Team(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,joinRequiresApproval: null == joinRequiresApproval ? _self.joinRequiresApproval : joinRequiresApproval // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Team].
extension TeamPatterns on Team {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Team value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Team() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Team value)  $default,){
final _that = this;
switch (_that) {
case _Team():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Team value)?  $default,){
final _that = this;
switch (_that) {
case _Team() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String timezone,  String inviteCode,  bool joinRequiresApproval)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Team() when $default != null:
return $default(_that.id,_that.name,_that.timezone,_that.inviteCode,_that.joinRequiresApproval);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String timezone,  String inviteCode,  bool joinRequiresApproval)  $default,) {final _that = this;
switch (_that) {
case _Team():
return $default(_that.id,_that.name,_that.timezone,_that.inviteCode,_that.joinRequiresApproval);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String timezone,  String inviteCode,  bool joinRequiresApproval)?  $default,) {final _that = this;
switch (_that) {
case _Team() when $default != null:
return $default(_that.id,_that.name,_that.timezone,_that.inviteCode,_that.joinRequiresApproval);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Team implements Team {
  const _Team({required this.id, required this.name, required this.timezone, required this.inviteCode, required this.joinRequiresApproval});
  factory _Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);

@override final  int id;
@override final  String name;
@override final  String timezone;
@override final  String inviteCode;
@override final  bool joinRequiresApproval;

/// Create a copy of Team
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamCopyWith<_Team> get copyWith => __$TeamCopyWithImpl<_Team>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeamToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Team&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&(identical(other.joinRequiresApproval, joinRequiresApproval) || other.joinRequiresApproval == joinRequiresApproval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,timezone,inviteCode,joinRequiresApproval);
}

@override
String toString() {
    return 'Team(id: $id, name: $name, timezone: $timezone, inviteCode: $inviteCode, joinRequiresApproval: $joinRequiresApproval)';
}


}

/// @nodoc
abstract mixin class _$TeamCopyWith<$Res> implements $TeamCopyWith<$Res> {
  factory _$TeamCopyWith(_Team value, $Res Function(_Team) _then) = __$TeamCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String timezone, String inviteCode, bool joinRequiresApproval
});




}
/// @nodoc
class __$TeamCopyWithImpl<$Res>
    implements _$TeamCopyWith<$Res> {
  __$TeamCopyWithImpl(this._self, this._then);

  final _Team _self;
  final $Res Function(_Team) _then;

/// Create a copy of Team
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? timezone = null,Object? inviteCode = null,Object? joinRequiresApproval = null,}) {
  return _then(_Team(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,joinRequiresApproval: null == joinRequiresApproval ? _self.joinRequiresApproval : joinRequiresApproval // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Membership {

 int get teamId; TeamRole get role; MemberStatus get status;@JsonKey(name: 'teams') Team get team;
/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipCopyWith<Membership> get copyWith => _$MembershipCopyWithImpl<Membership>(this as Membership, _$identity);

  /// Serializes this Membership to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Membership;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Membership&&(identical(other.teamId, _this.teamId) || other.teamId == _this.teamId)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.team, _this.team) || other.team == _this.team));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Membership;
  return Object.hash(runtimeType,_this.teamId,_this.role,_this.status,_this.team);
}

@override
String toString() {
  final _this = this as Membership;
  return 'Membership(teamId: ${_this.teamId}, role: ${_this.role}, status: ${_this.status}, team: ${_this.team})';
}


}

/// @nodoc
abstract mixin class $MembershipCopyWith<$Res>  {
  factory $MembershipCopyWith(Membership value, $Res Function(Membership) _then) = _$MembershipCopyWithImpl;
@useResult
$Res call({
 int teamId, TeamRole role, MemberStatus status,@JsonKey(name: 'teams') Team team
});


$TeamCopyWith<$Res> get team;

}
/// @nodoc
class _$MembershipCopyWithImpl<$Res>
    implements $MembershipCopyWith<$Res> {
  _$MembershipCopyWithImpl(this._self, this._then);

  final Membership _self;
  final $Res Function(Membership) _then;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? teamId = null,Object? role = null,Object? status = null,Object? team = null,}) {
  return _then(Membership(
teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as int,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as TeamRole,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MemberStatus,team: null == team ? _self.team : team // ignore: cast_nullable_to_non_nullable
as Team,
  ));
}
/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TeamCopyWith<$Res> get team {
  
  return $TeamCopyWith<$Res>(_self.team, (value) {
    return _then(_self.copyWith(team: value));
  });
}
}


/// Adds pattern-matching-related methods to [Membership].
extension MembershipPatterns on Membership {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Membership value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Membership() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Membership value)  $default,){
final _that = this;
switch (_that) {
case _Membership():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Membership value)?  $default,){
final _that = this;
switch (_that) {
case _Membership() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int teamId,  TeamRole role,  MemberStatus status, @JsonKey(name: 'teams')  Team team)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Membership() when $default != null:
return $default(_that.teamId,_that.role,_that.status,_that.team);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int teamId,  TeamRole role,  MemberStatus status, @JsonKey(name: 'teams')  Team team)  $default,) {final _that = this;
switch (_that) {
case _Membership():
return $default(_that.teamId,_that.role,_that.status,_that.team);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int teamId,  TeamRole role,  MemberStatus status, @JsonKey(name: 'teams')  Team team)?  $default,) {final _that = this;
switch (_that) {
case _Membership() when $default != null:
return $default(_that.teamId,_that.role,_that.status,_that.team);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Membership extends Membership {
  const _Membership({required this.teamId, required this.role, required this.status, @JsonKey(name: 'teams') required this.team}): super._();
  factory _Membership.fromJson(Map<String, dynamic> json) => _$MembershipFromJson(json);

@override final  int teamId;
@override final  TeamRole role;
@override final  MemberStatus status;
@override@JsonKey(name: 'teams') final  Team team;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MembershipCopyWith<_Membership> get copyWith => __$MembershipCopyWithImpl<_Membership>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MembershipToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Membership&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.team, team) || other.team == team));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,teamId,role,status,team);
}

@override
String toString() {
    return 'Membership(teamId: $teamId, role: $role, status: $status, team: $team)';
}


}

/// @nodoc
abstract mixin class _$MembershipCopyWith<$Res> implements $MembershipCopyWith<$Res> {
  factory _$MembershipCopyWith(_Membership value, $Res Function(_Membership) _then) = __$MembershipCopyWithImpl;
@override @useResult
$Res call({
 int teamId, TeamRole role, MemberStatus status,@JsonKey(name: 'teams') Team team
});


@override $TeamCopyWith<$Res> get team;

}
/// @nodoc
class __$MembershipCopyWithImpl<$Res>
    implements _$MembershipCopyWith<$Res> {
  __$MembershipCopyWithImpl(this._self, this._then);

  final _Membership _self;
  final $Res Function(_Membership) _then;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? teamId = null,Object? role = null,Object? status = null,Object? team = null,}) {
  return _then(_Membership(
teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as int,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as TeamRole,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MemberStatus,team: null == team ? _self.team : team // ignore: cast_nullable_to_non_nullable
as Team,
  ));
}

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TeamCopyWith<$Res> get team {
  
  return $TeamCopyWith<$Res>(_self.team, (value) {
    return _then(_self.copyWith(team: value));
  });
}
}


/// @nodoc
mixin _$ProfileSummary {

 String get displayName; String? get avatarPath;
/// Create a copy of ProfileSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileSummaryCopyWith<ProfileSummary> get copyWith => _$ProfileSummaryCopyWithImpl<ProfileSummary>(this as ProfileSummary, _$identity);

  /// Serializes this ProfileSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProfileSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileSummary&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.avatarPath, _this.avatarPath) || other.avatarPath == _this.avatarPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProfileSummary;
  return Object.hash(runtimeType,_this.displayName,_this.avatarPath);
}

@override
String toString() {
  final _this = this as ProfileSummary;
  return 'ProfileSummary(displayName: ${_this.displayName}, avatarPath: ${_this.avatarPath})';
}


}

/// @nodoc
abstract mixin class $ProfileSummaryCopyWith<$Res>  {
  factory $ProfileSummaryCopyWith(ProfileSummary value, $Res Function(ProfileSummary) _then) = _$ProfileSummaryCopyWithImpl;
@useResult
$Res call({
 String displayName, String? avatarPath
});




}
/// @nodoc
class _$ProfileSummaryCopyWithImpl<$Res>
    implements $ProfileSummaryCopyWith<$Res> {
  _$ProfileSummaryCopyWithImpl(this._self, this._then);

  final ProfileSummary _self;
  final $Res Function(ProfileSummary) _then;

/// Create a copy of ProfileSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = null,Object? avatarPath = freezed,}) {
  return _then(ProfileSummary(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarPath: freezed == avatarPath ? _self.avatarPath : avatarPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileSummary].
extension ProfileSummaryPatterns on ProfileSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileSummary value)  $default,){
final _that = this;
switch (_that) {
case _ProfileSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String displayName,  String? avatarPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileSummary() when $default != null:
return $default(_that.displayName,_that.avatarPath);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String displayName,  String? avatarPath)  $default,) {final _that = this;
switch (_that) {
case _ProfileSummary():
return $default(_that.displayName,_that.avatarPath);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String displayName,  String? avatarPath)?  $default,) {final _that = this;
switch (_that) {
case _ProfileSummary() when $default != null:
return $default(_that.displayName,_that.avatarPath);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileSummary implements ProfileSummary {
  const _ProfileSummary({required this.displayName, this.avatarPath});
  factory _ProfileSummary.fromJson(Map<String, dynamic> json) => _$ProfileSummaryFromJson(json);

@override final  String displayName;
@override final  String? avatarPath;

/// Create a copy of ProfileSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileSummaryCopyWith<_ProfileSummary> get copyWith => __$ProfileSummaryCopyWithImpl<_ProfileSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileSummary&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarPath, avatarPath) || other.avatarPath == avatarPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,displayName,avatarPath);
}

@override
String toString() {
    return 'ProfileSummary(displayName: $displayName, avatarPath: $avatarPath)';
}


}

/// @nodoc
abstract mixin class _$ProfileSummaryCopyWith<$Res> implements $ProfileSummaryCopyWith<$Res> {
  factory _$ProfileSummaryCopyWith(_ProfileSummary value, $Res Function(_ProfileSummary) _then) = __$ProfileSummaryCopyWithImpl;
@override @useResult
$Res call({
 String displayName, String? avatarPath
});




}
/// @nodoc
class __$ProfileSummaryCopyWithImpl<$Res>
    implements _$ProfileSummaryCopyWith<$Res> {
  __$ProfileSummaryCopyWithImpl(this._self, this._then);

  final _ProfileSummary _self;
  final $Res Function(_ProfileSummary) _then;

/// Create a copy of ProfileSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayName = null,Object? avatarPath = freezed,}) {
  return _then(_ProfileSummary(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarPath: freezed == avatarPath ? _self.avatarPath : avatarPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Member {

 String get userId; TeamRole get role; MemberStatus get status; DateTime get joinedAt;@JsonKey(name: 'profiles') ProfileSummary get profile;@JsonKey(name: 'member_parts', fromJson: _partIdsFromJson, toJson: _partIdsToJson) List<int> get partIds;
/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberCopyWith<Member> get copyWith => _$MemberCopyWithImpl<Member>(this as Member, _$identity);

  /// Serializes this Member to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Member;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Member&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.joinedAt, _this.joinedAt) || other.joinedAt == _this.joinedAt)&&(identical(other.profile, _this.profile) || other.profile == _this.profile)&&const DeepCollectionEquality().equals(other.partIds, _this.partIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Member;
  return Object.hash(runtimeType,_this.userId,_this.role,_this.status,_this.joinedAt,_this.profile,const DeepCollectionEquality().hash(_this.partIds));
}

@override
String toString() {
  final _this = this as Member;
  return 'Member(userId: ${_this.userId}, role: ${_this.role}, status: ${_this.status}, joinedAt: ${_this.joinedAt}, profile: ${_this.profile}, partIds: ${_this.partIds})';
}


}

/// @nodoc
abstract mixin class $MemberCopyWith<$Res>  {
  factory $MemberCopyWith(Member value, $Res Function(Member) _then) = _$MemberCopyWithImpl;
@useResult
$Res call({
 String userId, TeamRole role, MemberStatus status, DateTime joinedAt,@JsonKey(name: 'profiles') ProfileSummary profile,@JsonKey(name: 'member_parts', fromJson: _partIdsFromJson, toJson: _partIdsToJson) List<int> partIds
});


$ProfileSummaryCopyWith<$Res> get profile;

}
/// @nodoc
class _$MemberCopyWithImpl<$Res>
    implements $MemberCopyWith<$Res> {
  _$MemberCopyWithImpl(this._self, this._then);

  final Member _self;
  final $Res Function(Member) _then;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? role = null,Object? status = null,Object? joinedAt = null,Object? profile = null,Object? partIds = null,}) {
  return _then(Member(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as TeamRole,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MemberStatus,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as ProfileSummary,partIds: null == partIds ? _self.partIds : partIds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}
/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileSummaryCopyWith<$Res> get profile {
  
  return $ProfileSummaryCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}


/// Adds pattern-matching-related methods to [Member].
extension MemberPatterns on Member {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Member value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Member value)  $default,){
final _that = this;
switch (_that) {
case _Member():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Member value)?  $default,){
final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  TeamRole role,  MemberStatus status,  DateTime joinedAt, @JsonKey(name: 'profiles')  ProfileSummary profile, @JsonKey(name: 'member_parts', fromJson: _partIdsFromJson, toJson: _partIdsToJson)  List<int> partIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.userId,_that.role,_that.status,_that.joinedAt,_that.profile,_that.partIds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  TeamRole role,  MemberStatus status,  DateTime joinedAt, @JsonKey(name: 'profiles')  ProfileSummary profile, @JsonKey(name: 'member_parts', fromJson: _partIdsFromJson, toJson: _partIdsToJson)  List<int> partIds)  $default,) {final _that = this;
switch (_that) {
case _Member():
return $default(_that.userId,_that.role,_that.status,_that.joinedAt,_that.profile,_that.partIds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  TeamRole role,  MemberStatus status,  DateTime joinedAt, @JsonKey(name: 'profiles')  ProfileSummary profile, @JsonKey(name: 'member_parts', fromJson: _partIdsFromJson, toJson: _partIdsToJson)  List<int> partIds)?  $default,) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.userId,_that.role,_that.status,_that.joinedAt,_that.profile,_that.partIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Member implements Member {
  const _Member({required this.userId, required this.role, required this.status, required this.joinedAt, @JsonKey(name: 'profiles') required this.profile, @JsonKey(name: 'member_parts', fromJson: _partIdsFromJson, toJson: _partIdsToJson)  List<int> partIds = const <int>[]}): _partIds = partIds;
  factory _Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);

@override final  String userId;
@override final  TeamRole role;
@override final  MemberStatus status;
@override final  DateTime joinedAt;
@override@JsonKey(name: 'profiles') final  ProfileSummary profile;
 final  List<int> _partIds;
@override@JsonKey(name: 'member_parts', fromJson: _partIdsFromJson, toJson: _partIdsToJson) List<int> get partIds {
  if (_partIds is EqualUnmodifiableListView) return _partIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_partIds);
}


/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberCopyWith<_Member> get copyWith => __$MemberCopyWithImpl<_Member>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Member&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.profile, profile) || other.profile == profile)&&const DeepCollectionEquality().equals(other.partIds, _partIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,userId,role,status,joinedAt,profile,const DeepCollectionEquality().hash(_partIds));
}

@override
String toString() {
    return 'Member(userId: $userId, role: $role, status: $status, joinedAt: $joinedAt, profile: $profile, partIds: $partIds)';
}


}

/// @nodoc
abstract mixin class _$MemberCopyWith<$Res> implements $MemberCopyWith<$Res> {
  factory _$MemberCopyWith(_Member value, $Res Function(_Member) _then) = __$MemberCopyWithImpl;
@override @useResult
$Res call({
 String userId, TeamRole role, MemberStatus status, DateTime joinedAt,@JsonKey(name: 'profiles') ProfileSummary profile,@JsonKey(name: 'member_parts', fromJson: _partIdsFromJson, toJson: _partIdsToJson) List<int> partIds
});


@override $ProfileSummaryCopyWith<$Res> get profile;

}
/// @nodoc
class __$MemberCopyWithImpl<$Res>
    implements _$MemberCopyWith<$Res> {
  __$MemberCopyWithImpl(this._self, this._then);

  final _Member _self;
  final $Res Function(_Member) _then;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? role = null,Object? status = null,Object? joinedAt = null,Object? profile = null,Object? partIds = null,}) {
  return _then(_Member(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as TeamRole,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MemberStatus,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as ProfileSummary,partIds: null == partIds ? _self._partIds : partIds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileSummaryCopyWith<$Res> get profile {
  
  return $ProfileSummaryCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}


/// @nodoc
mixin _$Part {

 int get id; int get teamId; String get name; PartKind get kind; int get sortOrder;
/// Create a copy of Part
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PartCopyWith<Part> get copyWith => _$PartCopyWithImpl<Part>(this as Part, _$identity);

  /// Serializes this Part to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Part;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Part&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.teamId, _this.teamId) || other.teamId == _this.teamId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.sortOrder, _this.sortOrder) || other.sortOrder == _this.sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Part;
  return Object.hash(runtimeType,_this.id,_this.teamId,_this.name,_this.kind,_this.sortOrder);
}

@override
String toString() {
  final _this = this as Part;
  return 'Part(id: ${_this.id}, teamId: ${_this.teamId}, name: ${_this.name}, kind: ${_this.kind}, sortOrder: ${_this.sortOrder})';
}


}

/// @nodoc
abstract mixin class $PartCopyWith<$Res>  {
  factory $PartCopyWith(Part value, $Res Function(Part) _then) = _$PartCopyWithImpl;
@useResult
$Res call({
 int id, int teamId, String name, PartKind kind, int sortOrder
});




}
/// @nodoc
class _$PartCopyWithImpl<$Res>
    implements $PartCopyWith<$Res> {
  _$PartCopyWithImpl(this._self, this._then);

  final Part _self;
  final $Res Function(Part) _then;

/// Create a copy of Part
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? teamId = null,Object? name = null,Object? kind = null,Object? sortOrder = null,}) {
  return _then(Part(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PartKind,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Part].
extension PartPatterns on Part {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Part value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Part() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Part value)  $default,){
final _that = this;
switch (_that) {
case _Part():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Part value)?  $default,){
final _that = this;
switch (_that) {
case _Part() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int teamId,  String name,  PartKind kind,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Part() when $default != null:
return $default(_that.id,_that.teamId,_that.name,_that.kind,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int teamId,  String name,  PartKind kind,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _Part():
return $default(_that.id,_that.teamId,_that.name,_that.kind,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int teamId,  String name,  PartKind kind,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _Part() when $default != null:
return $default(_that.id,_that.teamId,_that.name,_that.kind,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Part implements Part {
  const _Part({required this.id, required this.teamId, required this.name, required this.kind, required this.sortOrder});
  factory _Part.fromJson(Map<String, dynamic> json) => _$PartFromJson(json);

@override final  int id;
@override final  int teamId;
@override final  String name;
@override final  PartKind kind;
@override final  int sortOrder;

/// Create a copy of Part
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PartCopyWith<_Part> get copyWith => __$PartCopyWithImpl<_Part>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PartToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Part&&(identical(other.id, id) || other.id == id)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,teamId,name,kind,sortOrder);
}

@override
String toString() {
    return 'Part(id: $id, teamId: $teamId, name: $name, kind: $kind, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$PartCopyWith<$Res> implements $PartCopyWith<$Res> {
  factory _$PartCopyWith(_Part value, $Res Function(_Part) _then) = __$PartCopyWithImpl;
@override @useResult
$Res call({
 int id, int teamId, String name, PartKind kind, int sortOrder
});




}
/// @nodoc
class __$PartCopyWithImpl<$Res>
    implements _$PartCopyWith<$Res> {
  __$PartCopyWithImpl(this._self, this._then);

  final _Part _self;
  final $Res Function(_Part) _then;

/// Create a copy of Part
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? teamId = null,Object? name = null,Object? kind = null,Object? sortOrder = null,}) {
  return _then(_Part(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PartKind,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
