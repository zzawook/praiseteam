import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;

import 'live_clock.dart';

/// A cue sent to everyone, or to the people of one part.
class LiveCue {
  const LiveCue({required this.text, required this.from, this.partId});
  final String text;
  final String from;
  final int? partId;

  Map<String, Object?> toJson() => {'text': text, 'from': from, 'part': partId};
  static LiveCue? fromJson(Map<String, dynamic> json) =>
      json['text'] is String &&
          (json['from'] == null || json['from'] is String) &&
          (json['part'] == null || json['part'] is int)
      ? LiveCue(text: json['text'] as String, from: json['from'] as String? ?? '', partId: json['part'] as int?)
      : null;
}

/// The transport may be subscribed while still collecting the room's state.
/// Only [connected] permits local navigation to be broadcast.
enum LiveConnection { connecting, syncing, connected, reconnecting, closed }

/// One viewer instance in a private `live:<session id>` channel. Presence is
/// ONLY membership, tracked once per subscription. Page/cue traffic and state
/// recovery use Broadcast. Confirmed state lives in peers, not in the database.
class LiveSession extends ChangeNotifier {
  LiveSession({
    required this.db,
    required this.sessionId,
    required this.me,
    required this.name,
    required this.myPartIds,
    required this.onFollow,
    String? clientId,
  }) : clientId = clientId ?? const Uuid().v4() {
    clock = LiveClock(this.clientId);
  }

  final SupabaseClient db;
  final int sessionId;
  final String me;
  final String name;
  final Set<int> myPartIds;
  final String clientId; // user id is not a device/viewer identity
  final void Function(StandPosition) onFollow;
  late final LiveClock clock;
  final _random = math.Random();
  RealtimeChannel? _channel;
  LiveConnection _state = LiveConnection.connecting;
  LiveConnection get state => _state;
  bool get joined => _state == LiveConnection.connected && _channel?.canPush == true;
  bool _closed = false;
  bool _subscribed = false;
  bool _tracked = false;
  bool _presenceSeen = false;
  bool _gotSnapshot = false;
  bool _replying = false;
  int _epoch = 0;
  int _requestSerial = 0;
  int _retryAttempt = 0;
  int participants = 0;
  final _peers = <String>{};
  final _requests = <String>{};
  Timer? _bootstrapTimer, _readyTimer, _replyTimer, _retryTimer, _stableTimer;
  LiveTurn? _pending, _sending;
  Future<void>? _draining;
  LiveCue? cue;
  int cueSerial = 0;

  // A quick leave/re-enter shares the server's per-client presence budget.
  // This is a reconnect safeguard, never a page-turn throttle.
  static final _trackTimes = Expando<List<DateTime>>();
  static const _ackTimeout = Duration(seconds: 2);

  static Map<String, dynamic> _payload(Map<String, dynamic> message) =>
      message['payload'] is Map ? Map<String, dynamic>.from(message['payload'] as Map) : message;

  void _setState(LiveConnection value) {
    if (_closed || _state == value) return;
    _state = value;
    notifyListeners();
  }

  bool _valid(RealtimeChannel channel, int epoch) =>
      !_closed && identical(_channel, channel) && epoch == _epoch && _subscribed;

