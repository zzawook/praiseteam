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
mixin _$Song {

 int get id; int get teamId; String get title; String? get artist; String? get defaultKey; int? get bpm; String? get timeSignature; List<String> get tags; String? get notes;
/// Create a copy of Song
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SongCopyWith<Song> get copyWith => _$SongCopyWithImpl<Song>(this as Song, _$identity);

  /// Serializes this Song to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Song;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Song&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.teamId, _this.teamId) || other.teamId == _this.teamId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&(identical(other.defaultKey, _this.defaultKey) || other.defaultKey == _this.defaultKey)&&(identical(other.bpm, _this.bpm) || other.bpm == _this.bpm)&&(identical(other.timeSignature, _this.timeSignature) || other.timeSignature == _this.timeSignature)&&const DeepCollectionEquality().equals(other.tags, _this.tags)&&(identical(other.notes, _this.notes) || other.notes == _this.notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Song;
  return Object.hash(runtimeType,_this.id,_this.teamId,_this.title,_this.artist,_this.defaultKey,_this.bpm,_this.timeSignature,const DeepCollectionEquality().hash(_this.tags),_this.notes);
}

@override
String toString() {
  final _this = this as Song;
  return 'Song(id: ${_this.id}, teamId: ${_this.teamId}, title: ${_this.title}, artist: ${_this.artist}, defaultKey: ${_this.defaultKey}, bpm: ${_this.bpm}, timeSignature: ${_this.timeSignature}, tags: ${_this.tags}, notes: ${_this.notes})';
}


}

