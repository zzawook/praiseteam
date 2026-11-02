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
mixin _$Session {

 int get id; int get teamId; String get title; DateTime get startsAt; String? get location; String? get theme; String? get notes; SetlistStatus get setlistStatus; DateTime? get publishedAt;@JsonKey(name: 'setlist_items', fromJson: _countFromJson, includeToJson: false) int get songCount;
/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionCopyWith<Session> get copyWith => _$SessionCopyWithImpl<Session>(this as Session, _$identity);

  /// Serializes this Session to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Session;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Session&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.teamId, _this.teamId) || other.teamId == _this.teamId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.startsAt, _this.startsAt) || other.startsAt == _this.startsAt)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.theme, _this.theme) || other.theme == _this.theme)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.setlistStatus, _this.setlistStatus) || other.setlistStatus == _this.setlistStatus)&&(identical(other.publishedAt, _this.publishedAt) || other.publishedAt == _this.publishedAt)&&(identical(other.songCount, _this.songCount) || other.songCount == _this.songCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Session;
  return Object.hash(runtimeType,_this.id,_this.teamId,_this.title,_this.startsAt,_this.location,_this.theme,_this.notes,_this.setlistStatus,_this.publishedAt,_this.songCount);
}

@override
String toString() {
  final _this = this as Session;
  return 'Session(id: ${_this.id}, teamId: ${_this.teamId}, title: ${_this.title}, startsAt: ${_this.startsAt}, location: ${_this.location}, theme: ${_this.theme}, notes: ${_this.notes}, setlistStatus: ${_this.setlistStatus}, publishedAt: ${_this.publishedAt}, songCount: ${_this.songCount})';
}


}

/// @nodoc
abstract mixin class $SessionCopyWith<$Res>  {
  factory $SessionCopyWith(Session value, $Res Function(Session) _then) = _$SessionCopyWithImpl;
@useResult
$Res call({
 int id, int teamId, String title, DateTime startsAt, String? location, String? theme, String? notes, SetlistStatus setlistStatus, DateTime? publishedAt,@JsonKey(name: 'setlist_items', fromJson: _countFromJson, includeToJson: false) int songCount
});




}
/// @nodoc
class _$SessionCopyWithImpl<$Res>
    implements $SessionCopyWith<$Res> {
  _$SessionCopyWithImpl(this._self, this._then);

  final Session _self;
  final $Res Function(Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? teamId = null,Object? title = null,Object? startsAt = null,Object? location = freezed,Object? theme = freezed,Object? notes = freezed,Object? setlistStatus = null,Object? publishedAt = freezed,Object? songCount = null,}) {
  return _then(Session(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,theme: freezed == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,setlistStatus: null == setlistStatus ? _self.setlistStatus : setlistStatus // ignore: cast_nullable_to_non_nullable
as SetlistStatus,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,songCount: null == songCount ? _self.songCount : songCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Session].
extension SessionPatterns on Session {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Session value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Session() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Session value)  $default,){
final _that = this;
switch (_that) {
case _Session():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Session value)?  $default,){
final _that = this;
switch (_that) {
case _Session() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int teamId,  String title,  DateTime startsAt,  String? location,  String? theme,  String? notes,  SetlistStatus setlistStatus,  DateTime? publishedAt, @JsonKey(name: 'setlist_items', fromJson: _countFromJson, includeToJson: false)  int songCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.id,_that.teamId,_that.title,_that.startsAt,_that.location,_that.theme,_that.notes,_that.setlistStatus,_that.publishedAt,_that.songCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int teamId,  String title,  DateTime startsAt,  String? location,  String? theme,  String? notes,  SetlistStatus setlistStatus,  DateTime? publishedAt, @JsonKey(name: 'setlist_items', fromJson: _countFromJson, includeToJson: false)  int songCount)  $default,) {final _that = this;
switch (_that) {
case _Session():
return $default(_that.id,_that.teamId,_that.title,_that.startsAt,_that.location,_that.theme,_that.notes,_that.setlistStatus,_that.publishedAt,_that.songCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int teamId,  String title,  DateTime startsAt,  String? location,  String? theme,  String? notes,  SetlistStatus setlistStatus,  DateTime? publishedAt, @JsonKey(name: 'setlist_items', fromJson: _countFromJson, includeToJson: false)  int songCount)?  $default,) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.id,_that.teamId,_that.title,_that.startsAt,_that.location,_that.theme,_that.notes,_that.setlistStatus,_that.publishedAt,_that.songCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Session implements Session {
  const _Session({required this.id, required this.teamId, required this.title, required this.startsAt, this.location, this.theme, this.notes, required this.setlistStatus, this.publishedAt, @JsonKey(name: 'setlist_items', fromJson: _countFromJson, includeToJson: false) this.songCount = 0});
  factory _Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);

@override final  int id;
@override final  int teamId;
@override final  String title;
@override final  DateTime startsAt;
@override final  String? location;
@override final  String? theme;
@override final  String? notes;
@override final  SetlistStatus setlistStatus;
@override final  DateTime? publishedAt;
@override@JsonKey(name: 'setlist_items', fromJson: _countFromJson, includeToJson: false) final  int songCount;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionCopyWith<_Session> get copyWith => __$SessionCopyWithImpl<_Session>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Session&&(identical(other.id, id) || other.id == id)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.title, title) || other.title == title)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.location, location) || other.location == location)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.setlistStatus, setlistStatus) || other.setlistStatus == setlistStatus)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.songCount, songCount) || other.songCount == songCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,teamId,title,startsAt,location,theme,notes,setlistStatus,publishedAt,songCount);
}