  void join() {
    if (_closed || _channel != null) return;
    final channel = db.channel('live:$sessionId', opts: RealtimeChannelConfig(private: true, key: clientId, ack: true));
    _channel = channel;
    bool current() => !_closed && identical(channel, _channel);
    channel
      ..onBroadcast(
        event: 'turn',
        callback: (message) {
          if (!current() || !_subscribed) return;
          final turn = LiveTurn.fromJson(_payload(message));
          if (turn != null) {
            _receive(turn);
            _gotSnapshot = true; // a live turn is also authoritative room state
            _considerReady();
          }
        },
      )
      ..onBroadcast(
        event: 'state_request',
        callback: (message) {
          if (!current() || !_subscribed) return;
          final payload = _payload(message);
          final id = payload['id'];
          if (payload['from'] == clientId || id is! String || id.length > 100) return;
          if (_requests.length < 128) _requests.add(id);
          // Several simultaneous joiners can use the same response. Hearing a
          // request suppresses our redundant initial request, with a watchdog
          // in case the elected responder disappears.
          if (_state == LiveConnection.syncing) _waitForSnapshot();
          _scheduleReply();
        },
      )
      ..onBroadcast(
        event: 'state_snapshot',
        callback: (message) {
          if (!current() || !_subscribed) return;
          final payload = _payload(message);
          if (payload['from'] == clientId || payload['requests'] is! List) return;
          final turn = LiveTurn.fromJson(payload['turn']);
          if (payload['turn'] != null && turn == null) return;
          final ids = (payload['requests'] as List).whereType<String>().where((s) => s.length <= 100);
          if (turn != null) _receive(turn);
          final ours = clock.current;
          final needsCorrection = ours != null && (turn == null || ours.isAfter(turn));
          if (needsCorrection) {
            for (final id in ids) {
              if (_requests.length < 128) _requests.add(id);
            }
            _scheduleReply(correction: true);
          } else {
            _requests.removeAll(ids);
            if (_requests.isEmpty) _replyTimer?.cancel();
          }
          _gotSnapshot = true;
          _considerReady();
        },
      )
      ..onBroadcast(
        event: 'cue',
        callback: (message) {
          if (!current() || !_subscribed) return;
          final c = LiveCue.fromJson(_payload(message));
          if (c != null) _showCue(c);
        },
      )
      ..onPresenceSync((_) {
        if (!current()) return;
        _presenceSeen = true;
        _peers.clear();
        var count = 0;
        for (final state in channel.presenceState()) {
          for (final p in state.presences) {
            count++;
            _peers.add(p.payload['client'] is String ? p.payload['client'] as String : state.key);
          }
        }
        participants = count;
        _scheduleReply();
        _considerReady();
        notifyListeners();
      })
      ..subscribe((status, error) {
        if (!current()) return;
        if (status == RealtimeSubscribeStatus.subscribed) {
          if (!_subscribed) unawaited(_onSubscribed(channel));
        } else {
          _interrupted(status, error);
        }
      });
  }

  Future<void> _onSubscribed(RealtimeChannel channel) async {
    _retryTimer?.cancel();
    _subscribed = true;
    final epoch = ++_epoch;
    _tracked = false;
    _gotSnapshot = false;
    _setState(LiveConnection.syncing);
    final times = _trackTimes[db] ??= [];
    times.removeWhere((t) => DateTime.now().difference(t) >= const Duration(seconds: 31));
    if (times.length >= 5) {
      final wait = times.first.add(const Duration(seconds: 31)).difference(DateTime.now());
      await Future<void>.delayed(wait);
    }
    if (!_valid(channel, epoch) || !channel.canPush) return;
    times.add(DateTime.now());
    ChannelResponse response;
    try {
      response = await channel.track({'name': name, 'user': me, 'client': clientId}).timeout(_ackTimeout);
    } catch (_) {
      response = ChannelResponse.timedOut;
    }
    if (!_valid(channel, epoch)) return;
    if (response != ChannelResponse.ok) {
      _interrupted(RealtimeSubscribeStatus.channelError, null, recreate: true);
      return;
    }
    _tracked = true;
    _scheduleReply();
    _considerReady();
    // Request jitter only applies to joining; manual turns have no debounce.
    _bootstrapTimer?.cancel();
    _bootstrapTimer = Timer(Duration(milliseconds: 40 + _random.nextInt(80)), _requestState);
  }

  void _considerReady() {
    if (_state != LiveConnection.syncing || !_tracked || !_presenceSeen) return;
    final alone = !_peers.any((id) => id != clientId);
    if (!alone && !_gotSnapshot) return;
    _readyTimer ??= Timer(const Duration(milliseconds: 120), () {
      _readyTimer = null;
      if (_closed || !_subscribed || !_tracked || _state != LiveConnection.syncing) return;
      final stillAlone = !_peers.any((id) => id != clientId);
      if (!stillAlone && !_gotSnapshot) return;
      if (stillAlone && !_gotSnapshot) clock.clearPosition();
      _bootstrapTimer?.cancel();
      _setState(LiveConnection.connected);
      final latest = clock.current;
      if (latest != null) onFollow(latest.position);
      _stableTimer?.cancel();
      _stableTimer = Timer(const Duration(seconds: 30), () => _retryAttempt = 0);
    });
  }

