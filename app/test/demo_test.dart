import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:praiseteam/core/offline/local_db.dart';
import 'package:praiseteam/core/offline/offline_store.dart';
import 'package:praiseteam/core/offline/reachability.dart';
import 'package:praiseteam/core/team_time.dart';
import 'package:praiseteam/demo/demo_client.dart';
import 'package:praiseteam/demo/demo_seed.dart';
import 'package:praiseteam/demo/demo_store.dart';
import 'package:praiseteam/features/chat/chat_repository.dart';
import 'package:praiseteam/features/sessions/sessions_repository.dart';
import 'package:praiseteam/features/rotation/rotation_repository.dart';
import 'package:praiseteam/features/songs/songs_repository.dart';
import 'package:praiseteam/features/teams/teams_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late DemoStore store;
  late DemoClient client;
  late LocalDb local;
  late OfflineStore offline;
  late Reachability reachability;
  late ReadThrough reader;

  setUp(() async {
    final reference = jsonDecode(File('assets/demo/reference.json').readAsStringSync()) as Map<String, dynamic>;
    store = DemoStore(seedDemo(reference));
    local = LocalDb(NativeDatabase.memory());
    offline = OfflineStore(local);
    reachability = Reachability();
    reader = ReadThrough(offline, reachability, demoUserId);
    client = DemoClient(store, offline);
    await client.start();
  });
  tearDown(() async {
    await client.dispose();
    await local.close();
    reachability.dispose();
  });

  test('the normal repositories load complete, prefilled demo data', () async {
    expect(client.auth.currentUser?.id, demoUserId);
    final teams = TeamsRepository(client, reader);
    final mine = await teams.myMemberships(demoUserId);
    expect(mine.single.team.name, '한빛 찬양팀');
    expect((await teams.members(1)).length, 10);
    final songs = SongsRepository(client, reader);
    expect((await songs.library(1)).length, 8);
    expect((await songs.detail(1)).song.versions.length, 2);
    final sessions = SessionsRepository(client, reader);
    expect(await sessions.upcoming(1, time: TeamTime('Asia/Singapore')), isNotEmpty);
    expect((await sessions.session(107)).songCount, 4);
    expect((await sessions.setlist(107)).first.version?.links, isNotEmpty);
    final from = DateTime.now();
    final board = await RotationRepository(client).board(1, from: from, to: from.add(const Duration(days: 56)));
    expect(board.sessions.every((s) => !s.startsAt.isBefore(from)), isTrue);
  });

  test('changing the prefilled setlist reports the change when announced again', () async {
    final sessions = SessionsRepository(client, reader);
    final first = (await sessions.setlist(107)).first;
    await sessions.updateItem(first.id, {'key': 'A'});
    expect((await sessions.publish(107)).keyChanged.single.to, 'A');
  });

  test('adding a song and publishing a service uses the real repository contracts', () async {
    final songs = SongsRepository(client, reader);
    final sessions = SessionsRepository(client, reader);
    final id = await songs.addSong(1, {'title': '데모에서 추가한 곡'}, {'name': '우리 팀', 'default_key': 'G', 'bpm': 72});
    final version = (await songs.versions(id)).single;
    final service = (await sessions.createSessions(1, [
      {'title': '새 예배', 'starts_at': DateTime.now().add(const Duration(days: 3)).toUtc().toIso8601String()},
    ])).single;
    await sessions.addItem(
      teamId: 1,
      sessionId: service,
      songId: id,
      versionId: version.id,
      position: 1,
      key: 'G',
      bpm: 72,
    );
    await sessions.publish(service);
    final item = (await sessions.setlist(service)).single;
    await sessions.updateItem(item.id, {'key': 'A'});
    final changes = await sessions.publish(service);
    expect(changes.keyChanged.single, (title: '데모에서 추가한 곡', from: 'G', to: 'A'));
  });

  test('chat updates are delivered locally and polls retain votes', () async {
    final repo = ChatRepository(client);
    expect(await repo.channels(1), isNotEmpty);
    final received = Completer<Map<String, dynamic>>();
    final channel = repo.watchTeam(1, (row) {
      if (row['body'] == '데모 메시지' && !received.isCompleted) received.complete(row);
    });
    await repo.send(id: repo.newMessageId(), teamId: 1, channelId: 1, body: '데모 메시지');
    expect((await received.future.timeout(const Duration(seconds: 2)))['sender_id'], demoUserId);
    await repo.vote(1, [2]);
    expect((await repo.poll(1)).options.where((o) => o.mine).single.id, 2);
    await channel.unsubscribe();
  });

  test('uploaded files stay in the local store', () async {
    final bytes = Uint8List.fromList(utf8.encode('%PDF-1.4 demo only'));
    await client.storage
        .from('sheets')
        .uploadBinary('1/local.pdf', bytes, fileOptions: const FileOptions(contentType: 'application/pdf'));
    expect(await client.storage.from('sheets').download('1/local.pdf'), bytes);
    expect(await offline.file('1/local.pdf'), bytes);
  });

  test('the adapter refuses requests to a real backend', () async {
    final transport = DemoHttpClient(store, offline);
    await expectLater(
      transport.get(Uri.parse('https://production.supabase.co/rest/v1/teams')),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('live preview has only the actual local participant', () async {
    final channel = client.channel('live:107');
    final ready = Completer<void>();
    channel.subscribe((status, _) {
      if (status == RealtimeSubscribeStatus.subscribed) ready.complete();
    });
    await ready.future;
    await channel.track({'name': '데모'});
    expect(channel.presenceState().length, 1);
    await client.removeChannel(channel);
    expect(client.getChannels(), isEmpty);
  });
}
