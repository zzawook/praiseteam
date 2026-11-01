import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

enum SetlistStatus { draft, published }

@freezed
abstract class Session with _$Session {
  const factory Session({
    required int id,
    required int teamId,
    required String title,
    required DateTime startsAt,
    String? location,
    String? theme,
    String? notes,
    required SetlistStatus setlistStatus,
    DateTime? publishedAt,
    // `setlist_items(count)` embeds as [{"count": n}]; members see the
    // count only once the setlist is published (RLS).
    @JsonKey(name: 'setlist_items', fromJson: _countFromJson, includeToJson: false) @Default(0) int songCount,
  }) = _Session;

  factory Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);
}

int _countFromJson(Object? json) =>
    json is List && json.isNotEmpty ? ((json.first as Map<String, dynamic>)['count'] as int? ?? 0) : 0;

@freezed
abstract class SetlistSong with _$SetlistSong {
  const factory SetlistSong({required String title, String? artist, String? defaultKey, int? bpm}) = _SetlistSong;

  factory SetlistSong.fromJson(Map<String, dynamic> json) => _$SetlistSongFromJson(json);
}

@freezed
abstract class SetlistItem with _$SetlistItem {
  const SetlistItem._();

  const factory SetlistItem({
    required int id,
    required int sessionId,
    required int position,
    required int songId,
    String? key,
    int? sheetId,
    String? songForm,
    String? notes,
    @JsonKey(name: 'songs') required SetlistSong song,
  }) = _SetlistItem;

  /// The key for this service, falling back to the song's default.
  String? get effectiveKey => key ?? song.defaultKey;

  factory SetlistItem.fromJson(Map<String, dynamic> json) => _$SetlistItemFromJson(json);
}

/// What `publish_setlist` reports (see private.setlist_diff).
class SetlistChanges {
  const SetlistChanges({
    this.added = const [],
    this.removed = const [],
    this.keyChanged = const [],
    this.reordered = false,
  });

  factory SetlistChanges.fromJson(Map<String, dynamic>? json) => SetlistChanges(
        added: [for (final t in (json?['added'] as List? ?? const [])) t.toString()],
        removed: [for (final t in (json?['removed'] as List? ?? const [])) t.toString()],
        keyChanged: [
          for (final k in (json?['key_changed'] as List? ?? const []).cast<Map<String, dynamic>>())
            (title: k['title'].toString(), from: k['from'] as String?, to: k['to'] as String?),
        ],
        reordered: json?['reordered'] == true,
      );

  final List<String> added;
  final List<String> removed;
  final List<({String title, String? from, String? to})> keyChanged;
  final bool reordered;

  bool get isEmpty => added.isEmpty && removed.isEmpty && keyChanged.isEmpty && !reordered;
}
