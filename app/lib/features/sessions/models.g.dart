// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Session _$SessionFromJson(Map<String, dynamic> json) => _Session(
  id: (json['id'] as num).toInt(),
  teamId: (json['team_id'] as num).toInt(),
  title: json['title'] as String,
  startsAt: DateTime.parse(json['starts_at'] as String),
  location: json['location'] as String?,
  theme: json['theme'] as String?,
  notes: json['notes'] as String?,
  setlistStatus: $enumDecode(_$SetlistStatusEnumMap, json['setlist_status']),
  publishedAt: json['published_at'] == null
      ? null
      : DateTime.parse(json['published_at'] as String),
  songCount: json['setlist_items'] == null
      ? 0
      : _countFromJson(json['setlist_items']),
);

Map<String, dynamic> _$SessionToJson(_Session instance) => <String, dynamic>{
  'id': instance.id,
  'team_id': instance.teamId,
  'title': instance.title,
  'starts_at': instance.startsAt.toIso8601String(),
  'location': instance.location,
  'theme': instance.theme,
  'notes': instance.notes,
  'setlist_status': _$SetlistStatusEnumMap[instance.setlistStatus]!,
  'published_at': instance.publishedAt?.toIso8601String(),
};

const _$SetlistStatusEnumMap = {
  SetlistStatus.draft: 'draft',
  SetlistStatus.published: 'published',
};

_SessionTemplate _$SessionTemplateFromJson(Map<String, dynamic> json) =>
    _SessionTemplate(
      id: (json['id'] as num).toInt(),
      teamId: (json['team_id'] as num).toInt(),
      title: json['title'] as String,
      weekday: (json['weekday'] as num).toInt(),
      startTime: json['start_time'] as String,
      location: json['location'] as String?,
    );

Map<String, dynamic> _$SessionTemplateToJson(_SessionTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'team_id': instance.teamId,
      'title': instance.title,
      'weekday': instance.weekday,
      'start_time': instance.startTime,
      'location': instance.location,
    };

_SetlistSong _$SetlistSongFromJson(Map<String, dynamic> json) => _SetlistSong(
  title: json['title'] as String,
  versions:
      (json['song_versions'] as List<dynamic>?)
          ?.map((e) => SetlistVersion.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SetlistVersion>[],
);

Map<String, dynamic> _$SetlistSongToJson(_SetlistSong instance) =>
    <String, dynamic>{
      'title': instance.title,
      'song_versions': instance.versions.map((e) => e.toJson()).toList(),
    };

_SetlistVersion _$SetlistVersionFromJson(Map<String, dynamic> json) =>
    _SetlistVersion(
      name: json['name'] as String?,
      defaultKey: json['default_key'] as String?,
      bpm: (json['bpm'] as num?)?.toInt(),
      links:
          (json['song_links'] as List<dynamic>?)
              ?.map((e) => SongLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <SongLink>[],
    );

Map<String, dynamic> _$SetlistVersionToJson(_SetlistVersion instance) =>
    <String, dynamic>{
      'name': instance.name,
      'default_key': instance.defaultKey,
      'bpm': instance.bpm,
      'song_links': instance.links.map((e) => e.toJson()).toList(),
    };

_SetlistItem _$SetlistItemFromJson(Map<String, dynamic> json) => _SetlistItem(
  id: (json['id'] as num).toInt(),
  sessionId: (json['session_id'] as num).toInt(),
  position: (json['position'] as num).toInt(),
  songId: (json['song_id'] as num).toInt(),
  versionId: (json['version_id'] as num?)?.toInt(),
  key: json['key'] as String?,
  bpm: (json['bpm'] as num?)?.toInt(),
  sheetId: (json['sheet_id'] as num?)?.toInt(),
  songForm: json['song_form'] as String?,
  notes: json['notes'] as String?,
  song: SetlistSong.fromJson(json['songs'] as Map<String, dynamic>),
  version: json['song_versions'] == null
      ? null
      : SetlistVersion.fromJson(json['song_versions'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SetlistItemToJson(_SetlistItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'session_id': instance.sessionId,
      'position': instance.position,
      'song_id': instance.songId,
      'version_id': instance.versionId,
      'key': instance.key,
      'bpm': instance.bpm,
      'sheet_id': instance.sheetId,
      'song_form': instance.songForm,
      'notes': instance.notes,
      'songs': instance.song.toJson(),
      'song_versions': instance.version?.toJson(),
    };
