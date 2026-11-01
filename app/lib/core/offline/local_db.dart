import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'local_db.g.dart';

/// Server rows kept for reading offline: the latest answer to one query,
/// per signed-in user.
class Snapshots extends Table {
  TextColumn get owner => text()();
  TextColumn get key => text()();
  TextColumn get json => text()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {owner, key};
}

/// Sheet PDFs by storage path. Every upload gets a new path, so a stored
/// file never goes out of date.
@DataClassName('StoredFile')
class StoredFiles extends Table {
  TextColumn get path => text()();
  BlobColumn get bytes => blob()();
  IntColumn get size => integer()();
  DateTimeColumn get usedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {path};
}

/// Changes made on this device that the server has not confirmed yet,
/// sent oldest first.
@DataClassName('OutboxOp')
class Outbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get owner => text()();
  IntColumn get sessionId => integer()();
  TextColumn get kind => text()();
  TextColumn get payload => text()();
}

/// SQLite on Android and iOS, SQLite compiled to WebAssembly on the web
/// (`web/sqlite3.wasm` and `web/drift_worker.js`, matching the drift and
/// sqlite3 package versions).
@DriftDatabase(tables: [Snapshots, StoredFiles, Outbox])
class LocalDb extends _$LocalDb {
  LocalDb([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'praiseteam',
              web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
            ),
      );

  @override
  int get schemaVersion => 1;
}
