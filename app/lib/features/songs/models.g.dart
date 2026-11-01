// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Song _$SongFromJson(Map<String, dynamic> json) => _Song(
  id: (json['id'] as num).toInt(),
  teamId: (json['team_id'] as num).toInt(),
  title: json['title'] as String,
  timeSignature: json['time_signature'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  notes: json['notes'] as String?,
  versions:
      (json['song_versions'] as List<dynamic>?)
          ?.map((e) => SongVersion.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SongVersion>[],
);

Map<String, dynamic> _$SongToJson(_Song instance) => <String, dynamic>{
  'id': instance.id,
  'team_id': instance.teamId,
  'title': instance.title,
  'time_signature': instance.timeSignature,
  'tags': instance.tags,
  'notes': instance.notes,
  'song_versions': instance.versions.map((e) => e.toJson()).toList(),
};

_SongVersion _$SongVersionFromJson(Map<String, dynamic> json) => _SongVersion(
  id: (json['id'] as num).toInt(),
  songId: (json['song_id'] as num).toInt(),
  name: json['name'] as String?,
  defaultKey: json['default_key'] as String?,
  bpm: (json['bpm'] as num?)?.toInt(),
  createdBy: json['created_by'] as String?,
  sheets:
      (json['sheets'] as List<dynamic>?)
          ?.map((e) => Sheet.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Sheet>[],
  links:
      (json['song_links'] as List<dynamic>?)
          ?.map((e) => SongLink.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SongLink>[],
);

Map<String, dynamic> _$SongVersionToJson(_SongVersion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'song_id': instance.songId,
      'name': instance.name,
      'default_key': instance.defaultKey,
      'bpm': instance.bpm,
      'created_by': instance.createdBy,
      'sheets': instance.sheets.map((e) => e.toJson()).toList(),
      'song_links': instance.links.map((e) => e.toJson()).toList(),
    };

_SongStats _$SongStatsFromJson(Map<String, dynamic> json) => _SongStats(
  songId: (json['song_id'] as num).toInt(),
  timesPlayed: (json['times_played'] as num?)?.toInt() ?? 0,
  lastPlayedAt: json['last_played_at'] == null
      ? null
      : DateTime.parse(json['last_played_at'] as String),
  firstPlayedAt: json['first_played_at'] == null
      ? null
      : DateTime.parse(json['first_played_at'] as String),
  usualKey: json['usual_key'] as String?,
  nextPlannedAt: json['next_planned_at'] == null
      ? null
      : DateTime.parse(json['next_planned_at'] as String),
  lastVersionId: (json['last_version_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$SongStatsToJson(_SongStats instance) =>
    <String, dynamic>{
      'song_id': instance.songId,
      'times_played': instance.timesPlayed,
      'last_played_at': instance.lastPlayedAt?.toIso8601String(),
      'first_played_at': instance.firstPlayedAt?.toIso8601String(),
      'usual_key': instance.usualKey,
      'next_planned_at': instance.nextPlannedAt?.toIso8601String(),
      'last_version_id': instance.lastVersionId,
    };

_SongLink _$SongLinkFromJson(Map<String, dynamic> json) => _SongLink(
  id: (json['id'] as num).toInt(),
  versionId: (json['version_id'] as num).toInt(),
  label: json['label'] as String?,
  url: json['url'] as String,
  sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SongLinkToJson(_SongLink instance) => <String, dynamic>{
  'id': instance.id,
  'version_id': instance.versionId,
  'label': instance.label,
  'url': instance.url,
  'sort_order': instance.sortOrder,
};

_Sheet _$SheetFromJson(Map<String, dynamic> json) => _Sheet(
  id: (json['id'] as num).toInt(),
  versionId: (json['version_id'] as num?)?.toInt(),
  key: json['key'] as String?,
  label: json['label'] as String?,
  storagePath: json['storage_path'] as String,
  pageCount: (json['page_count'] as num).toInt(),
  pageSizes: _pageSizesFromJson(json['page_sizes'] as List),
  sizeBytes: (json['size_bytes'] as num).toInt(),
  uploadedBy: json['uploaded_by'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$SheetToJson(_Sheet instance) => <String, dynamic>{
  'id': instance.id,
  'version_id': instance.versionId,
  'key': instance.key,
  'label': instance.label,
  'storage_path': instance.storagePath,
  'page_count': instance.pageCount,
  'page_sizes': _pageSizesToJson(instance.pageSizes),
  'size_bytes': instance.sizeBytes,
  'uploaded_by': instance.uploadedBy,
  'created_at': instance.createdAt.toIso8601String(),
};

_SongHistoryEntry _$SongHistoryEntryFromJson(Map<String, dynamic> json) =>
    _SongHistoryEntry(
      sessionId: (json['session_id'] as num).toInt(),
      sessionTitle: json['session_title'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      key: json['key'] as String?,
      bpm: (json['bpm'] as num?)?.toInt(),
      versionId: (json['version_id'] as num?)?.toInt(),
      versionName: json['version_name'] as String?,
    );

Map<String, dynamic> _$SongHistoryEntryToJson(_SongHistoryEntry instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'session_title': instance.sessionTitle,
      'starts_at': instance.startsAt.toIso8601String(),
      'key': instance.key,
      'bpm': instance.bpm,
      'version_id': instance.versionId,
      'version_name': instance.versionName,
    };