@override
String toString() {
    return 'Session(id: $id, teamId: $teamId, title: $title, startsAt: $startsAt, location: $location, theme: $theme, notes: $notes, setlistStatus: $setlistStatus, publishedAt: $publishedAt, songCount: $songCount)';
}


}

/// @nodoc
abstract mixin class _$SessionCopyWith<$Res> implements $SessionCopyWith<$Res> {
  factory _$SessionCopyWith(_Session value, $Res Function(_Session) _then) = __$SessionCopyWithImpl;
@override @useResult
$Res call({
 int id, int teamId, String title, DateTime startsAt, String? location, String? theme, String? notes, SetlistStatus setlistStatus, DateTime? publishedAt,@JsonKey(name: 'setlist_items', fromJson: _countFromJson, includeToJson: false) int songCount
});




}
/// @nodoc
class __$SessionCopyWithImpl<$Res>
    implements _$SessionCopyWith<$Res> {
  __$SessionCopyWithImpl(this._self, this._then);

  final _Session _self;
  final $Res Function(_Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? teamId = null,Object? title = null,Object? startsAt = null,Object? location = freezed,Object? theme = freezed,Object? notes = freezed,Object? setlistStatus = null,Object? publishedAt = freezed,Object? songCount = null,}) {
  return _then(_Session(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,theme: freezed == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,setlistStatus: null == setlistStatus ? _self.setlistStatus : setlistStatus // ignore: cast_nullable_to_non_nullable
as SetlistStatus,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,songCount: null == songCount ? _self.songCount : songCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SessionTemplate {

 int get id; int get teamId; String get title;/// ISO 8601, as [DateTime.weekday]: 1 = Monday ... 7 = Sunday.
 int get weekday;/// Wall-clock 'HH:MM:SS' where the team meets.
 String get startTime; String? get location;
/// Create a copy of SessionTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionTemplateCopyWith<SessionTemplate> get copyWith => _$SessionTemplateCopyWithImpl<SessionTemplate>(this as SessionTemplate, _$identity);

  /// Serializes this SessionTemplate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SessionTemplate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionTemplate&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.teamId, _this.teamId) || other.teamId == _this.teamId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.weekday, _this.weekday) || other.weekday == _this.weekday)&&(identical(other.startTime, _this.startTime) || other.startTime == _this.startTime)&&(identical(other.location, _this.location) || other.location == _this.location));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SessionTemplate;
  return Object.hash(runtimeType,_this.id,_this.teamId,_this.title,_this.weekday,_this.startTime,_this.location);
}

@override
String toString() {
  final _this = this as SessionTemplate;
  return 'SessionTemplate(id: ${_this.id}, teamId: ${_this.teamId}, title: ${_this.title}, weekday: ${_this.weekday}, startTime: ${_this.startTime}, location: ${_this.location})';
}


}

/// @nodoc
abstract mixin class $SessionTemplateCopyWith<$Res>  {
  factory $SessionTemplateCopyWith(SessionTemplate value, $Res Function(SessionTemplate) _then) = _$SessionTemplateCopyWithImpl;
@useResult
$Res call({
 int id, int teamId, String title, int weekday, String startTime, String? location
});




}
/// @nodoc
class _$SessionTemplateCopyWithImpl<$Res>
    implements $SessionTemplateCopyWith<$Res> {
  _$SessionTemplateCopyWithImpl(this._self, this._then);

  final SessionTemplate _self;
  final $Res Function(SessionTemplate) _then;

/// Create a copy of SessionTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? teamId = null,Object? title = null,Object? weekday = null,Object? startTime = null,Object? location = freezed,}) {
  return _then(SessionTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as int,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionTemplate].
extension SessionTemplatePatterns on SessionTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionTemplate value)  $default,){
final _that = this;
switch (_that) {
case _SessionTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _SessionTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int teamId,  String title,  int weekday,  String startTime,  String? location)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionTemplate() when $default != null:
return $default(_that.id,_that.teamId,_that.title,_that.weekday,_that.startTime,_that.location);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int teamId,  String title,  int weekday,  String startTime,  String? location)  $default,) {final _that = this;
switch (_that) {
case _SessionTemplate():
return $default(_that.id,_that.teamId,_that.title,_that.weekday,_that.startTime,_that.location);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int teamId,  String title,  int weekday,  String startTime,  String? location)?  $default,) {final _that = this;
switch (_that) {
case _SessionTemplate() when $default != null:
return $default(_that.id,_that.teamId,_that.title,_that.weekday,_that.startTime,_that.location);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionTemplate extends SessionTemplate {
  const _SessionTemplate({required this.id, required this.teamId, required this.title, required this.weekday, required this.startTime, this.location}): super._();
  factory _SessionTemplate.fromJson(Map<String, dynamic> json) => _$SessionTemplateFromJson(json);

@override final  int id;
@override final  int teamId;
@override final  String title;
/// ISO 8601, as [DateTime.weekday]: 1 = Monday ... 7 = Sunday.
@override final  int weekday;
/// Wall-clock 'HH:MM:SS' where the team meets.
@override final  String startTime;
@override final  String? location;

/// Create a copy of SessionTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionTemplateCopyWith<_SessionTemplate> get copyWith => __$SessionTemplateCopyWithImpl<_SessionTemplate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionTemplateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.title, title) || other.title == title)&&(identical(other.weekday, weekday) || other.weekday == weekday)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.location, location) || other.location == location));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,teamId,title,weekday,startTime,location);
}

@override
String toString() {
    return 'SessionTemplate(id: $id, teamId: $teamId, title: $title, weekday: $weekday, startTime: $startTime, location: $location)';
}


}

/// @nodoc
abstract mixin class _$SessionTemplateCopyWith<$Res> implements $SessionTemplateCopyWith<$Res> {
  factory _$SessionTemplateCopyWith(_SessionTemplate value, $Res Function(_SessionTemplate) _then) = __$SessionTemplateCopyWithImpl;
@override @useResult
$Res call({
 int id, int teamId, String title, int weekday, String startTime, String? location
});




}
/// @nodoc
class __$SessionTemplateCopyWithImpl<$Res>
    implements _$SessionTemplateCopyWith<$Res> {
  __$SessionTemplateCopyWithImpl(this._self, this._then);

  final _SessionTemplate _self;
  final $Res Function(_SessionTemplate) _then;

/// Create a copy of SessionTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? teamId = null,Object? title = null,Object? weekday = null,Object? startTime = null,Object? location = freezed,}) {
  return _then(_SessionTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as int,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SetlistSong {

 String get title;
/// Create a copy of SetlistSong
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetlistSongCopyWith<SetlistSong> get copyWith => _$SetlistSongCopyWithImpl<SetlistSong>(this as SetlistSong, _$identity);

  /// Serializes this SetlistSong to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SetlistSong;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetlistSong&&(identical(other.title, _this.title) || other.title == _this.title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SetlistSong;
  return Object.hash(runtimeType,_this.title);
}

@override
String toString() {
  final _this = this as SetlistSong;
  return 'SetlistSong(title: ${_this.title})';
}


}

/// @nodoc
abstract mixin class $SetlistSongCopyWith<$Res>  {
  factory $SetlistSongCopyWith(SetlistSong value, $Res Function(SetlistSong) _then) = _$SetlistSongCopyWithImpl;
@useResult
$Res call({
 String title
});




}
/// @nodoc
class _$SetlistSongCopyWithImpl<$Res>
    implements $SetlistSongCopyWith<$Res> {
  _$SetlistSongCopyWithImpl(this._self, this._then);

  final SetlistSong _self;
  final $Res Function(SetlistSong) _then;

/// Create a copy of SetlistSong
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,}) {
  return _then(SetlistSong(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SetlistSong].
extension SetlistSongPatterns on SetlistSong {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SetlistSong value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SetlistSong() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SetlistSong value)  $default,){
final _that = this;
switch (_that) {
case _SetlistSong():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SetlistSong value)?  $default,){
final _that = this;
switch (_that) {
case _SetlistSong() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SetlistSong() when $default != null:
return $default(_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title)  $default,) {final _that = this;
switch (_that) {
case _SetlistSong():
return $default(_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title)?  $default,) {final _that = this;
switch (_that) {
case _SetlistSong() when $default != null:
return $default(_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SetlistSong implements SetlistSong {
  const _SetlistSong({required this.title});
  factory _SetlistSong.fromJson(Map<String, dynamic> json) => _$SetlistSongFromJson(json);

@override final  String title;

/// Create a copy of SetlistSong
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetlistSongCopyWith<_SetlistSong> get copyWith => __$SetlistSongCopyWithImpl<_SetlistSong>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SetlistSongToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetlistSong&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title);
}

@override
String toString() {
    return 'SetlistSong(title: $title)';
}


}

/// @nodoc
abstract mixin class _$SetlistSongCopyWith<$Res> implements $SetlistSongCopyWith<$Res> {
  factory _$SetlistSongCopyWith(_SetlistSong value, $Res Function(_SetlistSong) _then) = __$SetlistSongCopyWithImpl;
@override @useResult
$Res call({
 String title
});




}
/// @nodoc
class __$SetlistSongCopyWithImpl<$Res>
    implements _$SetlistSongCopyWith<$Res> {
  __$SetlistSongCopyWithImpl(this._self, this._then);

  final _SetlistSong _self;
  final $Res Function(_SetlistSong) _then;

/// Create a copy of SetlistSong
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,}) {
  return _then(_SetlistSong(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SetlistVersion {

 String? get name; String? get defaultKey; int? get bpm;@JsonKey(name: 'song_links') List<SongLink> get links;
/// Create a copy of SetlistVersion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetlistVersionCopyWith<SetlistVersion> get copyWith => _$SetlistVersionCopyWithImpl<SetlistVersion>(this as SetlistVersion, _$identity);

  /// Serializes this SetlistVersion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SetlistVersion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetlistVersion&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.defaultKey, _this.defaultKey) || other.defaultKey == _this.defaultKey)&&(identical(other.bpm, _this.bpm) || other.bpm == _this.bpm)&&const DeepCollectionEquality().equals(other.links, _this.links));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SetlistVersion;
  return Object.hash(runtimeType,_this.name,_this.defaultKey,_this.bpm,const DeepCollectionEquality().hash(_this.links));
}

@override
String toString() {
  final _this = this as SetlistVersion;
  return 'SetlistVersion(name: ${_this.name}, defaultKey: ${_this.defaultKey}, bpm: ${_this.bpm}, links: ${_this.links})';
}


}

/// @nodoc
abstract mixin class $SetlistVersionCopyWith<$Res>  {
  factory $SetlistVersionCopyWith(SetlistVersion value, $Res Function(SetlistVersion) _then) = _$SetlistVersionCopyWithImpl;
@useResult
$Res call({
 String? name, String? defaultKey, int? bpm,@JsonKey(name: 'song_links') List<SongLink> links
});




}
/// @nodoc
class _$SetlistVersionCopyWithImpl<$Res>
    implements $SetlistVersionCopyWith<$Res> {
  _$SetlistVersionCopyWithImpl(this._self, this._then);

  final SetlistVersion _self;
  final $Res Function(SetlistVersion) _then;

/// Create a copy of SetlistVersion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? defaultKey = freezed,Object? bpm = freezed,Object? links = null,}) {
  return _then(SetlistVersion(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,defaultKey: freezed == defaultKey ? _self.defaultKey : defaultKey // ignore: cast_nullable_to_non_nullable
as String?,bpm: freezed == bpm ? _self.bpm : bpm // ignore: cast_nullable_to_non_nullable
as int?,links: null == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as List<SongLink>,
  ));
}

}


/// Adds pattern-matching-related methods to [SetlistVersion].
extension SetlistVersionPatterns on SetlistVersion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SetlistVersion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SetlistVersion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SetlistVersion value)  $default,){
final _that = this;
switch (_that) {
case _SetlistVersion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SetlistVersion value)?  $default,){
final _that = this;
switch (_that) {
case _SetlistVersion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String? defaultKey,  int? bpm, @JsonKey(name: 'song_links')  List<SongLink> links)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SetlistVersion() when $default != null:
return $default(_that.name,_that.defaultKey,_that.bpm,_that.links);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String? defaultKey,  int? bpm, @JsonKey(name: 'song_links')  List<SongLink> links)  $default,) {final _that = this;
switch (_that) {
case _SetlistVersion():
return $default(_that.name,_that.defaultKey,_that.bpm,_that.links);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String? defaultKey,  int? bpm, @JsonKey(name: 'song_links')  List<SongLink> links)?  $default,) {final _that = this;
switch (_that) {
case _SetlistVersion() when $default != null:
return $default(_that.name,_that.defaultKey,_that.bpm,_that.links);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SetlistVersion implements SetlistVersion {
  const _SetlistVersion({this.name, this.defaultKey, this.bpm, @JsonKey(name: 'song_links')  List<SongLink> links = const <SongLink>[]}): _links = links;
  factory _SetlistVersion.fromJson(Map<String, dynamic> json) => _$SetlistVersionFromJson(json);

@override final  String? name;
@override final  String? defaultKey;
@override final  int? bpm;
 final  List<SongLink> _links;
@override@JsonKey(name: 'song_links') List<SongLink> get links {
  if (_links is EqualUnmodifiableListView) return _links;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_links);
}


/// Create a copy of SetlistVersion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetlistVersionCopyWith<_SetlistVersion> get copyWith => __$SetlistVersionCopyWithImpl<_SetlistVersion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SetlistVersionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetlistVersion&&(identical(other.name, name) || other.name == name)&&(identical(other.defaultKey, defaultKey) || other.defaultKey == defaultKey)&&(identical(other.bpm, bpm) || other.bpm == bpm)&&const DeepCollectionEquality().equals(other.links, _links));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,defaultKey,bpm,const DeepCollectionEquality().hash(_links));
}

@override
String toString() {
    return 'SetlistVersion(name: $name, defaultKey: $defaultKey, bpm: $bpm, links: $links)';
}


}

/// @nodoc
abstract mixin class _$SetlistVersionCopyWith<$Res> implements $SetlistVersionCopyWith<$Res> {
  factory _$SetlistVersionCopyWith(_SetlistVersion value, $Res Function(_SetlistVersion) _then) = __$SetlistVersionCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? defaultKey, int? bpm,@JsonKey(name: 'song_links') List<SongLink> links
});




}
/// @nodoc
class __$SetlistVersionCopyWithImpl<$Res>
    implements _$SetlistVersionCopyWith<$Res> {
  __$SetlistVersionCopyWithImpl(this._self, this._then);

  final _SetlistVersion _self;
  final $Res Function(_SetlistVersion) _then;

/// Create a copy of SetlistVersion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? defaultKey = freezed,Object? bpm = freezed,Object? links = null,}) {
  return _then(_SetlistVersion(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,defaultKey: freezed == defaultKey ? _self.defaultKey : defaultKey // ignore: cast_nullable_to_non_nullable
as String?,bpm: freezed == bpm ? _self.bpm : bpm // ignore: cast_nullable_to_non_nullable
as int?,links: null == links ? _self._links : links // ignore: cast_nullable_to_non_nullable
as List<SongLink>,
  ));
}


}


