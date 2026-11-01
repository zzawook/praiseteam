import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:praiseteam/core/offline/local_db.dart';
import 'package:praiseteam/core/offline/offline_store.dart';
import 'package:praiseteam/core/offline/reachability.dart';
import 'package:praiseteam/features/annotations/ink.dart';
import 'package:praiseteam/features/annotations/stroke_outbox.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

void main() {
  late LocalDb db;
  late OfflineStore store;
  late Reachability reachability;
  ReadThrough reader(String? owner) => ReadThrough(store, reachability, owner);

  setUp(() {
    db = LocalDb(NativeDatabase.memory());
    store = OfflineStore(db);
    reachability = Reachability(probeEvery: const Duration(hours: 1));
  });
  tearDown(() async {
    reachability.dispose();
    await db.close();
  });

  final rowsA = [
    {'id': 1, 'title': 'A'},
  ];
  final rowsB = [
    {'id': 1, 'title': 'B'},
  ];

  group('rows', () {
    test('online: the server answers and its answer is kept', () async {
      expect(await reader('u1').list('k', () async => rowsA), rowsA);
      expect(await store.snapshot('u1', 'k'), rowsA);
      expect(await reader('u1').list('k', () async => rowsB), rowsB, reason: 'the server wins while online');
    });

    test('no connection: the kept copy answers', () async {
      await reader('u1').list('k', () async => rowsA);
      final result = await reader('u1').list('k', () => Future.error(http.ClientException('offline')));
      expect(result, rowsA);
    });

    test('known to be offline: the kept copy answers without asking the server', () async {
      await reader('u1').list('k', () async => rowsA);
      reachability.reportFailure();
      var asked = false;
      final result = await reader('u1').list('k', () async {
        asked = true;
        return rowsB;
      });
      expect(result, rowsA);
      expect(asked, isFalse);
    });

    test('the server stops answering mid-request: the kept copy answers at once', () async {
      await reader('u1').list('k', () async => rowsA);
      final never = Completer<List<Map<String, dynamic>>>();
      final pending = reader('u1').list('k', () => never.future);
      reachability.reportFailure(); // another request found the server gone
      expect(await pending, rowsA);
    });

    test('errors the server sent are not hidden behind the kept copy', () async {
      await reader('u1').list('k', () async => rowsA);
      expect(
        reader('u1').list('k', () => Future.error(const PostgrestException(message: 'denied', code: '42501'))),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('nothing kept and no connection: the connection error is the answer', () async {
      expect(
        reader('u1').list('k', () => Future.error(http.ClientException('offline'))),
        throwsA(isA<http.ClientException>()),
      );
    });

    test("one user's kept answers are not another's", () async {
      await reader('u1').list('k', () async => rowsA);
      reachability.reportFailure();
      expect(
        reader('u2').list('k', () => Future.error(http.ClientException('offline'))),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('signed out: nothing is kept', () async {
      await reader(null).list('k', () async => rowsA);
      expect(await store.snapshot('u1', 'k'), isNull);
    });
  });

  test('files: a kept file is used without asking the server', () async {
    final pdf = Uint8List.fromList([1, 2, 3]);
    expect(await reader('u1').file('t/1.pdf', () async => pdf), pdf);
    var asked = false;
    final again = await reader('u1').file('t/1.pdf', () async {
      asked = true;
      return Uint8List(0);
    });
    expect(again, pdf);
    expect(asked, isFalse);
  });

  test('reachability: back online counts as a new epoch', () async {
    expect(reachability.online, isTrue);
    final went = reachability.wentOffline;
    reachability.reportFailure();
    await went;
    expect(reachability.online, isFalse);
    reachability.reportResponse();
    expect((reachability.online, reachability.epoch), (true, 1));
  });

  test('clear forgets everything', () async {
    await reader('u1').list('k', () async => rowsA);
    await store.enqueue('u1', 7, 'erase', {'id': 'x', 'deleted_at': null});
    await store.clear();
    expect(await store.snapshot('u1', 'k'), isNull);
    expect(await store.pending('u1'), isEmpty);
  });

  group('note changes', () {
    InkStroke stroke(String id, {DateTime? deletedAt}) => InkStroke(
      id: id,
      teamId: 1,
      sessionId: 7,
      itemId: 3,
      sheetId: 4,
      pageIndex: 0,
      ownerId: 'u1',
      visibility: InkVisibility.private,
      tool: InkTool.pen,
      color: 0xFF2541B2,
      width: 2,
      points: const [(x: 0.1, y: 0.2, p: 0.5), (x: 0.3, y: 0.4, p: 0.5)],
      deletedAt: deletedAt,
    );

    test('survive the outbox format', () {
      final save = SaveStroke(stroke('s1'));
      final back = StrokeOp.decode(7, save.kind, jsonOf(save))! as SaveStroke;
      expect(back.stroke.toRow(), save.stroke.toRow());
      final at = DateTime.utc(2026, 11, 8, 10);
      final erase = StrokeOp.decode(7, 'erase', jsonOf(EraseStroke(7, 's1', at)))! as EraseStroke;
      expect((erase.strokeId, erase.at), ('s1', at));
    });

    test('apply on top of the server copy in order, as the server will', () {
      final shown = <String, InkStroke>{};
      final at = DateTime.utc(2026, 11, 8, 10);
      for (final op in [SaveStroke(stroke('s1')), EraseStroke(7, 's1', at), SaveStroke(stroke('s2'))]) {
        op.applyTo(shown);
      }
      expect(shown.keys, ['s1', 's2']);
      expect(shown['s1']!.deletedAt, at);

      // The server already has s3, erased by a leader: its copy wins.
      final server = {'s3': stroke('s3', deletedAt: at)};
      SaveStroke(stroke('s3')).applyTo(server);
      expect(server['s3']!.isDeleted, isTrue);
    });

    test('only refusals that can never succeed are dropped', () {
      expect(refusedForGood(const PostgrestException(message: 'rls', code: '42501')), isTrue);
      expect(refusedForGood(const PostgrestException(message: 'gone', code: '23503')), isTrue);
      expect(refusedForGood(const PostgrestException(message: 'jwt expired', code: 'PGRST301')), isFalse);
      expect(refusedForGood(const PostgrestException(message: 'busy', code: '503')), isFalse);
      expect(refusedForGood(const PostgrestException(message: 'slow down', code: '429')), isFalse);
      expect(refusedForGood(http.ClientException('offline')), isFalse);
      expect(refusedForGood(TimeoutException('slow')), isFalse);
    });
  });
}

String jsonOf(StrokeOp op) => jsonEncode(op.toJson());
