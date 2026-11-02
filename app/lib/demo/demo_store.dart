import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'demo_seed.dart';

class DemoChange {
  const DemoChange(this.table, this.kind, this.row, this.before);
  final String table, kind;
  final DemoRow row, before;
}

class DemoFailure implements Exception {
  const DemoFailure(this.code, this.message, {this.status = 400});
  final String code, message;
  final int status;
}

/// The demo owns only these browser-local rows. It never forwards a request
/// to a real database; the normal repositories and UI consume this adapter.
class DemoStore {
  DemoStore(this.tables, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final DemoTables tables;
  final DateTime Function() _clock;
  final changes = StreamController<DemoChange>.broadcast();
  void Function()? onSaved;
  String userId = demoUserId;
  String get timestamp => _clock().toUtc().toIso8601String();

  List<DemoRow> rows(String table) =>
      tables[table] ??
      (throw DemoFailure('42P01', 'Unknown demo table: $table'));
  DemoRow? row(String table, Object? id) =>
      rows(table).where((r) => r['id'] == id).firstOrNull;
  int nextId(String table) =>
      rows(table)
          .map((r) => r['id'])
          .whereType<int>()
          .fold(0, (a, b) => a > b ? a : b) +
      1;
  DemoRow? membership(Object? team) =>
      rows('team_members')
          .where((m) => m['team_id'] == team && m['user_id'] == userId)
          .firstOrNull;
  bool member(Object? team) => membership(team)?['status'] == 'active';
  bool leader(Object? team) =>
      member(team) &&
      const ['owner', 'leader'].contains(membership(team)?['role']);
  void requireLeader(Object? team) {
    if (!leader(team)) {
      throw const DemoFailure(
        '42501',
        'Only team leaders can do this',
        status: 403,
      );
    }
  }

  List<DemoRow> read(
    String table,
    Map<String, String> query, {
    Map<String, List<String>>? allQuery,
  }) {
    final source = table == 'song_stats'
        ? _stats()
        : table == 'song_history'
        ? _history()
        : rows(table);
    var result =
        [
              for (final r in source)
                if (_visible(table, r)) hydrate(table, r),
            ]
            .where(
              (r) => allQuery == null
                  ? matches(r, query)
                  : matchesAll(r, allQuery),
            )
            .toList();
    final order = query['order'];
    if (order != null) {
      result.sort((a, b) {
        for (final clause in order.split(',')) {
          final bits = clause.split('.');
          final cmp = _compare(a[bits.first], b[bits.first]);
          if (cmp != 0) return bits.contains('desc') ? -cmp : cmp;
        }
        return 0;
      });
    }
    final offset = int.tryParse(query['offset'] ?? '') ?? 0;
    final limit = int.tryParse(query['limit'] ?? '') ?? 1000;
    result = result.skip(offset).take(limit).toList();
    return result;
  }

  bool _visible(String table, DemoRow r) {
    if (table == 'profiles') return true;
    if (table == 'teams') return membership(r['id']) != null;
    if (table == 'team_members') {
      return r['user_id'] == userId ||
          (member(r['team_id']) &&
              (r['status'] == 'active' || leader(r['team_id'])));
    }
    if (const [
      'notification_prefs',
      'notifications',
      'device_tokens',
      'calendar_feeds',
      'channel_reads',
      'announcement_seen',
      'poll_votes',
    ].contains(table)) {
      return r['user_id'] == userId;
    }
    if (r['team_id'] != null && !member(r['team_id'])) return false;
    if (table == 'setlist_items' || table == 'strokes') {
      final session = row('sessions', r['session_id']);
      if (session?['setlist_status'] != 'published' && !leader(r['team_id'])) {
        return false;
      }
    }
    if (table == 'strokes') {
      return r['visibility'] == 'team' || r['owner_id'] == userId;
    }
    if (table == 'assignments' && r['status'] == 'draft') {
      return leader(r['team_id']);
    }
    if (table == 'blockouts' || table == 'rehearsal_responses') {
      return r['user_id'] == userId || leader(r['team_id']);
    }
    if (table == 'channels') return canReadChannel(r);
    if (table == 'messages') {
      return canReadChannel(row('channels', r['channel_id']) ?? {});
    }
    return true;
  }

  bool canReadChannel(DemoRow c) =>
      member(c['team_id']) &&
      (leader(c['team_id']) ||
          c['kind'] == 'team' ||
          c['kind'] == 'parts' &&
              rows('channel_parts').any(
                (p) =>
                    p['channel_id'] == c['id'] &&
                    rows('member_parts').any(
                      (m) =>
                          m['team_id'] == c['team_id'] &&
                          m['user_id'] == userId &&
                          m['part_id'] == p['part_id'],
                    ),
              ) ||
          c['kind'] == 'session' &&
              rows('assignments').any(
                (a) =>
                    a['session_id'] == c['session_id'] &&
                    a['user_id'] == userId &&
                    ['pending', 'accepted'].contains(a['status']),
              ));

  DemoRow hydrate(String table, DemoRow r) {
    final result = DemoRow.from(r);
    switch (table) {
      case 'team_members':
        result['teams'] = row('teams', r['team_id']);
        result['profiles'] = row('profiles', r['user_id']);
        result['member_parts'] = rows('member_parts')
            .where(
              (p) =>
                  p['team_id'] == r['team_id'] && p['user_id'] == r['user_id'],
            )
            .toList();
      case 'songs':
        result['song_versions'] = [
          for (final v in rows(
            'song_versions',
          ).where((v) => v['song_id'] == r['id']))
            hydrate('song_versions', v),
        ];
      case 'song_versions':
        result['sheets'] = rows('sheets')
            .where((s) => s['version_id'] == r['id'])
            .toList();
        result['song_links'] =
            rows('song_links').where((s) => s['version_id'] == r['id']).toList()
              ..sort((a, b) => _compare(a['sort_order'], b['sort_order']));
      case 'sessions':
        result['setlist_items'] = [
          {
            'count': rows('setlist_items')
                .where(
                  (i) =>
                      i['session_id'] == r['id'] &&
                      _visible('setlist_items', i),
                )
                .length,
          },
        ];
      case 'setlist_items':
        result['songs'] = hydrate('songs', row('songs', r['song_id'])!);
        result['song_versions'] = hydrate(
          'song_versions',
          row('song_versions', r['version_id'])!,
        );
      case 'assignments':
        result['sessions'] = row('sessions', r['session_id']);
        result['team_members'] = {'profiles': row('profiles', r['user_id'])};
      case 'rehearsals':
        result['rehearsal_responses'] = rows('rehearsal_responses')
            .where(
              (x) =>
                  x['rehearsal_id'] == r['id'] &&
                  _visible('rehearsal_responses', x),
            )
            .toList();
      case 'messages':
        result['profiles'] = row('profiles', r['sender_id']);
      case 'channels':
        result['channel_parts'] = rows('channel_parts')
            .where((p) => p['channel_id'] == r['id'])
            .toList();
    }
    return result;
  }

  static Object? _field(DemoRow row, String field) {
    Object? value = row;
    for (final part in field.split('.')) {
      value = value is Map ? value[part] : null;
    }
    return value;
  }

  static int _compare(Object? a, Object? b) {
    if (a == b) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    final an = num.tryParse('$a'), bn = num.tryParse('$b');
    if (an != null && bn != null) return an.compareTo(bn);
    final ad = DateTime.tryParse('$a'), bd = DateTime.tryParse('$b');
    if (ad != null && bd != null) return ad.compareTo(bd);
    return '$a'.compareTo('$b');
  }

  static bool matchesAll(DemoRow row, Map<String, List<String>> query) => query
      .entries
      .every((e) => e.value.every((value) => matches(row, {e.key: value})));

  static bool matches(DemoRow row, Map<String, String> query) {
    for (final entry in query.entries) {
      if ([
            'select',
            'order',
            'limit',
            'offset',
            'on_conflict',
          ].contains(entry.key) ||
          entry.key.endsWith('.order')) {
        continue;
      }
      final dot = entry.value.indexOf('.');
      if (dot < 0) continue;
      final op = entry.value.substring(0, dot),
          text = entry.value.substring(dot + 1);
      final value = _field(row, entry.key);
      final ok = switch (op) {
        'eq' => '$value' == text,
        'neq' => '$value' != text,
        'is' => text == 'null' ? value == null : '$value' == text,
        'in' =>
          text
              .replaceAll(RegExp(r'^[\(]|[\)]$'), '')
              .split(',')
              .map((x) => x.replaceAll('"', ''))
              .contains('$value'),
        'gte' => value != null && _compare(value, text) >= 0,
        'gt' => value != null && _compare(value, text) > 0,
        'lte' => value != null && _compare(value, text) <= 0,
        'lt' => value != null && _compare(value, text) < 0,
        _ => throw DemoFailure('22023', 'Unsupported demo filter: $op'),
      };
      if (!ok) return false;
    }
    return true;
  }

  DemoRow insert(
    String table,
    DemoRow input, {
    String? conflict,
    bool ignoreDuplicates = false,
  }) {
    final key = conflict?.split(',') ?? _keys[table] ?? ['id'];
    final existing = rows(table)
        .where(
          (r) => key.every((k) => input.containsKey(k) && r[k] == input[k]),
        )
        .firstOrNull;
    if (existing != null) {
      if (!ignoreDuplicates) update(table, existing, input);
      return existing;
    }
    final r = <String, dynamic>{
      'created_at': timestamp,
      'updated_at': timestamp,
      'created_by': userId,
      ...input,
    };
    if (!_keys.containsKey(table) && !r.containsKey('id')) {
      r['id'] = nextId(table);
    }
    switch (table) {
      case 'songs':
        r.addAll({
          'archived_at': null,
          'tags': input['tags'] ?? [],
          'notes': input['notes'],
          'time_signature': input['time_signature'],
        });
      case 'parts':
        r['archived_at'] = null;
      case 'sessions':
        r.addAll({'setlist_status': 'draft', 'published_at': null});
      case 'assignments':
        r.addAll({
          'status': input['status'] ?? 'draft',
          'source': input['source'] ?? 'manual',
          'decline_reason': null,
        });
      case 'announcements':
        r.addAll({'pinned': input['pinned'] ?? false});
      case 'channels':
        r['archived_at'] = null;
      case 'messages':
        r.addAll({
          'sender_id': input['sender_id'] ?? userId,
          'deleted_at': null,
          'poll_id': input['poll_id'],
        });
      case 'strokes':
        r.addAll({'owner_id': input['owner_id'] ?? userId, 'deleted_at': null});
      case 'blockouts' ||
          'rehearsal_responses' ||
          'channel_reads' ||
          'announcement_seen' ||
          'poll_votes' ||
          'notification_prefs' ||
          'calendar_feeds':
        r['user_id'] ??= userId;
      case 'sheets':
        r['uploaded_by'] ??= userId;
    }
    rows(table).add(r);
    if (table == 'sessions') {
      for (final d in rows(
        'default_slots',
      ).where((d) => d['team_id'] == r['team_id'])) {
        insert('session_slots', {...d, 'session_id': r['id']});
      }
    }
    _changed(table, 'insert', r, {});
    return r;
  }

  void update(String table, DemoRow row, DemoRow patch) {
    final before = DemoRow.from(row);
    row.addAll({...patch, 'updated_at': timestamp});
    _changed(table, 'update', row, before);
  }

  void delete(String table, DemoRow r) {
    final id = r['id'];
    if ((table == 'songs' &&
            rows('setlist_items').any((i) => i['song_id'] == id)) ||
        (table == 'song_versions' &&
            rows('setlist_items').any((i) => i['version_id'] == id))) {
      throw const DemoFailure(
        '23503',
        'This song version is still used by a setlist',
      );
    }
    if (table == 'sessions') {
      for (final child in [
        'setlist_items',
        'assignments',
        'session_slots',
        'rehearsals',
        'announcements',
        'channels',
      ]) {
        for (final x in rows(
          child,
        ).where((x) => x['session_id'] == id).toList()) {
          delete(child, x);
        }
      }
    }
    if (table == 'setlist_items') {
      rows('strokes').removeWhere((s) => s['setlist_item_id'] == id);
    }
    if (table == 'songs') {
      for (final v in rows(
        'song_versions',
      ).where((v) => v['song_id'] == id).toList()) {
        delete('song_versions', v);
      }
    }
    if (table == 'song_versions') {
      for (final child in ['song_links', 'sheets']) {
        for (final x in rows(
          child,
        ).where((x) => x['version_id'] == id).toList()) {
          delete(child, x);
        }
      }
    }
    if (table == 'sheets') {
      for (final i in rows('setlist_items').where((i) => i['sheet_id'] == id)) {
        i['sheet_id'] = null;
      }
      rows('strokes').removeWhere((s) => s['sheet_id'] == id);
    }
    if (table == 'channels') {
      for (final child in ['messages', 'channel_parts', 'channel_reads']) {
        rows(child).removeWhere((x) => x['channel_id'] == id);
      }
    }
    if (table == 'rehearsals') {
      rows('rehearsal_responses').removeWhere((x) => x['rehearsal_id'] == id);
    }
    if (table == 'assignments') {
      rows('swap_requests').removeWhere((x) => x['assignment_id'] == id);
    }
    rows(table).remove(r);
    _changed(table, 'delete', {}, r);
  }

  void _changed(String table, String kind, DemoRow row, DemoRow before) {
    changes.add(DemoChange(table, kind, DemoRow.from(row), before));
    onSaved?.call();
  }

  List<DemoRow> _history() => [
    for (final item in rows('setlist_items'))
      if (row('sessions', item['session_id']) case final service?
          when service['setlist_status'] == 'published')
        {
          'team_id': item['team_id'],
          'song_id': item['song_id'],
          'session_id': service['id'],
          'session_title': service['title'],
          'starts_at': service['starts_at'],
          'version_id': item['version_id'],
          'version_name': row('song_versions', item['version_id'])?['name'],
          'key':
              item['key'] ??
              row('song_versions', item['version_id'])?['default_key'],
          'bpm':
              item['bpm'] ?? row('song_versions', item['version_id'])?['bpm'],
        },
  ];

  List<DemoRow> _stats() {
    final history = _history(), now = _clock();
    return [
      for (final song in rows('songs'))
        (() {
          final played =
              history
                  .where(
                    (h) =>
                        h['song_id'] == song['id'] &&
                        !DateTime.parse(h['starts_at'] as String).isAfter(now),
                  )
                  .toList()
                ..sort((a, b) => _compare(b['starts_at'], a['starts_at']));
          final future =
              history
                  .where(
                    (h) =>
                        h['song_id'] == song['id'] &&
                        DateTime.parse(h['starts_at'] as String).isAfter(now),
                  )
                  .toList()
                ..sort((a, b) => _compare(a['starts_at'], b['starts_at']));
          return <String, dynamic>{
            'team_id': song['team_id'],
            'song_id': song['id'],
            'times_played': played.length,
            'last_played_at': played.firstOrNull?['starts_at'],
            'first_played_at': played.lastOrNull?['starts_at'],
            'usual_key': played.firstOrNull?['key'],
            'last_version_id': played.firstOrNull?['version_id'],
            'next_planned_at': future.firstOrNull?['starts_at'],
          };
        })(),
    ];
  }

  Object? rpc(String name, DemoRow p) {
    final team = p['p_team_id'];
    switch (name) {
      case 'add_song':
        final song = insert('songs', {
          'team_id': team,
          'title': p['p_title'],
          'time_signature': p['p_time_signature'],
          'tags': p['p_tags'] ?? [],
          'notes': p['p_notes'],
        });
        insert('song_versions', {
          'team_id': team,
          'song_id': song['id'],
          'name': p['p_version_name'],
          'default_key': p['p_key'],
          'bpm': p['p_bpm'],
        });
        return song['id'];
      case 'top_songs':
        final counts = <int, int>{};
        for (final h in _history()) {
          if (h['team_id'] == team &&
              _compare(h['starts_at'], p['p_from']) >= 0 &&
              _compare(h['starts_at'], p['p_to']) < 0 &&
              _compare(h['starts_at'], timestamp) <= 0) {
            counts.update(h['song_id'] as int, (n) => n + 1, ifAbsent: () => 1);
          }
        }
        return [
          for (final e in counts.entries)
            {
              'song_id': e.key,
              'title': row('songs', e.key)!['title'],
              'times': e.value,
            },
        ]..sort((a, b) => (b['times'] as int).compareTo(a['times'] as int));
      case 'reorder_setlist':
        for (final (i, id) in (p['p_item_ids'] as List).indexed) {
          update('setlist_items', row('setlist_items', id)!, {
            'position': i + 1,
          });
        }
        return null;
      case 'publish_setlist':
        return _publish(p['p_session_id'] as int);
      case 'copy_previous_strokes':
        final item = row('setlist_items', p['p_item_id'])!;
        final source =
            rows('setlist_items')
                .where(
                  (x) =>
                      x['id'] != item['id'] &&
                      x['sheet_id'] != null &&
                      x['sheet_id'] == item['sheet_id'],
                )
                .toList()
              ..sort(
                (a, b) => _compare(
                  row('sessions', b['session_id'])?['starts_at'],
                  row('sessions', a['session_id'])?['starts_at'],
                ),
              );
        final strokes = rows('strokes')
            .where(
              (s) =>
                  s['setlist_item_id'] == source.firstOrNull?['id'] &&
                  s['deleted_at'] == null &&
                  (s['owner_id'] == userId || s['visibility'] == 'team'),
            )
            .toList();
        for (final stroke in strokes) {
          insert('strokes', {
            ...stroke,
            'id': const Uuid().v4(),
            'session_id': item['session_id'],
            'setlist_item_id': item['id'],
            'owner_id': userId,
          });
        }
        return strokes.length;
      case 'send_assignments':
        final targets = rows('assignments')
            .where(
              (a) =>
                  (p['p_session_ids'] as List).contains(a['session_id']) &&
                  a['status'] == 'draft',
            )
            .toList();
        for (final a in targets) {
          update('assignments', a, {'status': 'pending', 'sent_at': timestamp});
        }
        return targets.length;
      case 'respond_assignment':
        final a = row('assignments', p['p_assignment_id'])!;
        update('assignments', a, {
          'status': p['p_accept'] == true ? 'accepted' : 'declined',
          'responded_at': timestamp,
          'decline_reason': p['p_reason'],
        });
        return null;
      case 'reassign_assignment':
        final a = row('assignments', p['p_assignment_id'])!;
        update('assignments', a, {
          'user_id': p['p_user_id'],
          'status': a['status'] == 'draft' ? 'draft' : 'pending',
          'decline_reason': null,
        });
        return null;
      case 'remove_assignment':
        delete('assignments', row('assignments', p['p_assignment_id'])!);
        return null;
      case 'request_swap':
        final a = row('assignments', p['p_assignment_id'])!;
        return insert('swap_requests', {
          'team_id': a['team_id'],
          'assignment_id': a['id'],
          'requested_by': userId,
          'message': p['p_message'],
          'status': 'open',
        })['id'];
      case 'accept_swap':
        final swap = row('swap_requests', p['p_swap_id'])!;
        update('assignments', row('assignments', swap['assignment_id'])!, {
          'user_id': userId,
          'status': 'accepted',
        });
        update('swap_requests', swap, {
          'status': 'filled',
          'filled_by': userId,
        });
        return null;
      case 'cancel_swap':
        update('swap_requests', row('swap_requests', p['p_swap_id'])!, {
          'status': 'cancelled',
        });
        return null;
      case 'set_rsvp' || 'record_attendance':
        final rehearsal = row('rehearsals', p['p_rehearsal_id'])!;
        insert('rehearsal_responses', {
          'team_id': rehearsal['team_id'],
          'rehearsal_id': rehearsal['id'],
          'user_id': p['p_user_id'] ?? userId,
          if (name == 'set_rsvp')
            'rsvp': p['p_rsvp']
          else
            'attendance': p['p_attendance'],
        });
        return null;
      case 'my_channels':
        return _channels(team);
      case 'mark_channel_read' || 'set_channel_muted':
        final channel = row('channels', p['p_channel_id'])!;
        insert('channel_reads', {
          'team_id': channel['team_id'],
          'channel_id': channel['id'],
          'user_id': userId,
          if (name == 'mark_channel_read')
            'last_read_at': timestamp
          else
            'muted': p['p_muted'],
        });
        return null;
      case 'mark_announcements_seen':
        insert('announcement_seen', {
          'team_id': team,
          'user_id': userId,
          'seen_at': timestamp,
        });
        return null;
      case 'create_poll':
        final poll = insert('polls', {
          'team_id': team,
          'channel_id': p['p_channel_id'],
          'announcement_id': p['p_announcement_id'],
          'question': p['p_question'],
          'multiple': p['p_multiple'] ?? false,
          'anonymous': p['p_anonymous'] ?? false,
          'closes_at': p['p_closes_at'],
        });
        for (final (i, label) in (p['p_options'] as List).indexed) {
          insert('poll_options', {
            'team_id': team,
            'poll_id': poll['id'],
            'label': label,
            'position': i + 1,
          });
        }
        if (p['p_channel_id'] != null) {
          insert('messages', {
            'id': const Uuid().v4(),
            'team_id': team,
            'channel_id': p['p_channel_id'],
            'poll_id': poll['id'],
            'body': null,
          });
        }
        return poll['id'];
      case 'poll_vote':
        final poll = row('polls', p['p_poll_id'])!;
        rows('poll_votes').removeWhere(
          (v) => v['poll_id'] == poll['id'] && v['user_id'] == userId,
        );
        for (final option in p['p_option_ids'] as List) {
          insert('poll_votes', {
            'team_id': poll['team_id'],
            'poll_id': poll['id'],
            'option_id': option,
            'user_id': userId,
          });
        }
        return null;
      case 'poll_results':
        final poll = row('polls', p['p_poll_id'])!;
        return [
          for (final option in rows(
            'poll_options',
          ).where((o) => o['poll_id'] == poll['id']))
            {
              'option_id': option['id'],
              'label': option['label'],
              'votes': rows('poll_votes')
                  .where((v) => v['option_id'] == option['id'])
                  .length,
              'mine': rows('poll_votes').any(
                (v) => v['option_id'] == option['id'] && v['user_id'] == userId,
              ),
              'voters': poll['anonymous'] == true
                  ? null
                  : [
                      for (final v in rows(
                        'poll_votes',
                      ).where((v) => v['option_id'] == option['id']))
                        row('profiles', v['user_id'])?['display_name'] ?? '',
                    ],
            },
        ];
      case 'create_team':
        final t = insert('teams', {
          'name': p['p_name'],
          'timezone': 'Asia/Singapore',
          'invite_code': const Uuid().v4().substring(0, 8).toUpperCase(),
          'join_requires_approval': true,
        });
        insert('team_members', {
          'team_id': t['id'],
          'user_id': userId,
          'role': 'owner',
          'status': 'active',
          'joined_at': timestamp,
          'approved_at': timestamp,
        });
        for (final part in rows(
          'parts',
        ).where((x) => x['team_id'] == 1).toList()) {
          insert('parts', {...part, 'id': nextId('parts'), 'team_id': t['id']});
        }
        insert('channels', {
          'team_id': t['id'],
          'name': '전체',
          'kind': 'team',
          'session_id': null,
        });
        return t['id'];
      case 'join_team':
        final t = rows('teams')
            .where(
              (t) =>
                  t['invite_code'] ==
                  '${p['p_invite_code']}'.trim().toUpperCase(),
            )
            .firstOrNull;
        if (t == null) throw const DemoFailure('P0002', 'Invalid invite code');
        if (membership(t['id']) == null) {
          insert('team_members', {
            'team_id': t['id'],
            'user_id': userId,
            'role': 'member',
            'status': t['join_requires_approval'] == true
                ? 'pending'
                : 'active',
            'joined_at': timestamp,
            'approved_at': timestamp,
          });
        }
        return t['id'];
      case 'approve_member':
        final m = rows('team_members').firstWhere(
          (m) => m['team_id'] == team && m['user_id'] == p['p_user_id'],
        );
        update('team_members', m, {
          'status': 'active',
          'approved_at': timestamp,
        });
        return null;
      case 'reject_member' || 'remove_member' || 'leave_team':
        final who = name == 'leave_team' ? userId : p['p_user_id'];
        final m = rows('team_members')
            .where((m) => m['team_id'] == team && m['user_id'] == who)
            .firstOrNull;
        if (m != null) {
          _lastOwner(m);
          delete('team_members', m);
          rows('member_parts')
              .removeWhere((x) => x['team_id'] == team && x['user_id'] == who);
        }
        return null;
      case 'set_member_role':
        final m = rows('team_members').firstWhere(
          (m) => m['team_id'] == team && m['user_id'] == p['p_user_id'],
        );
        if (p['p_role'] != 'owner') _lastOwner(m);
        update('team_members', m, {'role': p['p_role']});
        return null;
      case 'set_member_parts':
        rows('member_parts').removeWhere(
          (m) => m['team_id'] == team && m['user_id'] == p['p_user_id'],
        );
        for (final part in p['p_part_ids'] as List) {
          insert('member_parts', {
            'team_id': team,
            'user_id': p['p_user_id'],
            'part_id': part,
          });
        }
        return null;
      case 'rotate_invite_code':
        final code = const Uuid().v4().substring(0, 8).toUpperCase();
        update('teams', row('teams', team)!, {'invite_code': code});
        return code;
      case 'add_part':
        final part = insert('parts', {
          'team_id': team,
          'name': p['p_name'],
          'kind': p['p_kind'],
          'sort_order': rows('parts').length * 10 + 10,
        });
        for (final channel in p['p_channel_ids'] as List? ?? []) {
          insert('channel_parts', {
            'team_id': team,
            'channel_id': channel,
            'part_id': part['id'],
          });
        }
        return part['id'];
      case 'register_device_token':
        return null;
      default:
        throw DemoFailure(
          'DEMO_ONLY',
          'This action is not connected in the demo: $name',
        );
    }
  }

  void _lastOwner(DemoRow m) {
    if (m['role'] == 'owner' &&
        rows('team_members')
                .where(
                  (x) =>
                      x['team_id'] == m['team_id'] &&
                      x['role'] == 'owner' &&
                      x['status'] == 'active',
                )
                .length ==
            1) {
      throw const DemoFailure('23514', 'A team needs an owner');
    }
  }

  List<DemoRow> _channels(Object? team) => [
    for (final c in rows(
      'channels',
    ).where((c) => c['team_id'] == team && canReadChannel(c)))
      (() {
        final messages =
            rows('messages')
                .where(
                  (m) => m['channel_id'] == c['id'] && m['deleted_at'] == null,
                )
                .toList()
              ..sort((a, b) => _compare(b['created_at'], a['created_at']));
        final read = rows('channel_reads')
            .where((r) => r['channel_id'] == c['id'] && r['user_id'] == userId)
            .firstOrNull;
        final last = messages.firstOrNull;
        return <String, dynamic>{
          ...c,
          'archived': c['archived_at'] != null,
          'muted': read?['muted'] ?? false,
          'unread': messages
              .where(
                (m) =>
                    m['sender_id'] != userId &&
                    (read?['last_read_at'] == null ||
                        _compare(m['created_at'], read?['last_read_at']) > 0),
              )
              .length,
          'last_body':
              last?['body'] ?? row('polls', last?['poll_id'])?['question'],
          'last_is_poll': last?['poll_id'] != null,
          'last_at': last?['created_at'],
        };
      })(),
  ];

  DemoRow _publish(int id) {
    final session = row('sessions', id)!;
    requireLeader(session['team_id']);
    final items =
        rows('setlist_items').where((i) => i['session_id'] == id).toList()
          ..sort((a, b) => _compare(a['position'], b['position']));
    if (items.isEmpty) throw const DemoFailure('22023', 'The setlist is empty');
    final snapshot = [
      for (final i in items)
        {
          'song_id': i['song_id'],
          'title': row('songs', i['song_id'])?['title'],
          'version_id': i['version_id'],
          'version': row('song_versions', i['version_id'])?['name'],
          'key':
              i['key'] ?? row('song_versions', i['version_id'])?['default_key'],
          'bpm': i['bpm'] ?? row('song_versions', i['version_id'])?['bpm'],
        },
    ];
    final previous = rows('announcements')
        .where((a) => a['session_id'] == id)
        .firstOrNull;
    final old = (previous?['setlist_snapshot'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final diff = <String, dynamic>{};
    if (old.isNotEmpty) {
      diff['added'] = [
        for (final i in snapshot)
          if (!old.any((p) => p['song_id'] == i['song_id'])) i['title'],
      ];
      diff['removed'] = [
        for (final i in old)
          if (!snapshot.any((p) => p['song_id'] == i['song_id'])) i['title'],
      ];
      for (final (field, label) in [
        ('key', 'key_changed'),
        ('bpm', 'tempo_changed'),
        ('version_id', 'version_changed'),
      ]) {
        diff[label] = [
          for (final i in snapshot)
            for (final before in old.where((p) => p['song_id'] == i['song_id']))
              if (before[field] != i[field])
                {
                  'title': i['title'],
                  'from': field == 'version_id'
                      ? before['version']
                      : before[field],
                  'to': field == 'version_id' ? i['version'] : i[field],
                },
        ];
      }
      diff['reordered'] =
          jsonEncode(old.map((i) => i['song_id']).toList()) !=
          jsonEncode(snapshot.map((i) => i['song_id']).toList());
    }
    update('sessions', session, {
      'setlist_status': 'published',
      'published_at': session['published_at'] ?? timestamp,
    });
    final fields = <String, dynamic>{
      'team_id': session['team_id'],
      'kind': 'setlist',
      'session_id': id,
      'title': session['title'],
      'body': null,
      'setlist_snapshot': snapshot,
      'change_summary': diff,
      'pinned': false,
    };
    if (previous == null) {
      insert('announcements', fields);
    } else {
      update('announcements', previous, fields);
    }
    return diff;
  }

  static const _keys = <String, List<String>>{
    'profiles': ['id'],
    'team_members': ['team_id', 'user_id'],
    'member_parts': ['team_id', 'user_id', 'part_id'],
    'default_slots': ['team_id', 'part_id'],
    'session_slots': ['session_id', 'part_id'],
    'rehearsal_responses': ['rehearsal_id', 'user_id'],
    'channel_reads': ['user_id', 'channel_id'],
    'announcement_seen': ['user_id', 'team_id'],
    'poll_votes': ['poll_id', 'option_id', 'user_id'],
    'notification_prefs': ['user_id', 'category'],
    'calendar_feeds': ['user_id'],
    'device_tokens': ['token'],
  };
}
