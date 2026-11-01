import 'package:supabase_flutter/supabase_flutter.dart' hide Session;

import 'ink.dart';

class AnnotationsRepository {
  AnnotationsRepository(this._db);
  final SupabaseClient _db;

  static const _columns =
      'id, team_id, session_id, setlist_item_id, sheet_id, page_index, owner_id, visibility, tool, color, width, points, deleted_at';

  /// Every stroke of the session this user may see (RLS: team strokes and
  /// their own private ones), including erased ones so undo can restore.
  Future<List<InkStroke>> forSession(int sessionId) async {
    final rows = await _db.from('strokes').select(_columns).eq('session_id', sessionId);
    return rows.map(InkStroke.fromRow).toList();
  }

  /// Idempotent: the id is generated on the device, so a retried upload
  /// of the same stroke changes nothing.
  Future<void> save(InkStroke stroke) =>
      _db.from('strokes').upsert(stroke.toInsertRow(), onConflict: 'id', ignoreDuplicates: true);

  Future<void> setDeleted(String strokeId, DateTime? at) => _db
      .from('strokes')
      .update({'deleted_at': at?.toUtc().toIso8601String()})
      .eq('id', strokeId);

  Future<int> copyPrevious(int itemId) async =>
      await _db.rpc('copy_previous_strokes', params: {'p_item_id': itemId}) as int;

  /// Live inserts and updates (erase/undo) for the session. Realtime applies
  /// the table's RLS, so private strokes of others never arrive here.
  RealtimeChannel watch(int sessionId, void Function(InkStroke) onStroke) => _db
      .channel('strokes:$sessionId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'strokes',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'session_id', value: sessionId),
        callback: (payload) {
          final row = payload.newRecord;
          if (row.isNotEmpty && row['points'] != null) onStroke(InkStroke.fromRow(row));
        },
      )
      .subscribe();
}