/// @nodoc
abstract mixin class $SongCopyWith<$Res>  {
  factory $SongCopyWith(Song value, $Res Function(Song) _then) = _$SongCopyWithImpl;
@useResult
$Res call({
 int id, int teamId, String title, String? artist, String? defaultKey, int? bpm, String? timeSignature, List<String> tags, String? notes
});




}
/// @nodoc
class _$SongCopyWithImpl<$Res>
    implements $SongCopyWith<$Res> {
  _$SongCopyWithImpl(this._self, this._then);

  final Song _self;
  final $Res Function(Song) _then;

/// Create a copy of Song
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? teamId = null,Object? title = null,Object? artist = freezed,Object? defaultKey = freezed,Object? bpm = freezed,Object? timeSignature = freezed,Object? tags = null,Object? notes = freezed,}) {
  return _then(Song(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,defaultKey: freezed == defaultKey ? _self.defaultKey : defaultKey // ignore: cast_nullable_to_non_nullable
as String?,bpm: freezed == bpm ? _self.bpm : bpm // ignore: cast_nullable_to_non_nullable
as int?,timeSignature: freezed == timeSignature ? _self.timeSignature : timeSignature // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Song].
extension SongPatterns on Song {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Song value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Song() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Song value)  $default,){
final _that = this;
switch (_that) {
case _Song():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Song value)?  $default,){
final _that = this;
switch (_that) {
case _Song() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int teamId,  String title,  String? artist,  String? defaultKey,  int? bpm,  String? timeSignature,  List<String> tags,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Song() when $default != null:
return $default(_that.id,_that.teamId,_that.title,_that.artist,_that.defaultKey,_that.bpm,_that.timeSignature,_that.tags,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int teamId,  String title,  String? artist,  String? defaultKey,  int? bpm,  String? timeSignature,  List<String> tags,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _Song():
return $default(_that.id,_that.teamId,_that.title,_that.artist,_that.defaultKey,_that.bpm,_that.timeSignature,_that.tags,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int teamId,  String title,  String? artist,  String? defaultKey,  int? bpm,  String? timeSignature,  List<String> tags,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _Song() when $default != null:
return $default(_that.id,_that.teamId,_that.title,_that.artist,_that.defaultKey,_that.bpm,_that.timeSignature,_that.tags,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Song implements Song {
  const _Song({required this.id, required this.teamId, required this.title, this.artist, this.defaultKey, this.bpm, this.timeSignature,  List<String> tags = const <String>[], this.notes}): _tags = tags;
  factory _Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

@override final  int id;
@override final  int teamId;
@override final  String title;
@override final  String? artist;
@override final  String? defaultKey;
@override final  int? bpm;
@override final  String? timeSignature;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  String? notes;

/// Create a copy of Song
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SongCopyWith<_Song> get copyWith => __$SongCopyWithImpl<_Song>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SongToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Song&&(identical(other.id, id) || other.id == id)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.defaultKey, defaultKey) || other.defaultKey == defaultKey)&&(identical(other.bpm, bpm) || other.bpm == bpm)&&(identical(other.timeSignature, timeSignature) || other.timeSignature == timeSignature)&&const DeepCollectionEquality().equals(other.tags, _tags)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,teamId,title,artist,defaultKey,bpm,timeSignature,const DeepCollectionEquality().hash(_tags),notes);
}

@override
String toString() {
    return 'Song(id: $id, teamId: $teamId, title: $title, artist: $artist, defaultKey: $defaultKey, bpm: $bpm, timeSignature: $timeSignature, tags: $tags, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$SongCopyWith<$Res> implements $SongCopyWith<$Res> {
  factory _$SongCopyWith(_Song value, $Res Function(_Song) _then) = __$SongCopyWithImpl;
@override @useResult
$Res call({
 int id, int teamId, String title, String? artist, String? defaultKey, int? bpm, String? timeSignature, List<String> tags, String? notes
});




}
/// @nodoc
class __$SongCopyWithImpl<$Res>
    implements _$SongCopyWith<$Res> {
  __$SongCopyWithImpl(this._self, this._then);

  final _Song _self;
  final $Res Function(_Song) _then;

/// Create a copy of Song
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? teamId = null,Object? title = null,Object? artist = freezed,Object? defaultKey = freezed,Object? bpm = freezed,Object? timeSignature = freezed,Object? tags = null,Object? notes = freezed,}) {
  return _then(_Song(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,defaultKey: freezed == defaultKey ? _self.defaultKey : defaultKey // ignore: cast_nullable_to_non_nullable
as String?,bpm: freezed == bpm ? _self.bpm : bpm // ignore: cast_nullable_to_non_nullable
as int?,timeSignature: freezed == timeSignature ? _self.timeSignature : timeSignature // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SongStats {

 int get songId; int get timesPlayed; DateTime? get lastPlayedAt; DateTime? get firstPlayedAt; String? get usualKey; DateTime? get nextPlannedAt;
/// Create a copy of SongStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SongStatsCopyWith<SongStats> get copyWith => _$SongStatsCopyWithImpl<SongStats>(this as SongStats, _$identity);

  /// Serializes this SongStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SongStats;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SongStats&&(identical(other.songId, _this.songId) || other.songId == _this.songId)&&(identical(other.timesPlayed, _this.timesPlayed) || other.timesPlayed == _this.timesPlayed)&&(identical(other.lastPlayedAt, _this.lastPlayedAt) || other.lastPlayedAt == _this.lastPlayedAt)&&(identical(other.firstPlayedAt, _this.firstPlayedAt) || other.firstPlayedAt == _this.firstPlayedAt)&&(identical(other.usualKey, _this.usualKey) || other.usualKey == _this.usualKey)&&(identical(other.nextPlannedAt, _this.nextPlannedAt) || other.nextPlannedAt == _this.nextPlannedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SongStats;
  return Object.hash(runtimeType,_this.songId,_this.timesPlayed,_this.lastPlayedAt,_this.firstPlayedAt,_this.usualKey,_this.nextPlannedAt);
}

@override
String toString() {
  final _this = this as SongStats;
  return 'SongStats(songId: ${_this.songId}, timesPlayed: ${_this.timesPlayed}, lastPlayedAt: ${_this.lastPlayedAt}, firstPlayedAt: ${_this.firstPlayedAt}, usualKey: ${_this.usualKey}, nextPlannedAt: ${_this.nextPlannedAt})';
}


}

/// @nodoc
abstract mixin class $SongStatsCopyWith<$Res>  {
  factory $SongStatsCopyWith(SongStats value, $Res Function(SongStats) _then) = _$SongStatsCopyWithImpl;
@useResult
$Res call({
 int songId, int timesPlayed, DateTime? lastPlayedAt, DateTime? firstPlayedAt, String? usualKey, DateTime? nextPlannedAt
});




}
/// @nodoc
class _$SongStatsCopyWithImpl<$Res>
    implements $SongStatsCopyWith<$Res> {
  _$SongStatsCopyWithImpl(this._self, this._then);

  final SongStats _self;
  final $Res Function(SongStats) _then;

/// Create a copy of SongStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? songId = null,Object? timesPlayed = null,Object? lastPlayedAt = freezed,Object? firstPlayedAt = freezed,Object? usualKey = freezed,Object? nextPlannedAt = freezed,}) {
  return _then(SongStats(
songId: null == songId ? _self.songId : songId // ignore: cast_nullable_to_non_nullable
as int,timesPlayed: null == timesPlayed ? _self.timesPlayed : timesPlayed // ignore: cast_nullable_to_non_nullable
as int,lastPlayedAt: freezed == lastPlayedAt ? _self.lastPlayedAt : lastPlayedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,firstPlayedAt: freezed == firstPlayedAt ? _self.firstPlayedAt : firstPlayedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,usualKey: freezed == usualKey ? _self.usualKey : usualKey // ignore: cast_nullable_to_non_nullable
as String?,nextPlannedAt: freezed == nextPlannedAt ? _self.nextPlannedAt : nextPlannedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SongStats].
extension SongStatsPatterns on SongStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SongStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SongStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SongStats value)  $default,){
final _that = this;
switch (_that) {
case _SongStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SongStats value)?  $default,){
final _that = this;
switch (_that) {
case _SongStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int songId,  int timesPlayed,  DateTime? lastPlayedAt,  DateTime? firstPlayedAt,  String? usualKey,  DateTime? nextPlannedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SongStats() when $default != null:
return $default(_that.songId,_that.timesPlayed,_that.lastPlayedAt,_that.firstPlayedAt,_that.usualKey,_that.nextPlannedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int songId,  int timesPlayed,  DateTime? lastPlayedAt,  DateTime? firstPlayedAt,  String? usualKey,  DateTime? nextPlannedAt)  $default,) {final _that = this;
switch (_that) {
case _SongStats():
return $default(_that.songId,_that.timesPlayed,_that.lastPlayedAt,_that.firstPlayedAt,_that.usualKey,_that.nextPlannedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int songId,  int timesPlayed,  DateTime? lastPlayedAt,  DateTime? firstPlayedAt,  String? usualKey,  DateTime? nextPlannedAt)?  $default,) {final _that = this;
switch (_that) {
case _SongStats() when $default != null:
return $default(_that.songId,_that.timesPlayed,_that.lastPlayedAt,_that.firstPlayedAt,_that.usualKey,_that.nextPlannedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SongStats implements SongStats {
  const _SongStats({required this.songId, this.timesPlayed = 0, this.lastPlayedAt, this.firstPlayedAt, this.usualKey, this.nextPlannedAt});
  factory _SongStats.fromJson(Map<String, dynamic> json) => _$SongStatsFromJson(json);

@override final  int songId;
@override@JsonKey() final  int timesPlayed;
@override final  DateTime? lastPlayedAt;
@override final  DateTime? firstPlayedAt;
@override final  String? usualKey;
@override final  DateTime? nextPlannedAt;

/// Create a copy of SongStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SongStatsCopyWith<_SongStats> get copyWith => __$SongStatsCopyWithImpl<_SongStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SongStatsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SongStats&&(identical(other.songId, songId) || other.songId == songId)&&(identical(other.timesPlayed, timesPlayed) || other.timesPlayed == timesPlayed)&&(identical(other.lastPlayedAt, lastPlayedAt) || other.lastPlayedAt == lastPlayedAt)&&(identical(other.firstPlayedAt, firstPlayedAt) || other.firstPlayedAt == firstPlayedAt)&&(identical(other.usualKey, usualKey) || other.usualKey == usualKey)&&(identical(other.nextPlannedAt, nextPlannedAt) || other.nextPlannedAt == nextPlannedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,songId,timesPlayed,lastPlayedAt,firstPlayedAt,usualKey,nextPlannedAt);
}

@override
String toString() {
    return 'SongStats(songId: $songId, timesPlayed: $timesPlayed, lastPlayedAt: $lastPlayedAt, firstPlayedAt: $firstPlayedAt, usualKey: $usualKey, nextPlannedAt: $nextPlannedAt)';
}


}

/// @nodoc
abstract mixin class _$SongStatsCopyWith<$Res> implements $SongStatsCopyWith<$Res> {
  factory _$SongStatsCopyWith(_SongStats value, $Res Function(_SongStats) _then) = __$SongStatsCopyWithImpl;
@override @useResult
$Res call({
 int songId, int timesPlayed, DateTime? lastPlayedAt, DateTime? firstPlayedAt, String? usualKey, DateTime? nextPlannedAt
});




}
/// @nodoc
class __$SongStatsCopyWithImpl<$Res>
    implements _$SongStatsCopyWith<$Res> {
  __$SongStatsCopyWithImpl(this._self, this._then);

  final _SongStats _self;
  final $Res Function(_SongStats) _then;

/// Create a copy of SongStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? songId = null,Object? timesPlayed = null,Object? lastPlayedAt = freezed,Object? firstPlayedAt = freezed,Object? usualKey = freezed,Object? nextPlannedAt = freezed,}) {
  return _then(_SongStats(
songId: null == songId ? _self.songId : songId // ignore: cast_nullable_to_non_nullable
as int,timesPlayed: null == timesPlayed ? _self.timesPlayed : timesPlayed // ignore: cast_nullable_to_non_nullable
as int,lastPlayedAt: freezed == lastPlayedAt ? _self.lastPlayedAt : lastPlayedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,firstPlayedAt: freezed == firstPlayedAt ? _self.firstPlayedAt : firstPlayedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,usualKey: freezed == usualKey ? _self.usualKey : usualKey // ignore: cast_nullable_to_non_nullable
as String?,nextPlannedAt: freezed == nextPlannedAt ? _self.nextPlannedAt : nextPlannedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$SongLink {

 int get id; int get songId; String? get label; String get url; int get sortOrder;
/// Create a copy of SongLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SongLinkCopyWith<SongLink> get copyWith => _$SongLinkCopyWithImpl<SongLink>(this as SongLink, _$identity);

  /// Serializes this SongLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SongLink;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SongLink&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.songId, _this.songId) || other.songId == _this.songId)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.sortOrder, _this.sortOrder) || other.sortOrder == _this.sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SongLink;
  return Object.hash(runtimeType,_this.id,_this.songId,_this.label,_this.url,_this.sortOrder);
}

@override
String toString() {
  final _this = this as SongLink;
  return 'SongLink(id: ${_this.id}, songId: ${_this.songId}, label: ${_this.label}, url: ${_this.url}, sortOrder: ${_this.sortOrder})';
}


}

/// @nodoc
abstract mixin class $SongLinkCopyWith<$Res>  {
  factory $SongLinkCopyWith(SongLink value, $Res Function(SongLink) _then) = _$SongLinkCopyWithImpl;
@useResult
$Res call({
 int id, int songId, String? label, String url, int sortOrder
});




}
/// @nodoc
class _$SongLinkCopyWithImpl<$Res>
    implements $SongLinkCopyWith<$Res> {
  _$SongLinkCopyWithImpl(this._self, this._then);

  final SongLink _self;
  final $Res Function(SongLink) _then;

/// Create a copy of SongLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? songId = null,Object? label = freezed,Object? url = null,Object? sortOrder = null,}) {
  return _then(SongLink(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,songId: null == songId ? _self.songId : songId // ignore: cast_nullable_to_non_nullable
as int,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SongLink].
extension SongLinkPatterns on SongLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SongLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SongLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SongLink value)  $default,){
final _that = this;
switch (_that) {
case _SongLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SongLink value)?  $default,){
final _that = this;
switch (_that) {
case _SongLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int songId,  String? label,  String url,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SongLink() when $default != null:
return $default(_that.id,_that.songId,_that.label,_that.url,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int songId,  String? label,  String url,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _SongLink():
return $default(_that.id,_that.songId,_that.label,_that.url,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int songId,  String? label,  String url,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _SongLink() when $default != null:
return $default(_that.id,_that.songId,_that.label,_that.url,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SongLink implements SongLink {
  const _SongLink({required this.id, required this.songId, this.label, required this.url, this.sortOrder = 0});
  factory _SongLink.fromJson(Map<String, dynamic> json) => _$SongLinkFromJson(json);

@override final  int id;
@override final  int songId;
@override final  String? label;
@override final  String url;
@override@JsonKey() final  int sortOrder;

/// Create a copy of SongLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SongLinkCopyWith<_SongLink> get copyWith => __$SongLinkCopyWithImpl<_SongLink>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SongLinkToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SongLink&&(identical(other.id, id) || other.id == id)&&(identical(other.songId, songId) || other.songId == songId)&&(identical(other.label, label) || other.label == label)&&(identical(other.url, url) || other.url == url)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,songId,label,url,sortOrder);
}

@override
String toString() {
    return 'SongLink(id: $id, songId: $songId, label: $label, url: $url, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$SongLinkCopyWith<$Res> implements $SongLinkCopyWith<$Res> {
  factory _$SongLinkCopyWith(_SongLink value, $Res Function(_SongLink) _then) = __$SongLinkCopyWithImpl;
@override @useResult
$Res call({
 int id, int songId, String? label, String url, int sortOrder
});




}
/// @nodoc
class __$SongLinkCopyWithImpl<$Res>
    implements _$SongLinkCopyWith<$Res> {
  __$SongLinkCopyWithImpl(this._self, this._then);

  final _SongLink _self;
  final $Res Function(_SongLink) _then;

/// Create a copy of SongLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? songId = null,Object? label = freezed,Object? url = null,Object? sortOrder = null,}) {
  return _then(_SongLink(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,songId: null == songId ? _self.songId : songId // ignore: cast_nullable_to_non_nullable
as int,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Sheet {

 int get id; int get songId; String? get key; String? get label; String get storagePath; int get pageCount;@JsonKey(fromJson: _pageSizesFromJson, toJson: _pageSizesToJson) List<PageSize> get pageSizes; int get sizeBytes; String? get uploadedBy; DateTime get createdAt;
/// Create a copy of Sheet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SheetCopyWith<Sheet> get copyWith => _$SheetCopyWithImpl<Sheet>(this as Sheet, _$identity);

  /// Serializes this Sheet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Sheet;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Sheet&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.songId, _this.songId) || other.songId == _this.songId)&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.storagePath, _this.storagePath) || other.storagePath == _this.storagePath)&&(identical(other.pageCount, _this.pageCount) || other.pageCount == _this.pageCount)&&const DeepCollectionEquality().equals(other.pageSizes, _this.pageSizes)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&(identical(other.uploadedBy, _this.uploadedBy) || other.uploadedBy == _this.uploadedBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Sheet;
  return Object.hash(runtimeType,_this.id,_this.songId,_this.key,_this.label,_this.storagePath,_this.pageCount,const DeepCollectionEquality().hash(_this.pageSizes),_this.sizeBytes,_this.uploadedBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as Sheet;
  return 'Sheet(id: ${_this.id}, songId: ${_this.songId}, key: ${_this.key}, label: ${_this.label}, storagePath: ${_this.storagePath}, pageCount: ${_this.pageCount}, pageSizes: ${_this.pageSizes}, sizeBytes: ${_this.sizeBytes}, uploadedBy: ${_this.uploadedBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $SheetCopyWith<$Res>  {
  factory $SheetCopyWith(Sheet value, $Res Function(Sheet) _then) = _$SheetCopyWithImpl;
@useResult
$Res call({
 int id, int songId, String? key, String? label, String storagePath, int pageCount,@JsonKey(fromJson: _pageSizesFromJson, toJson: _pageSizesToJson) List<PageSize> pageSizes, int sizeBytes, String? uploadedBy, DateTime createdAt
});




}
/// @nodoc
class _$SheetCopyWithImpl<$Res>
    implements $SheetCopyWith<$Res> {
  _$SheetCopyWithImpl(this._self, this._then);

  final Sheet _self;
  final $Res Function(Sheet) _then;

/// Create a copy of Sheet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? songId = null,Object? key = freezed,Object? label = freezed,Object? storagePath = null,Object? pageCount = null,Object? pageSizes = null,Object? sizeBytes = null,Object? uploadedBy = freezed,Object? createdAt = null,}) {
  return _then(Sheet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,songId: null == songId ? _self.songId : songId // ignore: cast_nullable_to_non_nullable
as int,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,pageSizes: null == pageSizes ? _self.pageSizes : pageSizes // ignore: cast_nullable_to_non_nullable
as List<PageSize>,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,uploadedBy: freezed == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Sheet].
extension SheetPatterns on Sheet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Sheet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Sheet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Sheet value)  $default,){
final _that = this;
switch (_that) {
case _Sheet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Sheet value)?  $default,){
final _that = this;
switch (_that) {
case _Sheet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int songId,  String? key,  String? label,  String storagePath,  int pageCount, @JsonKey(fromJson: _pageSizesFromJson, toJson: _pageSizesToJson)  List<PageSize> pageSizes,  int sizeBytes,  String? uploadedBy,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Sheet() when $default != null:
return $default(_that.id,_that.songId,_that.key,_that.label,_that.storagePath,_that.pageCount,_that.pageSizes,_that.sizeBytes,_that.uploadedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int songId,  String? key,  String? label,  String storagePath,  int pageCount, @JsonKey(fromJson: _pageSizesFromJson, toJson: _pageSizesToJson)  List<PageSize> pageSizes,  int sizeBytes,  String? uploadedBy,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Sheet():
return $default(_that.id,_that.songId,_that.key,_that.label,_that.storagePath,_that.pageCount,_that.pageSizes,_that.sizeBytes,_that.uploadedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int songId,  String? key,  String? label,  String storagePath,  int pageCount, @JsonKey(fromJson: _pageSizesFromJson, toJson: _pageSizesToJson)  List<PageSize> pageSizes,  int sizeBytes,  String? uploadedBy,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Sheet() when $default != null:
return $default(_that.id,_that.songId,_that.key,_that.label,_that.storagePath,_that.pageCount,_that.pageSizes,_that.sizeBytes,_that.uploadedBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Sheet implements Sheet {
  const _Sheet({required this.id, required this.songId, this.key, this.label, required this.storagePath, required this.pageCount, @JsonKey(fromJson: _pageSizesFromJson, toJson: _pageSizesToJson) required  List<PageSize> pageSizes, required this.sizeBytes, this.uploadedBy, required this.createdAt}): _pageSizes = pageSizes;
  factory _Sheet.fromJson(Map<String, dynamic> json) => _$SheetFromJson(json);

@override final  int id;
@override final  int songId;
@override final  String? key;
@override final  String? label;
@override final  String storagePath;
@override final  int pageCount;
 final  List<PageSize> _pageSizes;
@override@JsonKey(fromJson: _pageSizesFromJson, toJson: _pageSizesToJson) List<PageSize> get pageSizes {
  if (_pageSizes is EqualUnmodifiableListView) return _pageSizes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pageSizes);
}

@override final  int sizeBytes;
@override final  String? uploadedBy;
@override final  DateTime createdAt;

/// Create a copy of Sheet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SheetCopyWith<_Sheet> get copyWith => __$SheetCopyWithImpl<_Sheet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SheetToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Sheet&&(identical(other.id, id) || other.id == id)&&(identical(other.songId, songId) || other.songId == songId)&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&const DeepCollectionEquality().equals(other.pageSizes, _pageSizes)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.uploadedBy, uploadedBy) || other.uploadedBy == uploadedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,songId,key,label,storagePath,pageCount,const DeepCollectionEquality().hash(_pageSizes),sizeBytes,uploadedBy,createdAt);
}

@override
String toString() {
    return 'Sheet(id: $id, songId: $songId, key: $key, label: $label, storagePath: $storagePath, pageCount: $pageCount, pageSizes: $pageSizes, sizeBytes: $sizeBytes, uploadedBy: $uploadedBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SheetCopyWith<$Res> implements $SheetCopyWith<$Res> {
  factory _$SheetCopyWith(_Sheet value, $Res Function(_Sheet) _then) = __$SheetCopyWithImpl;
@override @useResult
$Res call({
 int id, int songId, String? key, String? label, String storagePath, int pageCount,@JsonKey(fromJson: _pageSizesFromJson, toJson: _pageSizesToJson) List<PageSize> pageSizes, int sizeBytes, String? uploadedBy, DateTime createdAt
});




}
/// @nodoc
class __$SheetCopyWithImpl<$Res>
    implements _$SheetCopyWith<$Res> {
  __$SheetCopyWithImpl(this._self, this._then);

  final _Sheet _self;
  final $Res Function(_Sheet) _then;

/// Create a copy of Sheet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? songId = null,Object? key = freezed,Object? label = freezed,Object? storagePath = null,Object? pageCount = null,Object? pageSizes = null,Object? sizeBytes = null,Object? uploadedBy = freezed,Object? createdAt = null,}) {
  return _then(_Sheet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,songId: null == songId ? _self.songId : songId // ignore: cast_nullable_to_non_nullable
as int,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,pageSizes: null == pageSizes ? _self._pageSizes : pageSizes // ignore: cast_nullable_to_non_nullable
as List<PageSize>,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,uploadedBy: freezed == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$SongHistoryEntry {

 int get sessionId; String get sessionTitle; DateTime get startsAt; String? get key;
/// Create a copy of SongHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SongHistoryEntryCopyWith<SongHistoryEntry> get copyWith => _$SongHistoryEntryCopyWithImpl<SongHistoryEntry>(this as SongHistoryEntry, _$identity);

  /// Serializes this SongHistoryEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SongHistoryEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SongHistoryEntry&&(identical(other.sessionId, _this.sessionId) || other.sessionId == _this.sessionId)&&(identical(other.sessionTitle, _this.sessionTitle) || other.sessionTitle == _this.sessionTitle)&&(identical(other.startsAt, _this.startsAt) || other.startsAt == _this.startsAt)&&(identical(other.key, _this.key) || other.key == _this.key));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SongHistoryEntry;
  return Object.hash(runtimeType,_this.sessionId,_this.sessionTitle,_this.startsAt,_this.key);
}

@override
String toString() {
  final _this = this as SongHistoryEntry;
  return 'SongHistoryEntry(sessionId: ${_this.sessionId}, sessionTitle: ${_this.sessionTitle}, startsAt: ${_this.startsAt}, key: ${_this.key})';
}


}

/// @nodoc
abstract mixin class $SongHistoryEntryCopyWith<$Res>  {
  factory $SongHistoryEntryCopyWith(SongHistoryEntry value, $Res Function(SongHistoryEntry) _then) = _$SongHistoryEntryCopyWithImpl;
@useResult
$Res call({
 int sessionId, String sessionTitle, DateTime startsAt, String? key
});




}
/// @nodoc
class _$SongHistoryEntryCopyWithImpl<$Res>
    implements $SongHistoryEntryCopyWith<$Res> {
  _$SongHistoryEntryCopyWithImpl(this._self, this._then);

  final SongHistoryEntry _self;
  final $Res Function(SongHistoryEntry) _then;

/// Create a copy of SongHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? sessionTitle = null,Object? startsAt = null,Object? key = freezed,}) {
  return _then(SongHistoryEntry(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as int,sessionTitle: null == sessionTitle ? _self.sessionTitle : sessionTitle // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SongHistoryEntry].
extension SongHistoryEntryPatterns on SongHistoryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SongHistoryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SongHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SongHistoryEntry value)  $default,){
final _that = this;
switch (_that) {
case _SongHistoryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SongHistoryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _SongHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int sessionId,  String sessionTitle,  DateTime startsAt,  String? key)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SongHistoryEntry() when $default != null:
return $default(_that.sessionId,_that.sessionTitle,_that.startsAt,_that.key);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int sessionId,  String sessionTitle,  DateTime startsAt,  String? key)  $default,) {final _that = this;
switch (_that) {
case _SongHistoryEntry():
return $default(_that.sessionId,_that.sessionTitle,_that.startsAt,_that.key);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int sessionId,  String sessionTitle,  DateTime startsAt,  String? key)?  $default,) {final _that = this;
switch (_that) {
case _SongHistoryEntry() when $default != null:
return $default(_that.sessionId,_that.sessionTitle,_that.startsAt,_that.key);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SongHistoryEntry implements SongHistoryEntry {
  const _SongHistoryEntry({required this.sessionId, required this.sessionTitle, required this.startsAt, this.key});
  factory _SongHistoryEntry.fromJson(Map<String, dynamic> json) => _$SongHistoryEntryFromJson(json);

@override final  int sessionId;
@override final  String sessionTitle;
@override final  DateTime startsAt;
@override final  String? key;

/// Create a copy of SongHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SongHistoryEntryCopyWith<_SongHistoryEntry> get copyWith => __$SongHistoryEntryCopyWithImpl<_SongHistoryEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SongHistoryEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SongHistoryEntry&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.sessionTitle, sessionTitle) || other.sessionTitle == sessionTitle)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.key, key) || other.key == key));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,sessionId,sessionTitle,startsAt,key);
}

@override
String toString() {
    return 'SongHistoryEntry(sessionId: $sessionId, sessionTitle: $sessionTitle, startsAt: $startsAt, key: $key)';
}


}

/// @nodoc
abstract mixin class _$SongHistoryEntryCopyWith<$Res> implements $SongHistoryEntryCopyWith<$Res> {
  factory _$SongHistoryEntryCopyWith(_SongHistoryEntry value, $Res Function(_SongHistoryEntry) _then) = __$SongHistoryEntryCopyWithImpl;
@override @useResult
$Res call({
 int sessionId, String sessionTitle, DateTime startsAt, String? key
});




}
/// @nodoc
class __$SongHistoryEntryCopyWithImpl<$Res>
    implements _$SongHistoryEntryCopyWith<$Res> {
  __$SongHistoryEntryCopyWithImpl(this._self, this._then);

  final _SongHistoryEntry _self;
  final $Res Function(_SongHistoryEntry) _then;

/// Create a copy of SongHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? sessionTitle = null,Object? startsAt = null,Object? key = freezed,}) {
  return _then(_SongHistoryEntry(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as int,sessionTitle: null == sessionTitle ? _self.sessionTitle : sessionTitle // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