/// @nodoc
mixin _$SetlistItem {

 int get id; int get sessionId; int get position; int get songId;/// Null only in copies kept on a device from before versions.
 int? get versionId; String? get key;/// This service's tempo; null plays it at the version's own.
 int? get bpm; int? get sheetId; String? get songForm; String? get notes;@JsonKey(name: 'songs') SetlistSong get song;@JsonKey(name: 'song_versions') SetlistVersion? get version;
/// Create a copy of SetlistItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetlistItemCopyWith<SetlistItem> get copyWith => _$SetlistItemCopyWithImpl<SetlistItem>(this as SetlistItem, _$identity);

  /// Serializes this SetlistItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SetlistItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetlistItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.sessionId, _this.sessionId) || other.sessionId == _this.sessionId)&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.songId, _this.songId) || other.songId == _this.songId)&&(identical(other.versionId, _this.versionId) || other.versionId == _this.versionId)&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.bpm, _this.bpm) || other.bpm == _this.bpm)&&(identical(other.sheetId, _this.sheetId) || other.sheetId == _this.sheetId)&&(identical(other.songForm, _this.songForm) || other.songForm == _this.songForm)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.song, _this.song) || other.song == _this.song)&&(identical(other.version, _this.version) || other.version == _this.version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SetlistItem;
  return Object.hash(runtimeType,_this.id,_this.sessionId,_this.position,_this.songId,_this.versionId,_this.key,_this.bpm,_this.sheetId,_this.songForm,_this.notes,_this.song,_this.version);
}

