import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/offline/offline_store.dart';
import 'models.dart';

class SongsRepository {
  SongsRepository(this._db, this._offline);
  final SupabaseClient _db;
  final ReadThrough _offline;

  static const _songColumns = 'id, team_id, title, time_signature, tags, notes';
  static const _versionColumns = 'id, song_id, name, default_key, bpm, created_by';
  static const _sheetColumns =
      'id, version_id, key, label, storage_path, page_count, page_sizes, size_bytes, uploaded_by, created_at';
  static const _linkColumns = 'id, version_id, label, url, sort_order';

  /// The team's songs with their versions, and their statistics.
  Future<List<SongEntry>> library(int teamId) async {
    final (songs, stats) = await (
      _db
          .from('songs')
          .select('$_songColumns, song_versions($_versionColumns, song_links($_linkColumns))')
          .eq('team_id', teamId)
          .isFilter('archived_at', null)
          .order('title', ascending: true)
          .order('id', referencedTable: 'song_versions', ascending: true)
          .order('sort_order', referencedTable: 'song_versions.song_links', ascending: true),
      _db.from('song_stats').select().eq('team_id', teamId),
    ).wait;
    final byId = {for (final row in stats) row['song_id'] as int: SongStats.fromJson(row)};
    return [
      for (final row in songs) SongEntry(Song.fromJson(row), byId[row['id']] ?? SongStats(songId: row['id'] as int)),
    ];
  }

  /// A song with each version's sheets and links, its statistics and the
  /// services it was played in.
  Future<SongDetail> detail(int songId) async {
    final (song, stats, history) = await (
      _db
          .from('songs')
          .select('$_songColumns, song_versions($_versionColumns, sheets($_sheetColumns), song_links($_linkColumns))')
          .eq('id', songId)
          .order('id', referencedTable: 'song_versions', ascending: true)
          .order('created_at', referencedTable: 'song_versions.sheets', ascending: true)
          .order('sort_order', referencedTable: 'song_versions.song_links', ascending: true)
          .single(),
      _db.from('song_stats').select().eq('song_id', songId).maybeSingle(),
      _db
          .from('song_history')
          .select('session_id, session_title, starts_at, key, bpm, version_id, version_name')
          .eq('song_id', songId)
          .order('starts_at', ascending: false)
          .limit(50),
    ).wait;
    return SongDetail(
      song: Song.fromJson(song),
      stats: stats == null ? SongStats(songId: songId) : SongStats.fromJson(stats),
      history: history.map(SongHistoryEntry.fromJson).toList(),
    );
  }

  /// A song's versions with their sheets, oldest first.
  Future<List<SongVersion>> versions(int songId) async {
    final rows = await _db
        .from('song_versions')
        .select('$_versionColumns, sheets($_sheetColumns)')
        .eq('song_id', songId)
        .order('id', ascending: true)
        .order('created_at', referencedTable: 'sheets', ascending: true);
    return rows.map(SongVersion.fromJson).toList();
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

  /// A song with its first version, in one step. [song]: title,
  /// time_signature, tags, notes; [version]: name, default_key, bpm.
  Future<int> addSong(int teamId, Map<String, Object?> song, Map<String, Object?> version) async => await _db.rpc(
    'add_song',
    params: {
      'p_team_id': teamId,
      'p_title': song['title'],
      'p_time_signature': song['time_signature'],
      'p_tags': song['tags'] ?? const <String>[],
      'p_notes': song['notes'],
      'p_version_name': version['name'],
      'p_key': version['default_key'],
      'p_bpm': version['bpm'],
    },
  ) as int;

  Future<void> updateSong(int songId, Map<String, Object?> fields) => _db.from('songs').update(fields).eq('id', songId);

  /// Deletes the song with its versions, then their sheet files.
  Future<void> deleteSong(Song song) async {
    await _db.from('songs').delete().eq('id', song.id);
    await _removeFiles([for (final v in song.versions) ...v.sheets]);
  }

  /// [fields]: name, default_key, bpm.
  Future<int> addVersion(int teamId, int songId, Map<String, Object?> fields) async {
    final row = await _db
        .from('song_versions')
        .insert({'team_id': teamId, 'song_id': songId, ...fields})
        .select('id')
        .single();
    return row['id'] as int;
  }

  Future<void> updateVersion(int versionId, Map<String, Object?> fields) =>
      _db.from('song_versions').update(fields).eq('id', versionId);

  /// Deletes the version with its sheets and links, then the sheet files.
  /// A version some setlist plays is refused (23503).
  Future<void> deleteVersion(SongVersion version) async {
    await _db.from('song_versions').delete().eq('id', version.id);
    await _removeFiles(version.sheets);
  }

  Future<void> addLink(int teamId, int versionId, {required String url, String? label, int sortOrder = 0}) =>
      _db.from('song_links').insert({
        'team_id': teamId,
        'version_id': versionId,
        'url': url.trim(),
        'label': ?(label == null || label.trim().isEmpty ? null : label.trim()),
        'sort_order': sortOrder,
      });

  Future<void> deleteLink(int linkId) => _db.from('song_links').delete().eq('id', linkId);

  /// Stores the PDF, then records it. If recording fails the file is removed
  /// again so storage never holds sheets nobody can see.
  Future<void> uploadSheet({
    required int teamId,
    required int versionId,
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
        'version_id': versionId,
        'key': ?key,
        'label': ?(label == null || label.trim().isEmpty ? null : label.trim()),
        'storage_path': path,
        'page_count': pageSizes.length,
        'page_sizes': [
          for (final s in pageSizes) [s.width, s.height],
        ],
        'size_bytes': pdf.length,
      });
    } catch (_) {
      await bucket.remove([path]);
      rethrow;
    }
  }

  Future<void> deleteSheet(Sheet sheet) async {
    await _db.from('sheets').delete().eq('id', sheet.id);
    await _removeFiles([sheet]);
  }

  /// After the rows are gone: a file left behind is only wasted space,
  /// while a row without its file would be a broken sheet.
  Future<void> _removeFiles(List<Sheet> sheets) async {
    if (sheets.isEmpty) return;
    await _db.storage.from('sheets').remove([for (final s in sheets) s.storagePath]);
  }

  /// A sheet's PDF. Kept on the device; a path never changes content, so a
  /// kept copy is used without asking the server.
  Future<Uint8List> downloadSheet(String storagePath) =>
      _offline.file(storagePath, () => _db.storage.from('sheets').download(storagePath));

  Future<List<TopSong>> topSongs(int teamId, DateTime from, DateTime to) async {
    final rows = await _db.rpc(
      'top_songs',
      params: {'p_team_id': teamId, 'p_from': from.toUtc().toIso8601String(), 'p_to': to.toUtc().toIso8601String()},
    ) as List<dynamic>;
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        TopSong(r['song_id'] as int, r['title'] as String, r['times'] as int),
    ];
  }
}
