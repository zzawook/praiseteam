import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:praiseteam/features/live/live_clock.dart';
import 'package:praiseteam/features/live/live_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

StandPosition at(int page) => StandPosition(itemId: 42, pageIndex: page);

/// In-memory wire with independently controllable delivery, ACKs and status.
/// Tests exercise LiveSession itself, including real reconnect/bootstrap timers.
class Wire {
  final peers = <Peer>[];
  final channels = <WireChannel>[];
  final messages = <({String event, Map<String, dynamic> payload, WireChannel from})>[];
  final acknowledgements = <Completer<ChannelResponse>>[];
  bool holdTurnAcks = false, dropTurns = false;
  int trackCalls = 0;

  Peer peer(String id, {String user = 'same-user'}) {
    final p = Peer(this, id, user);
    peers.add(p);
    p.live.join();
    return p;
  }

  void sync() {
    for (final channel in channels.where((c) => c.active)) {
      channel.presenceCallback?.call(const RealtimePresenceSyncPayload(event: PresenceEvent.sync));
    }
  }

  void deliver(WireChannel from, String event, Map<String, dynamic> payload) {
    for (final channel in channels.where((c) => c.active && c != from)) {
      channel.broadcasts[event]?.call({'payload': payload});
    }
  }

  Future<void> settle(WidgetTester tester, [int milliseconds = 2000]) async {
    for (var i = 0; i < milliseconds; i += 20) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> close(WidgetTester tester) async {
    for (final peer in peers) {
      await peer.live.leave();
      peer.live.dispose();
    }
    for (final ack in acknowledgements) {
      if (!ack.isCompleted) ack.complete(ChannelResponse.error);
    }
    await tester.pump(const Duration(seconds: 32));
    await Future.wait(peers.map((p) => p.db.dispose()));
  }
}

class Peer {
  Peer(Wire wire, String id, String user) : db = WireClient(wire) {
    live = LiveSession(db: db, sessionId: 1, me: user, name: id, myPartIds: {7}, clientId: id, onFollow: followed.add);
  }
  final WireClient db;
  late final LiveSession live;
  final followed = <StandPosition>[];
  WireChannel get channel => db.created.last;
}

class WireClient implements SupabaseClient {
  WireClient(this.wire);
  @override
  final RealtimeClient realtime = RealtimeClient('ws://localhost:54321/realtime/v1');
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
  @override
  Future<void> dispose() => realtime.disconnect();
  final Wire wire;
  final created = <WireChannel>[];

  @override
  RealtimeChannel channel(String name, {RealtimeChannelConfig opts = const RealtimeChannelConfig()}) {
    expectSync(opts.private, isTrue);
    expectSync(opts.ack, isTrue);
    final channel = WireChannel(name, realtime, wire, opts);
    created.add(channel);
    wire.channels.add(channel);
    return channel;
  }

  @override
  Future<String> removeChannel(RealtimeChannel channel) => channel.unsubscribe();
}

class WireChannel extends RealtimeChannel {
  WireChannel(super.topic, super.socket, this.wire, this.config) : super(params: config);
  final Wire wire;
  final RealtimeChannelConfig config;
  bool active = false;
  Map<String, dynamic>? tracked;
  final broadcasts = <String, void Function(Map<String, dynamic>)>{};
  void Function(RealtimePresenceSyncPayload)? presenceCallback;
  void Function(RealtimeSubscribeStatus, Object?)? statusCallback;

  @override
  bool get canPush => active;

  @override
  RealtimeChannel onBroadcast({required String event, required void Function(Map<String, dynamic>) callback}) {
    broadcasts[event] = callback;
    return this;
  }

  @override
  RealtimeChannel onPresenceSync(void Function(RealtimePresenceSyncPayload) callback) {
    presenceCallback = callback;
    return this;
  }

  @override
  RealtimeChannel subscribe([void Function(RealtimeSubscribeStatus, Object?)? callback, Duration? timeout]) {
    statusCallback = callback;
    reconnect();
    return this;
  }

  void reconnect() {
    active = true;
    scheduleMicrotask(() {
      statusCallback?.call(RealtimeSubscribeStatus.subscribed, null);
      wire.sync();
    });
  }

  void fail(RealtimeSubscribeStatus status, [String? error]) {
    active = false;
    tracked = null;
    statusCallback?.call(status, error);
    wire.sync();
  }

  @override
  List<SinglePresenceState> presenceState() => [
    for (final c in wire.channels.where((c) => c.active && c.tracked != null))
      SinglePresenceState(
        key: c.config.key,
        presences: [Presence(presenceRef: c.config.key, payload: c.tracked!)],
      ),
  ];

  @override
  Future<ChannelResponse> track(Map<String, dynamic> payload, [Map<String, dynamic> opts = const {}]) async {
    expectSync(payload.containsKey('turn'), isFalse, reason: 'page state never belongs in Presence');
    tracked = Map.of(payload);
    wire.trackCalls++;
    wire.sync();
    return ChannelResponse.ok;
  }

