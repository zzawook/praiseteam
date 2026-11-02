import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:praiseteam/core/dates.dart';
import 'package:praiseteam/core/music.dart';
import 'package:praiseteam/features/sessions/models.dart';
import 'package:praiseteam/features/sessions/sessions_providers.dart';
import 'package:praiseteam/l10n/app_localizations.dart';

void main() {
  final ko = lookupAppLocalizations(const Locale('ko'));
  final en = lookupAppLocalizations(const Locale('en'));

  group('song form', () {
    test('normalises separators and case', () {
      expect(normalizeSongForm(' i v1  c-v2,c → b c '), 'I-V1-C-V2-C-B-C');
      expect(normalizeSongForm(''), '');
    });
  });

  group('keys', () {
    test('accepts what the database accepts', () {
      for (final k in allKeys) {
        expect(isValidKey(k), isTrue, reason: k);
      }
      expect(isValidKey('H'), isFalse);
      expect(isValidKey('C##'), isFalse);
      expect(isValidKey('cm'), isFalse);
    });
  });

  group('youtube', () {
    test('finds the video id in common link shapes', () {
      expect(youtubeId('https://www.youtube.com/watch?v=aqz-KE-bpKQ&t=30'), 'aqz-KE-bpKQ');
      expect(youtubeId('https://youtu.be/aqz-KE-bpKQ?si=x'), 'aqz-KE-bpKQ');
      expect(youtubeId('https://www.youtube.com/shorts/aqz-KE-bpKQ'), 'aqz-KE-bpKQ');
      expect(youtubeId('https://open.spotify.com/track/1'), isNull);
      expect(youtubeId('https://music.youtube.com/watch?v=aqz-KE-bpKQ'), 'aqz-KE-bpKQ');
      expect(youtubeId('https://www.youtube-nocookie.com/embed/aqz-KE-bpKQ'), 'aqz-KE-bpKQ');
      expect(youtubeId('https://youtube.com.example.org/watch?v=aqz-KE-bpKQ'), isNull);
      expect(youtubeId('https://youtu.be/too-short'), isNull);
    });
  });

  group('time ago', () {
    final now = DateTime(2026, 11, 1, 10);
    test('days, weeks, months', () {
      expect(timeAgo(ko, DateTime(2026, 11, 1, 8), now: now), '오늘');
      expect(timeAgo(ko, DateTime(2026, 10, 29), now: now), '3일 전');
      expect(timeAgo(ko, DateTime(2026, 10, 11), now: now), '3주 전');
      expect(timeAgo(en, DateTime(2026, 7, 1), now: now), '4 months ago');
      expect(timeAgo(en, DateTime(2026, 10, 31), now: now), 'yesterday');
    });
  });

  group('setlist changes', () {
    test('parses publish_setlist output and describes it', () {
      final changes = SetlistChanges.fromJson({
        'added': ['은혜'],
        'key_changed': [
          {'title': '주의 집에 거하는 자', 'from': 'G', 'to': 'A'},
        ],
        'reordered': true,
      });
      expect(changes.isEmpty, isFalse);
      expect(describeSetlistChanges(ko, changes), '추가: 은혜 / 키: 주의 집에 거하는 자(G→A) / 순서 변경');
      expect(describeSetlistChanges(en, changes), 'Added: 은혜 / Key: 주의 집에 거하는 자(G→A) / New order');
    });

    test('a changed tempo is part of the summary', () {
      final changes = SetlistChanges.fromJson({
        'tempo_changed': [
          {'title': '은혜', 'from': 68, 'to': 72},
          {'title': '주의 집에 거하는 자', 'to': 76}, // nulls are stripped
        ],
      });
      expect(changes.isEmpty, isFalse);
      expect(describeSetlistChanges(ko, changes), '템포: 은혜(68→72), 주의 집에 거하는 자(?→76)');
      expect(describeSetlistChanges(en, changes), 'Tempo: 은혜(68→72), 주의 집에 거하는 자(?→76)');
    });

    test('empty summary means nothing changed', () {
      expect(SetlistChanges.fromJson(const {}).isEmpty, isTrue);
      expect(SetlistChanges.fromJson(null).isEmpty, isTrue);
    });
  });
}
