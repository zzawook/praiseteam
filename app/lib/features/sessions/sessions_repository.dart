// supabase_flutter's auth Session is not the worship session model here.
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;

import '../../core/offline/offline_store.dart';
import 'models.dart';

/// Sessions and setlists. The reads the music stand needs are kept on the
/// device ([ReadThrough]) so they work without a connection.
class SessionsRepository {
  SessionsRepository(this._db, this._offline);
  final SupabaseClient _db;
  final ReadThrough _offline;

  static const _sessionColumns =
      'id, team_id, title, starts_at, location, theme, notes, setlist_status, published_at, setlist_items(count)';
  static const _itemColumns =
      'id, session_id, position, song_id, key, bpm, sheet_id, song_form, notes, songs(title, artist, default_key, bpm)';

  /// A session stays "upcoming" for the rest of its day.
  static DateTime get _upcomingCutoff => DateTime.now().subtract(const Duration(hours: 12)).toUtc();

  Future<List<Session>> upcoming(int teamId) async {
    final rows = await _offline.list(
      'sessions:upcoming:$teamId',
      () => _db
          .from('sessions')
          .select(_sessionColumns)
          .eq('team_id', teamId)
          .gte('starts_at', _upcomingCutoff.toIso8601String())
          .order('starts_at', ascending: true)
          .limit(100),
    );
    return rows.map(Session.fromJson).toList();
  }

  Future<List<Session>> past(int teamId) async {
    final rows = await _db
        .from('sessions')
        .select(_sessionColumns)
        .eq('team_id', teamId)
        .lt('starts_at', _upcomingCutoff.toIso8601String())
        .order('starts_at', ascending: false)
        .limit(50);
    return rows.map(Session.fromJson).toList();
  }

  Future<Session> session(int sessionId) async => Session.fromJson(await _offline.single(
        'session:$sessionId',
        () => _db.from('sessions').select(_sessionColumns).eq('id', sessionId).single(),
      ));

  Future<List<SetlistItem>> setlist(int sessionId) async {
    final rows = await _offline.list(
      'setlist:$sessionId',
      () => _db.from('setlist_items').select(_itemColumns).eq('session_id', sessionId).order('position', ascending: true),
    );
    return rows.map(SetlistItem.fromJson).toList();
  }

  /// Inserts one or more sessions (the weekly repeat creates several).
  Future<List<int>> createSessions(int teamId, List<Map<String, Object?>> sessions) async {
    final rows = await _db
        .from('sessions')
        .insert([for (final s in sessions) {'team_id': teamId, ...s}])
        .select('id');
    return [for (final r in rows) r['id'] as int];
  }

  Future<void> updateSession(int sessionId, Map<String, Object?> fields) =>
      _db.from('sessions').update(fields).eq('id', sessionId);

  Future<void> deleteSession(int sessionId) => _db.from('sessions').delete().eq('id', sessionId);

  Future<void> addItem({
    required int teamId,
    required int sessionId,
    required int songId,
    required int position,
    String? key,
    int? bpm,
    int? sheetId,
  }) =>
      _db.from('setlist_items').insert({
        'team_id': teamId,
        'session_id': sessionId,
        'song_id': songId,
        'position': position,
        'key': ?key,
        'bpm': ?bpm,
        'sheet_id': ?sheetId,
      });

  Future<void> updateItem(int itemId, Map<String, Object?> fields) =>
      _db.from('setlist_items').update(fields).eq('id', itemId);

  Future<void> deleteItem(int itemId) => _db.from('setlist_items').delete().eq('id', itemId);

  Future<void> reorder(int sessionId, List<int> itemIds) =>
      _db.rpc('reorder_setlist', params: {'p_session_id': sessionId, 'p_item_ids': itemIds});

  /// The team's weekly services, Sunday first.
  Future<List<SessionTemplate>> templates(int teamId) async {
    final rows = await _db
        .from('session_templates')
        .select('id, team_id, title, weekday, start_time, location')
        .eq('team_id', teamId);
    return rows.map(SessionTemplate.fromJson).toList()..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  }

  /// [fields]: title, weekday, start_time ('HH:MM'), location.
  Future<void> createTemplate(int teamId, Map<String, Object?> fields) =>
      _db.from('session_templates').insert({'team_id': teamId, ...fields});

  Future<void> updateTemplate(int templateId, Map<String, Object?> fields) =>
      _db.from('session_templates').update(fields).eq('id', templateId);

  Future<void> deleteTemplate(int templateId) => _db.from('session_templates').delete().eq('id', templateId);

  Future<SetlistChanges> publish(int sessionId) async {
    final result = await _db.rpc('publish_setlist', params: {'p_session_id': sessionId});
    return SetlistChanges.fromJson((result as Map?)?.cast<String, dynamic>());
  }
}