@override
String toString() {
  final _this = this as SetlistItem;
  return 'SetlistItem(id: ${_this.id}, sessionId: ${_this.sessionId}, position: ${_this.position}, songId: ${_this.songId}, versionId: ${_this.versionId}, key: ${_this.key}, bpm: ${_this.bpm}, sheetId: ${_this.sheetId}, songForm: ${_this.songForm}, notes: ${_this.notes}, song: ${_this.song}, version: ${_this.version})';
}


}

/// @nodoc
abstract mixin class $SetlistItemCopyWith<$Res>  {
  factory $SetlistItemCopyWith(SetlistItem value, $Res Function(SetlistItem) _then) = _$SetlistItemCopyWithImpl;
@useResult
$Res call({
 int id, int sessionId, int position, int songId, int? versionId, String? key, int? bpm, int? sheetId, String? songForm, String? notes,@JsonKey(name: 'songs') SetlistSong song,@JsonKey(name: 'song_versions') SetlistVersion? version
});


$SetlistSongCopyWith<$Res> get song;$SetlistVersionCopyWith<$Res>? get version;

}
/// @nodoc
class _$SetlistItemCopyWithImpl<$Res>
    implements $SetlistItemCopyWith<$Res> {
  _$SetlistItemCopyWithImpl(this._self, this._then);

  final SetlistItem _self;
  final $Res Function(SetlistItem) _then;

/// Create a copy of SetlistItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? position = null,Object? songId = null,Object? versionId = freezed,Object? key = freezed,Object? bpm = freezed,Object? sheetId = freezed,Object? songForm = freezed,Object? notes = freezed,Object? song = null,Object? version = freezed,}) {
  return _then(SetlistItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as int,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,songId: null == songId ? _self.songId : songId // ignore: cast_nullable_to_non_nullable
as int,versionId: freezed == versionId ? _self.versionId : versionId // ignore: cast_nullable_to_non_nullable
as int?,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,bpm: freezed == bpm ? _self.bpm : bpm // ignore: cast_nullable_to_non_nullable
as int?,sheetId: freezed == sheetId ? _self.sheetId : sheetId // ignore: cast_nullable_to_non_nullable
as int?,songForm: freezed == songForm ? _self.songForm : songForm // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,song: null == song ? _self.song : song // ignore: cast_nullable_to_non_nullable
as SetlistSong,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as SetlistVersion?,
  ));
}
/// Create a copy of SetlistItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SetlistSongCopyWith<$Res> get song {
  
  return $SetlistSongCopyWith<$Res>(_self.song, (value) {
    return _then(_self.copyWith(song: value));
  });
}/// Create a copy of SetlistItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SetlistVersionCopyWith<$Res>? get version {
    if (_self.version == null) {
    return null;
  }

  return $SetlistVersionCopyWith<$Res>(_self.version!, (value) {
    return _then(_self.copyWith(version: value));
  });
}
}


