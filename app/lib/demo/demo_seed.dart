import 'dart:math' as math;
import 'dart:typed_data';

import '../core/team_time.dart';

typedef DemoRow = Map<String, dynamic>;
typedef DemoTables = Map<String, List<DemoRow>>;

const demoUserId = '00000000-0000-4000-8000-000000000001';

String demoPersonId(int index) =>
    '00000000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}';

/// Only fabricated/anonymized reference material goes into this manifest.
/// Dates are regenerated around this week so the demo never opens empty.
DemoTables seedDemo(Map<String, dynamic> reference, {DateTime? now}) {
  final time = TeamTime(
    reference['timezone'] as String? ?? TeamTime.defaultZone,
  );
  final today = time.local(now ?? DateTime.now());
  final serviceHour = reference['service_hour'] as int? ?? 14;
  var sunday = time.at(
    today.year,
    today.month,
    today.day + (DateTime.sunday - today.weekday) % 7,
    serviceHour,
  );
  if (!sunday.isAfter(today)) {
    sunday = time.at(sunday.year, sunday.month, sunday.day + 7, serviceHour);
  }
  String at(DateTime t) => t.toUtc().toIso8601String();
  final created = at(today.subtract(const Duration(days: 90)));
  final tables = <String, List<DemoRow>>{
    for (final name in [
      'profiles',
      'teams',
      'team_members',
      'parts',
      'member_parts',
      'songs',
      'song_versions',
      'song_links',
      'sheets',
      'sessions',
      'setlist_items',
      'default_slots',
      'session_slots',
      'assignments',
      'blockouts',
      'swap_requests',
      'rehearsals',
      'rehearsal_responses',
      'channels',
      'channel_parts',
      'messages',
      'channel_reads',
      'announcements',
      'announcement_seen',
      'polls',
      'poll_options',
      'poll_votes',
      'notifications',
      'notification_prefs',
      'session_templates',
      'strokes',
      'calendar_feeds',
      'device_tokens',
    ])
      name: [],
  };
  void add(String table, DemoRow row) => tables[table]!.add({
    'created_at': created,
    'updated_at': created,
    ...row,
  });
  final names = (reference['people'] as List).cast<String>();
  add('teams', {
    'id': 1,
    'name': reference['team_name'],
    'timezone': time.name,
    'invite_code': 'PRAISE26',
    'join_requires_approval': true,
    'created_by': demoUserId,
  });
  for (var i = 0; i < names.length; i++) {
    add('profiles', {
      'id': demoPersonId(i),
      'display_name': names[i],
      'avatar_path': null,
      'locale': 'ko',
    });
    add('team_members', {
      'team_id': 1,
      'user_id': demoPersonId(i),
      'role': i == 0
          ? 'owner'
          : i == 3
          ? 'leader'
          : 'member',
      'status': i == names.length - 1 ? 'pending' : 'active',
      'joined_at': created,
      'approved_at': created,
    });
  }
  const partNames = ['인도', '싱어', '건반', '세컨건반', '일렉기타', '베이스', '드럼', '음향'];
  const personParts = [
    [1],
    [2],
    [2],
    [3],
    [7],
    [6],
    [2, 4],
    [5],
    [8],
    [2],
  ];
  for (var i = 0; i < partNames.length; i++) {
    final id = i + 1;
    add('parts', {
      'id': id,
      'team_id': 1,
      'name': partNames[i],
      'kind': i < 2
          ? 'vocal'
          : i == 7
          ? 'tech'
          : 'instrument',
      'sort_order': id * 10,
      'archived_at': null,
    });
    if (id != 4) {
      add('default_slots', {
        'team_id': 1,
        'part_id': id,
        'count': id == 2 ? 4 : 1,
      });
    }
  }
  for (var i = 0; i < names.length; i++) {
    for (final part in personParts[i % personParts.length]) {
      add('member_parts', {
        'team_id': 1,
        'user_id': demoPersonId(i),
        'part_id': part,
      });
    }
  }
  final songs = (reference['songs'] as List).cast<Map<String, dynamic>>();
  for (var i = 0; i < songs.length; i++) {
    final song = songs[i], id = i + 1;
    add('songs', {
      'id': id,
      'team_id': 1,
      'title': song['title'],
      'time_signature': '4/4',
      'tags': song['tags'] ?? [],
      'notes': null,
      'created_by': demoUserId,
      'archived_at': null,
    });
    final versions = (song['versions'] as List).cast<String>();
    for (var v = 0; v < versions.length; v++) {
      final versionId = id * 10 + v;
      add('song_versions', {
        'id': versionId,
        'team_id': 1,
        'song_id': id,
        'name': versions[v],
        'default_key': v == 0 ? song['key'] : 'A',
        'bpm': song['bpm'] == null ? null : (song['bpm'] as int) + 4 * v,
        'created_by': demoUserId,
      });
      final links = (song['links'] as List?)?.cast<String>() ?? const [];
      for (final (j, url) in links.indexed) {
        add('song_links', {
          'id': versionId * 10 + j,
          'team_id': 1,
          'version_id': versionId,
          'label': '참고 영상',
          'url': url,
          'sort_order': j,
        });
      }
      if (i < 2) {
        final chart = i == 0 ? v + 1 : 3;
        add('sheets', {
          'id': versionId,
          'team_id': 1,
          'version_id': versionId,
          'key': v == 0 ? song['key'] : 'A',
          'label': '데모용 연습 차트',
          'storage_path': '1/demo-chart-$chart.pdf',
          'page_count': chart == 1 ? 2 : 1,
          'page_sizes': [
            for (var p = 0; p < (chart == 1 ? 2 : 1); p++) [595.28, 841.89],
          ],
          'size_bytes': 10000,
          'uploaded_by': demoUserId,
        });
      }
    }
  }
  add('session_templates', {
    'id': 1,
    'team_id': 1,
    'title': '주일 청년예배',
    'weekday': 7,
    'start_time': '${serviceHour.toString().padLeft(2, '0')}:00:00',
    'location': '본당',
  });
  add('session_templates', {
    'id': 2,
    'team_id': 1,
    'title': '금요 기도회',
    'weekday': 5,
    'start_time': '20:00:00',
    'location': '본당',
  });
  var itemId = 1, assignmentId = 1;
  const roster = [
    (1, 0),
    (2, 1),
    (2, 2),
    (2, 6),
    (3, 3),
    (5, 7),
    (6, 5),
    (7, 4),
    (8, 8),
  ];
  for (var week = -6; week < 4; week++) {
    final id = week + 107;
    final start = time.at(
      sunday.year,
      sunday.month,
      sunday.day + week * 7,
      serviceHour,
    );
    final status = week < 2 ? 'published' : 'draft';
    add('sessions', {
      'id': id,
      'team_id': 1,
      'title': '주일 청년예배',
      'starts_at': at(start),
      'location': '본당',
      'theme': week == 0 ? '함께 드리는 예배' : null,
      'notes': week == 0
          ? '주일 오후 1시까지 모여요. 1시 50분까지 연습을 마치고 함께 기도로 준비합니다.'
          : null,
      'setlist_status': status,
      'published_at': status == 'published' ? created : null,
      'created_by': demoUserId,
    });
    for (var position = 0; position < 4; position++) {
      final song = week == 0
          ? position % songs.length
          : (position + week.abs()) % songs.length;
      final version = tables['song_versions']!.firstWhere(
        (v) => v['song_id'] == song + 1,
      );
      add('setlist_items', {
        'id': itemId++,
        'team_id': 1,
        'session_id': id,
        'position': position + 1,
        'song_id': song + 1,
        'version_id': version['id'],
        'key': version['default_key'],
        'bpm': version['bpm'],
        'sheet_id': song < 2 ? version['id'] : null,
        'song_form': position == 0 ? 'I-V1-C-V2-C-B-C-O' : null,
        'notes': position == 0 ? '마지막 후렴 두 번' : null,
      });
    }
    if (status == 'published') {
      add('announcements', {
        'id': 1000 + id,
        'team_id': 1,
        'kind': 'setlist',
        'session_id': id,
        'title': '주일 청년예배',
        'body': null,
        'pinned': false,
        'created_by': demoUserId,
        'updated_at': at(
          start.isBefore(today)
              ? start
              : today.subtract(const Duration(hours: 12)),
        ),
        'change_summary': <String, dynamic>{},
        'setlist_snapshot': [
          for (final item in tables['setlist_items']!.where(
            (i) => i['session_id'] == id,
          ))
            {
              'item_id': item['id'],
              'song_id': item['song_id'],
              'title': songs[(item['song_id'] as int) - 1]['title'],
              'version_id': item['version_id'],
              'version': tables['song_versions']!.firstWhere(
                (v) => v['id'] == item['version_id'],
              )['name'],
              'key': item['key'],
              'bpm': item['bpm'],
            },
        ],
      });
    }
    for (final slot in tables['default_slots']!) {
      add('session_slots', {...slot, 'session_id': id});
    }
    for (final (part, person) in roster) {
      final state = week >= 2
          ? 'draft'
          : week == 0 && part == 7
          ? 'declined'
          : week == 0 && person == 2 || week == 1 && person == 0
          ? 'pending'
          : 'accepted';
      add('assignments', {
        'id': assignmentId++,
        'team_id': 1,
        'session_id': id,
        'part_id': part,
        'user_id': demoPersonId(person),
        'status': state,
        'source': 'manual',
        'decline_reason': state == 'declined' ? '이번 주는 참석이 어려워요.' : null,
        'sent_at': state == 'draft' ? null : created,
        'responded_at': state == 'accepted' ? created : null,
      });
    }
  }
  for (var week = 0; week < 2; week++) {
    final id = week + 1;
    add('rehearsals', {
      'id': id,
      'team_id': 1,
      'session_id': 107 + week,
      'starts_at': at(
        time.at(sunday.year, sunday.month, sunday.day + week * 7 - 1, 14),
      ),
      'location': '본당',
      'notes': '오후 2시-4시 합주 후 팀 나눔',
      'created_by': demoUserId,
    });
    for (var i = 1; i < 7; i++) {
      add('rehearsal_responses', {
        'team_id': 1,
        'rehearsal_id': id,
        'user_id': demoPersonId(i),
        'rsvp': i == 2 ? 'late' : 'going',
        'attendance': null,
      });
    }
  }
  add('blockouts', {
    'id': 1,
    'team_id': 1,
    'user_id': demoPersonId(4),
    'starts_on':
        '${sunday.year}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}',
    'ends_on':
        '${sunday.year}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}',
    'note': '가족 일정',
  });
  for (final (id, name, kind) in [
    (1, '전체', 'team'),
    (2, '싱어팀', 'parts'),
    (3, '악기팀', 'parts'),
    (4, '주일 2부 예배', 'session'),
  ]) {
    add('channels', {
      'id': id,
      'team_id': 1,
      'name': name,
      'kind': kind,
      'session_id': kind == 'session' ? 107 : null,
      'created_by': demoUserId,
      'archived_at': null,
    });
  }
  for (final p in tables['parts']!) {
    if (p['kind'] != 'tech') {
      add('channel_parts', {
        'team_id': 1,
        'channel_id': p['kind'] == 'vocal' ? 2 : 3,
        'part_id': p['id'],
      });
    }
  }
  final messages = (reference['messages'] as List).cast<Map<String, dynamic>>();
  for (final (i, message) in messages.indexed) {
    add('messages', {
      'id': '10000000-0000-4000-8000-${(i + 1).toString().padLeft(12, '0')}',
      'team_id': 1,
      'channel_id': 1,
      'sender_id': demoPersonId(message['person'] as int),
      'body': message['text'],
      'poll_id': null,
      'deleted_at': null,
      'created_at': at(today.subtract(Duration(minutes: 45 - i * 8))),
    });
  }
  final notice = Map<String, dynamic>.from(reference['announcement'] as Map);
  add('announcements', {
    'id': 1,
    'team_id': 1,
    'kind': 'general',
    'session_id': null,
    'title': notice['title'],
    'body': notice['body'],
    'pinned': true,
    'created_by': demoPersonId(3),
    'updated_at': at(today.subtract(const Duration(hours: 2))),
  });
  add('polls', {
    'id': 1,
    'team_id': 1,
    'channel_id': 1,
    'question': '다음 팀 모임은 언제가 좋을까요?',
    'multiple': false,
    'anonymous': false,
    'closes_at': at(today.add(const Duration(days: 7))),
    'created_by': demoUserId,
  });
  for (final (i, label) in ['토요일 점심', '주일 예배 후', '평일 저녁'].indexed) {
    add('poll_options', {
      'id': i + 1,
      'team_id': 1,
      'poll_id': 1,
      'label': label,
      'position': i + 1,
    });
  }
  for (var i = 1; i < 7; i++) {
    add('poll_votes', {
      'team_id': 1,
      'poll_id': 1,
      'option_id': i < 5 ? 2 : 1,
      'user_id': demoPersonId(i),
    });
  }
  add('messages', {
    'id': '10000000-0000-4000-8000-000000000100',
    'team_id': 1,
    'channel_id': 1,
    'sender_id': demoUserId,
    'body': null,
    'poll_id': 1,
    'deleted_at': null,
    'created_at': at(today.subtract(const Duration(minutes: 5))),
  });
  add('notifications', {
    'id': 1,
    'team_id': 1,
    'user_id': demoUserId,
    'category': 'announcement',
    'params': {
      'title': notice['title'],
      'preview': notice['body'],
      'team_name': reference['team_name'],
      'timezone': time.name,
    },
    'listed': true,
    'read_at': null,
    'created_at': at(today.subtract(const Duration(hours: 2))),
  });
  add('notifications', {
    'id': 2,
    'team_id': 1,
    'user_id': demoUserId,
    'category': 'member_join_request',
    'params': {'user_name': names.last, 'team_name': reference['team_name']},
    'listed': true,
    'read_at': null,
    'created_at': at(today.subtract(const Duration(hours: 1))),
  });
  final first = tables['setlist_items']!.firstWhere(
    (i) => i['session_id'] == 107,
  );
  final points = BytesBuilder();
  for (var i = 0; i <= 20; i++) {
    final data = ByteData(5)
      ..setUint16(0, ((0.18 + i * 0.018) * 65535).round(), Endian.little)
      ..setUint16(
        2,
        ((0.405 + math.sin(i / 3) * 0.002) * 65535).round(),
        Endian.little,
      )
      ..setUint8(4, 180);
    points.add(data.buffer.asUint8List());
  }
  add('strokes', {
    'id': '20000000-0000-4000-8000-000000000001',
    'team_id': 1,
    'session_id': 107,
    'setlist_item_id': first['id'],
    'sheet_id': first['sheet_id'],
    'page_index': 0,
    'owner_id': demoPersonId(3),
    'visibility': 'team',
    'tool': 'pen',
    'color': 0xff2541b2.toSigned(32),
    'width': 0.004,
    'points':
        '\\x${points.takeBytes().map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
    'deleted_at': null,
  });
  return tables;
}
