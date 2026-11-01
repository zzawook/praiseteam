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

/// A service the team holds every week (주일 2부 예배, Sundays 11:00 at
/// 본당). Adding a service from it fills the title, time and place, and
/// picks the next week that doesn't have the service yet.
@freezed
abstract class SessionTemplate with _$SessionTemplate {
  const SessionTemplate._();

  const factory SessionTemplate({
    required int id,
    required int teamId,
    required String title,

    /// ISO 8601, as [DateTime.weekday]: 1 = Monday ... 7 = Sunday.
    required int weekday,

    /// Wall-clock 'HH:MM:SS' where the team meets.
    required String startTime,
    String? location,
  }) = _SessionTemplate;

  int get hour => int.parse(startTime.substring(0, 2));
  int get minute => int.parse(startTime.substring(3, 5));

  /// Sunday first, then Monday to Saturday; earlier services first.
  int get sortKey => (weekday % 7) * 24 * 60 + hour * 60 + minute;

  /// The first [weekday] at this time, after [now], whose day has no
  /// service with this title or starting at this time among [existing].
  DateTime nextStart(DateTime now, Iterable<Session> existing) {
    final taken = {
      for (final s in existing)
        if (s.title == title || (s.startsAt.toLocal().hour == hour && s.startsAt.toLocal().minute == minute))
          _dayKey(s.startsAt.toLocal()),
    };
    final first = now.day + (weekday - now.weekday) % 7;
    for (var week = 0;; week++) {
      final start = DateTime(now.year, now.month, first + 7 * week, hour, minute);
      if (start.isAfter(now) && !taken.contains(_dayKey(start))) return start;
    }
  }

  static int _dayKey(DateTime t) => (t.year * 100 + t.month) * 100 + t.day;

  factory SessionTemplate.fromJson(Map<String, dynamic> json) => _$SessionTemplateFromJson(json);
}

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

    /// This service's tempo; null plays it at the song's own.
    int? bpm,
    int? sheetId,
    String? songForm,
    String? notes,
    @JsonKey(name: 'songs') required SetlistSong song,
  }) = _SetlistItem;

  /// The key for this service, falling back to the song's default.
  String? get effectiveKey => key ?? song.defaultKey;

  /// The tempo for this service, falling back to the song's.
  int? get effectiveBpm => bpm ?? song.bpm;

  factory SetlistItem.fromJson(Map<String, dynamic> json) => _$SetlistItemFromJson(json);
}

/// What `publish_setlist` reports (see private.setlist_diff).
class SetlistChanges {
  const SetlistChanges({
    this.added = const [],
    this.removed = const [],
    this.keyChanged = const [],
    this.tempoChanged = const [],
    this.reordered = false,
  });

  factory SetlistChanges.fromJson(Map<String, dynamic>? json) => SetlistChanges(
        added: [for (final t in (json?['added'] as List? ?? const [])) t.toString()],
        removed: [for (final t in (json?['removed'] as List? ?? const [])) t.toString()],
        keyChanged: [
          for (final k in (json?['key_changed'] as List? ?? const []).cast<Map<String, dynamic>>())
            (title: k['title'].toString(), from: k['from'] as String?, to: k['to'] as String?),
        ],
        tempoChanged: [
          for (final t in (json?['tempo_changed'] as List? ?? const []).cast<Map<String, dynamic>>())
            (title: t['title'].toString(), from: t['from'] as int?, to: t['to'] as int?),
        ],
        reordered: json?['reordered'] == true,
      );

  final List<String> added;
  final List<String> removed;
  final List<({String title, String? from, String? to})> keyChanged;
  final List<({String title, int? from, int? to})> tempoChanged;
  final bool reordered;

  bool get isEmpty => added.isEmpty && removed.isEmpty && keyChanged.isEmpty && tempoChanged.isEmpty && !reordered;
}
