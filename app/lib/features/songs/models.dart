import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

/// A song itself: what every way of playing it shares. How the team plays
/// it (whose version, its key and tempo, its sheets and links) is a
/// [SongVersion]; statistics count the song, whichever version was played.
@freezed
abstract class Song with _$Song {
  const factory Song({
    required int id,
    required int teamId,
    required String title,
    String? timeSignature,
    @Default(<String>[]) List<String> tags,
    String? notes,

    /// Oldest first, when the query embeds them.
    @JsonKey(name: 'song_versions') @Default(<SongVersion>[]) List<SongVersion> versions,
  }) = _Song;

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
}

/// One way the team plays a song: whose recording or arrangement it
/// follows, its usual key and tempo, and its sheets and links.
@freezed
abstract class SongVersion with _$SongVersion {
  const factory SongVersion({
    required int id,
    required int songId,

    /// An artist, a live recording, the team's own arrangement; may be none.
    String? name,
    String? defaultKey,
    int? bpm,
    String? createdBy,

    /// Oldest first, when the query embeds them.
    @Default(<Sheet>[]) List<Sheet> sheets,
    @JsonKey(name: 'song_links') @Default(<SongLink>[]) List<SongLink> links,
  }) = _SongVersion;

  factory SongVersion.fromJson(Map<String, dynamic> json) => _$SongVersionFromJson(json);
}

/// Row of the `song_stats` view.
@freezed
abstract class SongStats with _$SongStats {
  const factory SongStats({
    required int songId,
    @Default(0) int timesPlayed,
    DateTime? lastPlayedAt,
    DateTime? firstPlayedAt,
    String? usualKey,
    DateTime? nextPlannedAt,
    int? lastVersionId,
  }) = _SongStats;

  factory SongStats.fromJson(Map<String, dynamic> json) => _$SongStatsFromJson(json);
}

/// A library entry: the song (with its versions) and its statistics.
class SongEntry {
  const SongEntry(this.song, this.stats);
  final Song song;
  final SongStats stats;

  /// The version to offer first: the one played last, else the oldest.
  SongVersion? get preferredVersion =>
      song.versions.where((v) => v.id == stats.lastVersionId).firstOrNull ?? song.versions.firstOrNull;

  /// The key the team usually plays, else that of the version offered first.
  String? get displayKey => stats.usualKey ?? preferredVersion?.defaultKey;

  /// "마커스워십, 어노인팅", or null when no version has a name.
  String? get versionNames {
    final names = {for (final v in song.versions) ?v.name};
    return names.isEmpty ? null : names.join(', ');
  }
}

@freezed
abstract class SongLink with _$SongLink {
  const factory SongLink({
    required int id,
    required int versionId,
    String? label,
    required String url,
    @Default(0) int sortOrder,
  }) = _SongLink;

  factory SongLink.fromJson(Map<String, dynamic> json) => _$SongLinkFromJson(json);
}

@freezed
abstract class Sheet with _$Sheet {
  const factory Sheet({
    required int id,

    /// Null only in copies kept on a device from before versions.
    int? versionId,
    String? key,
    String? label,
    required String storagePath,
    required int pageCount,
    @JsonKey(fromJson: _pageSizesFromJson, toJson: _pageSizesToJson) required List<PageSize> pageSizes,
    required int sizeBytes,
    String? uploadedBy,
    required DateTime createdAt,
  }) = _Sheet;

  factory Sheet.fromJson(Map<String, dynamic> json) => _$SheetFromJson(json);
}

/// A PDF page size in points.
typedef PageSize = ({double width, double height});

List<PageSize> _pageSizesFromJson(List<dynamic> json) => [
      for (final pair in json)
        (width: ((pair as List)[0] as num).toDouble(), height: (pair[1] as num).toDouble()),
    ];

List<List<double>> _pageSizesToJson(List<PageSize> sizes) => [for (final s in sizes) [s.width, s.height]];

/// Row of the `song_history` view.
@freezed
abstract class SongHistoryEntry with _$SongHistoryEntry {
  const factory SongHistoryEntry({
    required int sessionId,
    required String sessionTitle,
    required DateTime startsAt,
    String? key,
    int? bpm,
    int? versionId,
    String? versionName,
  }) = _SongHistoryEntry;

  factory SongHistoryEntry.fromJson(Map<String, dynamic> json) => _$SongHistoryEntryFromJson(json);
}

class SongDetail {
  const SongDetail({required this.song, required this.stats, required this.history});

  /// With its versions, and each version's sheets and links.
  final Song song;
  final SongStats stats;
  final List<SongHistoryEntry> history;
}

class TopSong {
  const TopSong(this.songId, this.title, this.times);
  final int songId;
  final String title;
  final int times;
}