  void _waitForSnapshot() {
    _bootstrapTimer?.cancel();
    _bootstrapTimer = Timer(Duration(milliseconds: 800 + _random.nextInt(400)), _requestState);
  }

  Future<void> _requestState() async {
    if (_closed || !_tracked || _state != LiveConnection.syncing) return;
    final channel = _channel!;
    final epoch = _epoch;
    final result = await _send(channel, 'state_request', {'from': clientId, 'id': '$clientId:${++_requestSerial}'});
    if (!_valid(channel, epoch)) return;
    if (result != ChannelResponse.ok) {
      _interrupted(RealtimeSubscribeStatus.channelError, null, recreate: true);
    } else if (_state == LiveConnection.syncing) {
      _waitForSnapshot();
    }
  }

  void _scheduleReply({bool correction = false}) {
    if (_closed || !_tracked || !_subscribed || _requests.isEmpty || _replying) return;
    if (_replyTimer?.isActive == true && !correction) return;
    if (correction) _replyTimer?.cancel();
    // First present peer answers. The others wait their turn and cancel when
    // an equal/newer snapshot covers their requests. Coalescing these replies
    // avoids every participant answering every newcomer. A newer peer can
    // still issue a correction, using the same suppression rule.
    final peers = {..._peers, clientId}.toList()..sort();
    final rank = peers.indexOf(clientId);
    final delay = correction ? 20 + _random.nextInt(40) : 25 + rank * 60 + _random.nextInt(20);
    _replyTimer = Timer(Duration(milliseconds: delay), () async {
      if (_closed || !_tracked || !_subscribed || _requests.isEmpty) return;
      _replying = true;
      final channel = _channel!;
      final epoch = _epoch;
      final ids = _requests.toList();
      final turn = clock.current;
      final result = await _send(channel, 'state_snapshot', {
        'from': clientId,
        'requests': ids,
        'turn': turn?.toJson(),
      });
      if (!_valid(channel, epoch)) return;
      _replying = false;
      if (result == ChannelResponse.ok) {
        final newer = clock.current != null && (turn == null || clock.current!.isAfter(turn));
        if (!newer) _requests.removeAll(ids);
        _scheduleReply(correction: newer);
      } else {
        _interrupted(RealtimeSubscribeStatus.channelError, null, recreate: true);
      }
    });
  }

  void _receive(LiveTurn turn) {
    if (!clock.receive(turn)) return;
    if (_pending != null && !(_pending!.isAfter(turn))) _pending = null;
    final local = _pending ?? _sending;
    if (local == null || turn.isAfter(local)) onFollow(turn.position);
  }

  /// The first intent goes onto the socket immediately. While its ACK is in
  /// flight, only the newest target is retained. There is no fixed Hz cap or
  /// timer before a normal turn, and no queue of obsolete animations/turns.
  Future<void> turned(StandPosition position) {
    if (!joined) return Future.value();
    _pending = clock.turn(position);
    return _draining ??= _drain(_channel!, _epoch);
  }

  Future<void> _drain(RealtimeChannel channel, int epoch) async {
    var failures = 0;
    try {
      while (_valid(channel, epoch) && joined && _pending != null) {
        final turn = _pending!;
        _pending = null;
        _sending = turn;
        var result = await _send(channel, 'turn', turn.toJson());
        if (!_valid(channel, epoch)) return;
        failures = result == ChannelResponse.ok ? 0 : failures + 1;
        // One bounded retry of the SAME version; a newer intent supersedes it.
        if (result != ChannelResponse.ok && _pending == null && failures < 2) {
          await Future<void>.delayed(Duration(milliseconds: 80 + _random.nextInt(80)));
          if (!_valid(channel, epoch)) return;
          if (_pending == null) {
            result = await _send(channel, 'turn', turn.toJson());
            failures = result == ChannelResponse.ok ? 0 : failures + 1;
          }
        }
        if (!_valid(channel, epoch)) return;
        _sending = null;
        if (result == ChannelResponse.ok) {
          clock.receive(turn);
        } else if (_pending == null || failures >= 2) {
          _interrupted(RealtimeSubscribeStatus.channelError, null, recreate: true);
          return;
        }
      }
      // An ACK can arrive after a winning concurrent remote turn. Restore
      // that winner rather than letting the local animation leave us behind.
      final current = clock.current;
      if (_valid(channel, epoch) && current != null && current.by != clientId) onFollow(current.position);
    } finally {
      if (epoch == _epoch) {
        _sending = null;
        _draining = null;
      }
    }
  }