  @override
  Future<ChannelResponse> sendBroadcastMessage({required String event, required Map<String, dynamic> payload}) async {
    expectSync(active, isTrue, reason: 'no REST fallback through a disconnected channel');
    wire.messages.add((event: event, payload: Map.of(payload), from: this));
    if (event != 'turn' || !wire.dropTurns) wire.deliver(this, event, payload);
    if (event == 'turn' && wire.holdTurnAcks) {
      final ack = Completer<ChannelResponse>();
      wire.acknowledgements.add(ack);
      return ack.future;
    }
    return ChannelResponse.ok;
  }

  @override
  Future<String> unsubscribe([Duration? timeout]) async {
    active = false;
    tracked = null;
    wire.sync();
    return 'ok';
  }
}

void main() {
  late Wire wire;
  setUp(() => wire = Wire());
  void liveTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        await wire.close(tester);
      }
    });
  }

  liveTest('100 immediate turns, same user on two devices, only one track per join', (tester) async {
    final a = wire.peer('a'), b = wire.peer('b');
    await wire.settle(tester);
    expect([a.live.joined, b.live.joined], [true, true]);
    for (var i = 0; i < 100; i++) {
      final sending = a.live.turned(at(i));
      expect(wire.messages.last.event, 'turn', reason: 'first intent has no debounce/timer');
      await sending;
      await tester.pump(const Duration(milliseconds: 10));
      expect(b.live.clock.current!.position, at(i));
    }
    expect(wire.trackCalls, 2);
    expect(a.channel.tracked!['user'], b.channel.tracked!['user']);
    expect(a.channel.tracked!['client'], isNot(b.channel.tracked!['client']));
  });

  liveTest('while ACK is in flight only latest target survives, no 500ms wait', (tester) async {
    final a = wire.peer('a'), b = wire.peer('b');
    await wire.settle(tester);
    wire.holdTurnAcks = true;
    a.live.turned(at(1));
    for (var i = 2; i <= 100; i++) {
      a.live.turned(at(i));
    }
    expect(wire.messages.where((m) => m.event == 'turn').length, 1);
    expect(a.live.clock.current, isNull, reason: 'unacknowledged intent is not a shared snapshot');
    wire.acknowledgements.first.complete(ChannelResponse.ok);
    await tester.pump();
    final turns = wire.messages.where((m) => m.event == 'turn').toList();
    expect(turns.map((m) => m.payload['page']), [1, 100]);
    expect(b.live.clock.current!.position, at(100));
    wire.acknowledgements.last.complete(ChannelResponse.ok);
    await tester.pump();
    expect(a.live.clock.current!.position, at(100));
    expect(wire.trackCalls, 2);
  });

  liveTest('late join after the controller leaves recovers from another peer', (tester) async {
    final a = wire.peer('a'), b = wire.peer('b');
    await wire.settle(tester);
    await a.live.turned(at(9));
    await a.live.leave();
    final late = wire.peer('z');
    await wire.settle(tester);
    expect(late.live.joined, isTrue);
    expect(late.live.clock.current!.position, at(9));
    expect(late.followed.last, at(9));
    expect(b.live.clock.current!.position, at(9));
  });

  liveTest('30 simultaneous joiners coalesce snapshots and converge on concurrent turns', (tester) async {
    final peers = [for (var i = 0; i < 30; i++) wire.peer('peer-${i.toString().padLeft(2, '0')}')];
    await wire.settle(tester, 4000);
    expect(peers.every((p) => p.live.joined), isTrue);
    expect(wire.messages.where((m) => m.event == 'state_snapshot').length, lessThan(10));
    wire.holdTurnAcks = true;
    for (var i = 0; i < 30; i++) {
      peers[i].live.turned(at(i));
    }
    for (final ack in wire.acknowledgements) {
      ack.complete(ChannelResponse.ok);
    }
    await tester.pump();
    expect(peers.map((p) => p.live.clock.current!.position).toSet(), {at(29)});
    expect(wire.trackCalls, 30);
  });

  liveTest('terminal close reconnects, ignores offline browsing and old channel callbacks', (tester) async {
    final a = wire.peer('a'), b = wire.peer('b');
    await wire.settle(tester);
    await a.live.turned(at(1));
    final old = b.channel;
    old.fail(RealtimeSubscribeStatus.closed);
    expect(b.live.joined, isFalse);
    expect(b.live.state, LiveConnection.reconnecting);
    await b.live.turned(at(99));
    await a.live.turned(at(4));
    await wire.settle(tester, 4000);
    expect(b.live.joined, isTrue);
    expect(b.live.clock.current!.position, at(4));
    expect(b.db.created.length, 2);
    old.broadcasts['turn']!({
      'payload': {'item': 42, 'page': 99, 'seq': 999, 'by': 'stale'},
    });
    expect(b.live.clock.current!.position, at(4));
    expect(wire.messages.where((m) => m.event == 'turn' && m.payload['page'] == 99), isEmpty);
  });

  liveTest('SDK rejoin owns ordinary errors, recreating no extra channel', (tester) async {
    final a = wire.peer('a'), b = wire.peer('b');
    await wire.settle(tester);
    b.channel.fail(RealtimeSubscribeStatus.channelError, 'socket lost');
    expect(b.live.state, LiveConnection.reconnecting);
    await a.live.turned(at(5));
    b.channel.reconnect();
    await wire.settle(tester);
    expect(b.db.created.length, 1);
    expect(b.live.joined, isTrue);
    expect(b.live.clock.current!.position, at(5));
    expect(wire.trackCalls, 3);
  });

  liveTest('presence limit gets a full cooldown, not an immediate rejoin loop', (tester) async {
    final a = wire.peer('a');
    await wire.settle(tester);
    final old = a.channel;
    old.fail(RealtimeSubscribeStatus.channelError, 'Client presence rate limit exceeded');
    old.fail(RealtimeSubscribeStatus.closed);
    await wire.settle(tester, 30000);
    expect(a.db.created.length, 1);
    expect(a.live.joined, isFalse);
    await wire.settle(tester, 3000);
    expect(a.db.created.length, 2);
    expect(a.live.joined, isTrue);
    expect(wire.trackCalls, 2);
  });

  liveTest('ACK timeout retries the same version, then visibly reconnects without replaying', (tester) async {
    final a = wire.peer('a'), b = wire.peer('b');
    await wire.settle(tester);
    wire.holdTurnAcks = wire.dropTurns = true;
    a.live.turned(at(99));
    await wire.settle(tester, 4500);
    final turns = wire.messages.where((m) => m.event == 'turn').toList();
    expect(turns.length, 2);
    expect(turns[0].payload, turns[1].payload);
    expect(a.live.joined, isFalse);
    expect(a.live.clock.current, isNull);
    wire.holdTurnAcks = wire.dropTurns = false;
    await b.live.turned(at(7));
    for (final ack in wire.acknowledgements) {
      ack.complete(ChannelResponse.ok);
    }
    await wire.settle(tester, 4000);
    expect(a.live.joined, isTrue);
    expect(a.live.clock.current!.position, at(7));
    expect(b.live.clock.current!.position, at(7));
  });

  liveTest('an empty room does not resurrect a stale page after reconnect', (tester) async {
    final a = wire.peer('a');
    await wire.settle(tester);
    await a.live.turned(at(4));
    a.channel.fail(RealtimeSubscribeStatus.closed);
    await a.live.turned(at(99));
    await wire.settle(tester, 4000);
    expect(a.live.joined, isTrue);
    expect(a.live.clock.current, isNull);
  });

  liveTest('a newer peer corrects an elected responder with an old snapshot', (tester) async {
    final old = wire.peer('a'), newer = wire.peer('b');
    await wire.settle(tester);
    // Simulate a turn only one survivor received just before its sender left.
    newer.live.clock.receive(LiveTurn(position: at(8), seq: 20, by: 'departed'));
    expect(old.live.clock.current, isNull);
    final late = wire.peer('z');
    await wire.settle(tester);
    expect(late.live.joined, isTrue);
    expect(late.live.clock.current!.position, at(8));
    expect(old.live.clock.current!.position, at(8));
    await late.live.turned(at(9));
    expect(newer.live.clock.current!.seq, 21);
  });

  liveTest('a new intent cannot hide repeated send failures', (tester) async {
    final a = wire.peer('a');
    await wire.settle(tester);
    wire.holdTurnAcks = wire.dropTurns = true;
    a.live.turned(at(1));
    a.live.turned(at(2));
    wire.acknowledgements.first.complete(ChannelResponse.error);
    await tester.pump();
    a.live.turned(at(3));
    wire.acknowledgements.last.complete(ChannelResponse.error);
    await tester.pump();
    expect(a.live.state, LiveConnection.reconnecting);
    expect(a.live.clock.current, isNull);
    expect(wire.messages.where((m) => m.event == 'turn').length, 2);
  });

  liveTest('cues keep part filtering and leaving cancels reconnects', (tester) async {
    final a = wire.peer('a'), b = wire.peer('b');
    await wire.settle(tester);
    await a.live.sendCue('Chorus', partId: 7);
    expect(b.live.cue!.text, 'Chorus');
    await a.live.sendCue('Other part', partId: 8);
    expect(b.live.cue!.text, 'Chorus');
    b.channel.fail(RealtimeSubscribeStatus.closed);
    await b.live.leave();
    await wire.settle(tester, 5000);
    expect(b.db.created.length, 1);
  });
}
