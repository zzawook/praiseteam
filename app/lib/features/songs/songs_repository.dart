import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/offline/offline_store.dart';
import 'models.dart';

class SongsRepository {
  SongsRepository(this._db, this._offline);
  final SupabaseClient _db;
  final ReadThrough _offline;

  static const _songColumns = 'id, team_id, title, artist, default_key, bpm, time_signature, tags, notes';
  static const _sheetColumns =
      'id, song_id, key, label, storage_path, page_count, page_sizes, size_bytes, uploaded_by, created_at';

  Future<List<SongEntry>> library(int teamId) async {
    final (songs, stats) = await (
      _db
          .from('songs')
          .select(_songColumns)
          .eq('team_id', teamId)
          .isFilter('archived_at', null)
          .order('title', ascending: true),
      _db.from('song_stats').select().eq('team_id', teamId),
    ).wait;
    final byId = {for (final row in stats) row['song_id'] as int: SongStats.fromJson(row)};
    return [
      for (final row in songs)
        SongEntry(Song.fromJson(row), byId[row['id']] ?? SongStats(songId: row['id'] as int)),
    ];
  }

  Future<SongDetail> detail(int songId) async {
    final (song, stats, links, sheets, history) = await (
      _db.from('songs').select(_songColumns).eq('id', songId).single(),
      _db.from('song_stats').select().eq('song_id', songId).maybeSingle(),
      _db.from('song_links').select('id, song_id, label, url, sort_order').eq('song_id', songId).order('sort_order', ascending: true),
      _db.from('sheets').select(_sheetColumns).eq('song_id', songId).order('created_at', ascending: true),
      _db
          .from('song_history')
          .select('session_id, session_title, starts_at, key')
          .eq('song_id', songId)
          .order('starts_at', ascending: false)
          .limit(50),
    ).wait;
    return SongDetail(
      song: Song.fromJson(song),
      stats: stats == null ? SongStats(songId: songId) : SongStats.fromJson(stats),
      links: links.map(SongLink.fromJson).toList(),
      sheets: sheets.map(Sheet.fromJson).toList(),
      history: history.map(SongHistoryEntry.fromJson).toList(),
    );
  }

  Future<Sheet> sheet(int sheetId) async =>
      Sheet.fromJson(await _db.from('sheets').select(_sheetColumns).eq('id', sheetId).single());

  /// The sheets a setlist uses; kept on the device for the music stand.
  Future<List<Sheet>> sheetsByIds(Iterable<int> ids) async {
    final unique = ids.toSet().toList()..sort();
    if (unique.isEmpty) return const [];
    final rows = await _offline.list(
      'sheets:${unique.join(',')}',
      () => _db.from('sheets').select(_sheetColumns).inFilter('id', unique),
    );
    return rows.map(Sheet.fromJson).toList();
  }

  Future<List<Sheet>> sheetsFor(int songId) async {
    final rows = await _db.from('sheets').select(_sheetColumns).eq('song_id', songId).order('created_at', ascending: true);
    return rows.map(Sheet.fromJson).toList();
  }

  Future<int> addSong(int teamId, Map<String, Object?> fields) async {
    final row = await _db.from('songs').insert({'team_id': teamId, ...fields}).select('id').single();
    return row['id'] as int;
  }

  Future<void> updateSong(int songId, Map<String, Object?> fields) =>
      _db.from('songs').update(fields).eq('id', songId);

  Future<void> deleteSong(int songId) => _db.from('songs').delete().eq('id', songId);

  Future<void> addLink(int teamId, int songId, {required String url, String? label, int sortOrder = 0}) =>
      _db.from('song_links').insert({
        'team_id': teamId,
        'song_id': songId,
        'url': url.trim(),
        'label': ?(label == null || label.trim().isEmpty ? null : label.trim()),
        'sort_order': sortOrder,
      });

  Future<void> deleteLink(int linkId) => _db.from('song_links').delete().eq('id', linkId);

  /// Stores the PDF, then records it. If recording fails the file is removed
  /// again so storage never holds sheets nobody can see.
  Future<void> uploadSheet({
    required int teamId,
    required int songId,
    required Uint8List pdf,
    required List<PageSize> pageSizes,
    String? key,
    String? label,
  }) async {
    final path = '$teamId/${const Uuid().v4()}.pdf';
    final bucket = _db.storage.from('sheets');
    await bucket.uploadBinary(path, pdf, fileOptions: const FileOptions(contentType: 'application/pdf'));
    try {
      await _db.from('sheets').insert({
        'team_id': teamId,
        'song_id': songId,
        'key': ?key,
        'label': ?(label == null || label.trim().isEmpty ? null : label.trim()),
        'storage_path': path,
        'page_count': pageSizes.length,
        'page_sizes': [for (final s in pageSizes) [s.width, s.height]],
        'size_bytes': pdf.length,
      });
    } catch (_) {
      await bucket.remove([path]);
      rethrow;
    }
  }

  Future<void> deleteSheet(Sheet sheet) async {
    await _db.from('sheets').delete().eq('id', sheet.id);
    await _db.storage.from('sheets').remove([sheet.storagePath]);
  }

  /// A sheet's PDF. Kept on the device; a path never changes content, so a
  /// kept copy is used without asking the server.
  Future<Uint8List> downloadSheet(String storagePath) =>
      _offline.file(storagePath, () => _db.storage.from('sheets').download(storagePath));

  Future<List<TopSong>> topSongs(int teamId, DateTime from, DateTime to) async {
    final rows = await _db.rpc('top_songs', params: {
      'p_team_id': teamId,
      'p_from': from.toUtc().toIso8601String(),
      'p_to': to.toUtc().toIso8601String(),
    }) as List<dynamic>;
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        TopSong(r['song_id'] as int, r['title'] as String, r['times'] as int),
    ];
  }
}