  Future<ChannelResponse> _send(RealtimeChannel channel, String event, Map<String, dynamic> payload) async {
    // The SDK otherwise falls back to REST on a dead socket. An old/offline
    // local page must never be broadcast through that fallback.
    if (_closed || !_subscribed || !identical(channel, _channel) || !channel.canPush) return ChannelResponse.error;
    try {
      return await channel.sendBroadcastMessage(event: event, payload: payload).timeout(_ackTimeout);
    } catch (_) {
      return ChannelResponse.timedOut;
    }
  }

  Future<void> sendCue(String text, {int? partId}) async {
    if (!joined) return;
    final c = LiveCue(text: text, from: name, partId: partId);
    final channel = _channel!;
    final epoch = _epoch;
    final response = await _send(channel, 'cue', c.toJson());
    if (!_valid(channel, epoch)) return;
    if (response == ChannelResponse.ok) {
      _showCue(c);
    } else {
      _interrupted(RealtimeSubscribeStatus.channelError, null, recreate: true);
    }
  }

  void _showCue(LiveCue c) {
    if (c.partId != null && !myPartIds.contains(c.partId)) return;
    cue = c;
    cueSerial++;
    notifyListeners();
  }

  void _interrupted(RealtimeSubscribeStatus status, Object? error, {bool recreate = false}) {
    if (_closed) return;
    _subscribed = false;
    _tracked = false;
    _presenceSeen = false;
    _gotSnapshot = false;
    _replying = false;
    ++_epoch; // invalidate pending sends, callbacks and animation intents
    _pending = _sending = null;
    _draining = null;
    _requests.clear();
    _peers.clear();
    participants = 0;
    _cancelSyncTimers();
    _setState(LiveConnection.reconnecting);
    final message = error?.toString().toLowerCase() ?? '';
    final limited = message.contains('rate limit') || message.contains('too many');
    final presenceLimited = limited && message.contains('presence');
    // Do not let a following CLOSED event shorten the rate-limit cooldown.
    if (_retryTimer?.isActive == true && !limited && (_channel == null || status != RealtimeSubscribeStatus.closed)) {
      return;
    }
    _retryTimer?.cancel();
    final backoff = math.min(30000, 1000 * (1 << math.min(_retryAttempt++, 5)));
    final delay = presenceLimited ? 31000 : backoff + _random.nextInt(500);
    final old = _channel;
    if (recreate || limited || status == RealtimeSubscribeStatus.closed) {
      _channel = null;
      if (old != null) unawaited(db.removeChannel(old));
      _retryTimer = Timer(Duration(milliseconds: delay), join);
    } else {
      // Ordinary socket loss/errors already rejoin inside the SDK. Give that
      // one owner a chance; replace only a channel that remains stuck.
      _retryTimer = Timer(Duration(milliseconds: math.max(10000, delay)), () {
        if (_closed || _subscribed) return;
        _channel = null;
        if (old != null) unawaited(db.removeChannel(old));
        join();
      });
    }
  }

  void _cancelSyncTimers() {
    _bootstrapTimer?.cancel();
    _readyTimer?.cancel();
    _readyTimer = null;
    _replyTimer?.cancel();
    _stableTimer?.cancel();
  }

  Future<void> leave() async {
    if (_closed) return;
    _closed = true;
    _state = LiveConnection.closed;
    ++_epoch;
    _cancelSyncTimers();
    _retryTimer?.cancel();
    final channel = _channel;
    _channel = null;
    if (channel != null) await db.removeChannel(channel);
  }

  @override
  void dispose() {
    unawaited(leave());
    super.dispose();
  }
}
