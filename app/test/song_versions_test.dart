import 'package:flutter_test/flutter_test.dart';
import 'package:praiseteam/features/sessions/models.dart';
import 'package:praiseteam/features/sessions/sessions_providers.dart';
import 'package:praiseteam/features/songs/models.dart';
import 'package:praiseteam/features/songs/song_artwork.dart';
import 'package:praiseteam/l10n/app_localizations_en.dart';
import 'package:praiseteam/l10n/app_localizations_ko.dart';

/// Shapes below are what PostgREST returns for the selects in
/// SongsRepository and SessionsRepository.
void main() {
  Map<String, dynamic> version(int id, String? name, String? key, int? bpm) => {
    'id': id,
    'song_id': 1,
    'name': name,
    'default_key': key,
    'bpm': bpm,
    'created_by': null,
  };

  SongEntry entry({int? lastVersionId, String? usualKey}) => SongEntry(
    Song.fromJson({
      'id': 1,
      'team_id': 7,
      'title': '주의 집에 거하는 자',
      'time_signature': '4/4',
      'tags': <String>[],
      'notes': null,
      'song_versions': [version(10, '마커스워십', 'G', 72), version(11, '어노인팅', 'A', 76), version(12, null, 'G', 70)],
    }),
    SongStats(songId: 1, lastVersionId: lastVersionId, usualKey: usualKey),
  );

  group('a library entry', () {
    test('offers the version played last, else the oldest', () {
      expect(entry(lastVersionId: 11).preferredVersion?.name, '어노인팅');
      expect(entry().preferredVersion?.name, '마커스워십');
    });

    test('shows the usual key, else that of the version offered first', () {
      expect(entry(lastVersionId: 11, usualKey: 'G').displayKey, 'G');
      expect(entry(lastVersionId: 11).displayKey, 'A');
    });

    test('names its versions, leaving out unnamed ones', () {
      expect(entry().versionNames, '마커스워십, 어노인팅');
    });
  });

  group('a setlist entry', () {
    const selectedLink = SongLink(id: 1, versionId: 11, url: 'https://youtu.be/aqz-KE-bpKQ');
    const otherLink = SongLink(id: 2, versionId: 12, url: 'https://www.youtube.com/watch?v=dQw4w9WgXc');
    const picturedItem = SetlistItem(
      id: 5,
      sessionId: 3,
      position: 1,
      songId: 1,
      versionId: 11,
      song: SetlistSong(
        title: '주의 집에 거하는 자',
        versions: [
          SetlistVersion(links: [otherLink]),
        ],
      ),
      version: SetlistVersion(name: '선택한 버전', defaultKey: 'G', bpm: 72, links: [selectedLink]),
    );

    test('artwork prefers the version being played', () {
      expect(setlistThumbnail(picturedItem), linkThumbnail(selectedLink.url));
    });

    test('a version without video artwork uses another version of the same song', () {
      final item = picturedItem.copyWith(
        version: picturedItem.version!.copyWith(
          links: [const SongLink(id: 3, versionId: 11, url: 'https://open.spotify.com/track/1')],
        ),
      );
      expect(setlistThumbnail(item), linkThumbnail(otherLink.url));
      expect((item.versionId, item.effectiveKey, item.effectiveBpm), (11, 'G', 72));
    });

    test('nested artwork links survive the setlist snapshot used offline', () {
      final item = picturedItem.copyWith(version: picturedItem.version!.copyWith(links: const []));
      final restored = SetlistItem.fromJson(item.toJson());
      expect(setlistThumbnail(restored), linkThumbnail(otherLink.url));
    });

    test('plays its own key and tempo, else its version\'s', () {
      final item = SetlistItem.fromJson({
        'id': 5,
        'session_id': 3,
        'position': 1,
        'song_id': 1,
        'version_id': 11,
        'key': null,
        'bpm': 80,
        'sheet_id': null,
        'song_form': null,
        'notes': null,
        'songs': {'title': '주의 집에 거하는 자'},
        'song_versions': {'name': '어노인팅', 'default_key': 'A', 'bpm': 76},
      });
      expect((item.version?.name, item.effectiveKey, item.effectiveBpm), ('어노인팅', 'A', 80));
    });

    test('kept on a device from before versions still opens', () {
      final item = SetlistItem.fromJson({
        'id': 5,
        'session_id': 3,
        'position': 1,
        'song_id': 1,
        'key': 'G',
        'sheet_id': 9,
        'song_form': null,
        'notes': null,
        'songs': {'title': '주의 집에 거하는 자', 'artist': '마커스워십', 'default_key': 'G', 'bpm': 72},
      });
      expect((item.versionId, item.version, item.effectiveKey, item.sheetId), (null, null, 'G', 9));
      expect(setlistThumbnail(item), isNull);
    });
  });

  test('a sheet kept from before versions still opens', () {
    final sheet = Sheet.fromJson({
      'id': 9,
      'song_id': 1,
      'key': 'G',
      'label': null,
      'storage_path': '7/a.pdf',
      'page_count': 1,
      'page_sizes': [
        [595, 842],
      ],
      'size_bytes': 100,
      'uploaded_by': null,
      'created_at': '2026-11-01T00:00:00Z',
    });
    expect((sheet.versionId, sheet.pageCount), (null, 1));
  });

  test('a changed version is part of the summary', () {
    final changes = SetlistChanges.fromJson({
      'version_changed': [
        {'title': '주의 집에 거하는 자', 'from': '마커스워십', 'to': '어노인팅'},
      ],
      'key_changed': [
        {'title': '주의 집에 거하는 자', 'from': 'G', 'to': 'A'},
      ],
    });
    expect(changes.isEmpty, isFalse);
    expect(describeSetlistChanges(AppLocalizationsKo(), changes), '버전: 주의 집에 거하는 자(마커스워십→어노인팅) / 키: 주의 집에 거하는 자(G→A)');
    expect(
      describeSetlistChanges(AppLocalizationsEn(), changes),
      'Version: 주의 집에 거하는 자(마커스워십→어노인팅) / Key: 주의 집에 거하는 자(G→A)',
    );
  });
}
