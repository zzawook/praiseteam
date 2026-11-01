import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
abstract class Song with _$Song {
  const factory Song({
    required int id,
    required int teamId,
    required String title,
    String? artist,
    String? defaultKey,
    int? bpm,
    String? timeSignature,
    @Default(<String>[]) List<String> tags,
    String? notes,
  }) = _Song;

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
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
  }) = _SongStats;

  factory SongStats.fromJson(Map<String, dynamic> json) => _$SongStatsFromJson(json);
}

/// A library entry: the song with its statistics.
class SongEntry {
  const SongEntry(this.song, this.stats);
  final Song song;
  final SongStats stats;

  /// The key the team usually plays, else the song's default key.
  String? get displayKey => stats.usualKey ?? song.defaultKey;
}

@freezed
abstract class SongLink with _$SongLink {
  const factory SongLink({
    required int id,
    required int songId,
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
    required int songId,
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
  }) = _SongHistoryEntry;

  factory SongHistoryEntry.fromJson(Map<String, dynamic> json) => _$SongHistoryEntryFromJson(json);
}

class SongDetail {
  const SongDetail({
    required this.song,
    required this.stats,
    required this.links,
    required this.sheets,
    required this.history,
  });
  final Song song;
  final SongStats stats;
  final List<SongLink> links;
  final List<Sheet> sheets;
  final List<SongHistoryEntry> history;
}

class TopSong {
  const TopSong(this.songId, this.title, this.times);
  final int songId;
  final String title;
  final int times;
}
