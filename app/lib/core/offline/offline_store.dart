import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'local_db.dart';
import 'reachability.dart';

/// The device's copy of what the app needs without a connection.
///
/// It is a convenience, not a source of truth: if the local database
/// cannot be opened or written (a browser that blocks storage, a full
/// disk), reads and writes here quietly do nothing and the app keeps
/// working online.
class OfflineStore {
  OfflineStore(this._db);
  final LocalDb _db;

  /// Keep at most this much PDF data; the least recently opened go first.
  static const maxFileBytes = 300 * 1024 * 1024;

  Future<T?> _guard<T>(String what, Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      debugPrint('offline store: $what failed: $e');
      return null;
    }
  }

  // ---- query answers

  Future<Object?> snapshot(String owner, String key) => _guard<Object?>('read $key', () async {
    final row = await (_db.select(
      _db.snapshots,
    )..where((s) => s.owner.equals(owner) & s.key.equals(key))).getSingleOrNull();
    return row == null ? null : jsonDecode(row.json);
  });

  Future<void> saveSnapshot(String owner, String key, Object? value) => _guard(
    'save $key',
    () => _db
        .into(_db.snapshots)
        .insertOnConflictUpdate(
          SnapshotsCompanion.insert(owner: owner, key: key, json: jsonEncode(value), savedAt: DateTime.now()),
        ),
  );

  // ---- files

  Future<Uint8List?> file(String path) => _guard<Uint8List?>('read $path', () async {
    final row = await (_db.select(_db.storedFiles)..where((f) => f.path.equals(path))).getSingleOrNull();
    if (row == null) return null;
    await (_db.update(
      _db.storedFiles,
    )..where((f) => f.path.equals(path))).write(StoredFilesCompanion(usedAt: Value(DateTime.now())));
    return row.bytes;
  });

  Future<void> saveFile(String path, Uint8List bytes) => _guard('save $path', () async {
    await _db
        .into(_db.storedFiles)
        .insertOnConflictUpdate(
          StoredFilesCompanion.insert(path: path, bytes: bytes, size: bytes.length, usedAt: DateTime.now()),
        );
    await _trimFiles();
  });

  Future<void> _trimFiles() async {
    final rows =
        await (_db.selectOnly(_db.storedFiles)
              ..addColumns([_db.storedFiles.path, _db.storedFiles.size])
              ..orderBy([OrderingTerm.desc(_db.storedFiles.usedAt)]))
            .get();
    var total = 0;
    final drop = <String>[];
    for (final r in rows) {
      total += r.read(_db.storedFiles.size)!;
      if (total > maxFileBytes) drop.add(r.read(_db.storedFiles.path)!);
    }
    if (drop.isNotEmpty) await (_db.delete(_db.storedFiles)..where((f) => f.path.isIn(drop))).go();
  }

  // ---- changes waiting for the server

  /// Returns the change's place in line. Not guarded: the caller decides
  /// what to do when a change cannot be kept.
  Future<int> enqueue(String owner, int sessionId, String kind, Map<String, Object?> payload) => _db
      .into(_db.outbox)
      .insert(OutboxCompanion.insert(owner: owner, sessionId: sessionId, kind: kind, payload: jsonEncode(payload)));

  Future<List<OutboxOp>> pending(String owner, {int? sessionId}) async =>
      await _guard('read outbox', () {
        final query = _db.select(_db.outbox)
          ..where(
            (o) => o.owner.equals(owner) & (sessionId == null ? const Constant(true) : o.sessionId.equals(sessionId)),
          )
          ..orderBy([(o) => OrderingTerm.asc(o.seq)]);
        return query.get();
      }) ??
      const [];

  Stream<int> pendingCount(String owner) {
    final count = _db.outbox.seq.count();
    final query = _db.selectOnly(_db.outbox)
      ..addColumns([count])
      ..where(_db.outbox.owner.equals(owner));
    return query.map((r) => r.read(count) ?? 0).watchSingle().handleError((Object e) => debugPrint('$e'));
  }

  Future<void> done(int seq) =>
      _guard('outbox done', () => (_db.delete(_db.outbox)..where((o) => o.seq.equals(seq))).go());

  /// Everything, for every user: on sign-out, so the next person to use a
  /// shared tablet finds nothing of the previous one.
  Future<void> clear() => _guard('clear', () async {
    await _db.transaction(() async {
      await _db.delete(_db.snapshots).go();
      await _db.delete(_db.storedFiles).go();
      await _db.delete(_db.outbox).go();
    });
  });
}

/// Reads that keep working without a connection.
///
/// Rows: the server is asked first and its answer is saved. When the
/// server cannot be reached, or is already known to be unreachable, the
/// saved answer is used instead, at once. Files never change at a given
/// path, so a saved file is used without asking the server at all.
class ReadThrough {
  ReadThrough(this._store, this._reachability, this._owner);
  final OfflineStore _store;
  final Reachability _reachability;
  final String? _owner;

  Future<List<Map<String, dynamic>>> list(String key, Future<List<Map<String, dynamic>>> Function() fetch) async {
    final value = await _read(key, fetch);
    return [for (final row in value as List) Map<String, dynamic>.from(row as Map)];
  }

  Future<Map<String, dynamic>> single(String key, Future<Map<String, dynamic>> Function() fetch) async =>
      Map<String, dynamic>.from(await _read(key, fetch) as Map);

  Future<Object?> _read(String key, Future<Object?> Function() fetch) async {
    final owner = _owner;
    if (owner == null) return fetch();
    if (!_reachability.online) {
      final saved = await _store.snapshot(owner, key);
      if (saved != null) return saved;
    }

    final request = fetch();
    // Save the answer whenever it comes, even if the screen has moved on
    // to the saved copy by then.
    request.then((fresh) => _store.saveSnapshot(owner, key, fresh)).ignore();

    final Object? outcome = await Future.any<Object?>([
      request.then((value) => _Fresh(value)),
      _reachability.wentOffline.then((_) => const _Unreachable()),
    ]).catchError((Object e) => isOfflineError(e) ? const _Unreachable() : throw e);
    if (outcome is _Fresh) return outcome.value;

    final saved = await _store.snapshot(owner, key);
    // Nothing saved: the request's own answer or error is all there is.
    return saved ?? await request;
  }

  Future<Uint8List> file(String path, Future<Uint8List> Function() fetch) async {
    final saved = await _store.file(path);
    if (saved != null) return saved;
    final bytes = await fetch();
    await _store.saveFile(path, bytes);
    return bytes;
  }
}

class _Fresh {
  const _Fresh(this.value);
  final Object? value;
}

class _Unreachable {
  const _Unreachable();
}