/// Adds pattern-matching-related methods to [SetlistItem].
extension SetlistItemPatterns on SetlistItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SetlistItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SetlistItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SetlistItem value)  $default,){
final _that = this;
switch (_that) {
case _SetlistItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SetlistItem value)?  $default,){
final _that = this;
switch (_that) {
case _SetlistItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int sessionId,  int position,  int songId,  int? versionId,  String? key,  int? bpm,  int? sheetId,  String? songForm,  String? notes, @JsonKey(name: 'songs')  SetlistSong song, @JsonKey(name: 'song_versions')  SetlistVersion? version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SetlistItem() when $default != null:
return $default(_that.id,_that.sessionId,_that.position,_that.songId,_that.versionId,_that.key,_that.bpm,_that.sheetId,_that.songForm,_that.notes,_that.song,_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int sessionId,  int position,  int songId,  int? versionId,  String? key,  int? bpm,  int? sheetId,  String? songForm,  String? notes, @JsonKey(name: 'songs')  SetlistSong song, @JsonKey(name: 'song_versions')  SetlistVersion? version)  $default,) {final _that = this;
switch (_that) {
case _SetlistItem():
return $default(_that.id,_that.sessionId,_that.position,_that.songId,_that.versionId,_that.key,_that.bpm,_that.sheetId,_that.songForm,_that.notes,_that.song,_that.version);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int sessionId,  int position,  int songId,  int? versionId,  String? key,  int? bpm,  int? sheetId,  String? songForm,  String? notes, @JsonKey(name: 'songs')  SetlistSong song, @JsonKey(name: 'song_versions')  SetlistVersion? version)?  $default,) {final _that = this;
switch (_that) {
case _SetlistItem() when $default != null:
return $default(_that.id,_that.sessionId,_that.position,_that.songId,_that.versionId,_that.key,_that.bpm,_that.sheetId,_that.songForm,_that.notes,_that.song,_that.version);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SetlistItem extends SetlistItem {
  const _SetlistItem({required this.id, required this.sessionId, required this.position, required this.songId, this.versionId, this.key, this.bpm, this.sheetId, this.songForm, this.notes, @JsonKey(name: 'songs') required this.song, @JsonKey(name: 'song_versions') this.version}): super._();
  factory _SetlistItem.fromJson(Map<String, dynamic> json) => _$SetlistItemFromJson(json);

@override final  int id;
@override final  int sessionId;
@override final  int position;
@override final  int songId;
/// Null only in copies kept on a device from before versions.
@override final  int? versionId;
@override final  String? key;
/// This service's tempo; null plays it at the version's own.
@override final  int? bpm;
@override final  int? sheetId;
@override final  String? songForm;
@override final  String? notes;
@override@JsonKey(name: 'songs') final  SetlistSong song;
@override@JsonKey(name: 'song_versions') final  SetlistVersion? version;

/// Create a copy of SetlistItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetlistItemCopyWith<_SetlistItem> get copyWith => __$SetlistItemCopyWithImpl<_SetlistItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SetlistItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetlistItem&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.position, position) || other.position == position)&&(identical(other.songId, songId) || other.songId == songId)&&(identical(other.versionId, versionId) || other.versionId == versionId)&&(identical(other.key, key) || other.key == key)&&(identical(other.bpm, bpm) || other.bpm == bpm)&&(identical(other.sheetId, sheetId) || other.sheetId == sheetId)&&(identical(other.songForm, songForm) || other.songForm == songForm)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.song, song) || other.song == song)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,sessionId,position,songId,versionId,key,bpm,sheetId,songForm,notes,song,version);
}

@override
String toString() {
    return 'SetlistItem(id: $id, sessionId: $sessionId, position: $position, songId: $songId, versionId: $versionId, key: $key, bpm: $bpm, sheetId: $sheetId, songForm: $songForm, notes: $notes, song: $song, version: $version)';
}


}

/// @nodoc
abstract mixin class _$SetlistItemCopyWith<$Res> implements $SetlistItemCopyWith<$Res> {
  factory _$SetlistItemCopyWith(_SetlistItem value, $Res Function(_SetlistItem) _then) = __$SetlistItemCopyWithImpl;
@override @useResult
$Res call({
 int id, int sessionId, int position, int songId, int? versionId, String? key, int? bpm, int? sheetId, String? songForm, String? notes,@JsonKey(name: 'songs') SetlistSong song,@JsonKey(name: 'song_versions') SetlistVersion? version
});


@override $SetlistSongCopyWith<$Res> get song;@override $SetlistVersionCopyWith<$Res>? get version;

}
/// @nodoc
class __$SetlistItemCopyWithImpl<$Res>
    implements _$SetlistItemCopyWith<$Res> {
  __$SetlistItemCopyWithImpl(this._self, this._then);

  final _SetlistItem _self;
  final $Res Function(_SetlistItem) _then;

/// Create a copy of SetlistItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? position = null,Object? songId = null,Object? versionId = freezed,Object? key = freezed,Object? bpm = freezed,Object? sheetId = freezed,Object? songForm = freezed,Object? notes = freezed,Object? song = null,Object? version = freezed,}) {
  return _then(_SetlistItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as int,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,songId: null == songId ? _self.songId : songId // ignore: cast_nullable_to_non_nullable
as int,versionId: freezed == versionId ? _self.versionId : versionId // ignore: cast_nullable_to_non_nullable
as int?,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,bpm: freezed == bpm ? _self.bpm : bpm // ignore: cast_nullable_to_non_nullable
as int?,sheetId: freezed == sheetId ? _self.sheetId : sheetId // ignore: cast_nullable_to_non_nullable
as int?,songForm: freezed == songForm ? _self.songForm : songForm // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,song: null == song ? _self.song : song // ignore: cast_nullable_to_non_nullable
as SetlistSong,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as SetlistVersion?,
  ));
}

/// Create a copy of SetlistItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SetlistSongCopyWith<$Res> get song {
  
  return $SetlistSongCopyWith<$Res>(_self.song, (value) {
    return _then(_self.copyWith(song: value));
  });
}/// Create a copy of SetlistItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SetlistVersionCopyWith<$Res>? get version {
    if (_self.version == null) {
    return null;
  }

  return $SetlistVersionCopyWith<$Res>(_self.version!, (value) {
    return _then(_self.copyWith(version: value));
  });
}
}

// dart format on
