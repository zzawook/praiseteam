import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;

import 'live_clock.dart';

/// A cue sent to everyone, or to the people of one part.
class LiveCue {
  const LiveCue({required this.text, required this.from, this.partId});
  final String text;
  final String from;
  final int? partId;

  Map<String, Object?> toJson() => {'text': text, 'from': from, 'part': partId};
  static LiveCue? fromJson(Map<String, dynamic> json) => json['text'] is String
      ? LiveCue(text: json['text'] as String, from: json['from'] as String? ?? '', partId: json['part'] as int?)
      : null;
}

/// One device's connection to a service's live stand.
///
/// Realtime private channel `live:<session id>` (members of the team only,
/// see the live_mode migration). Broadcast carries page turns and cues;
/// presence carries who is here and the last turn each saw, so a late
/// joiner lands on the current page. Nothing is stored anywhere.
class LiveSession extends ChangeNotifier {
  LiveSession({
    required this.db,
    required this.sessionId,
    required this.me,
    required this.name,
    required this.myPartIds,
    required this.onFollow,
  }) : clock = LiveClock(me);

  final SupabaseClient db;
  final int sessionId;
  final String me;
  final String name;
  final Set<int> myPartIds;

  /// Called when the stand should move to another page.
  final void Function(StandPosition) onFollow;

  final LiveClock clock;
  RealtimeChannel? _channel;
  bool joined = false;

  /// Set when leaving. Events still in flight while the channel closes are
  /// ignored, so nothing touches the stand after it is gone.
  bool _closed = false;
  int participants = 0;
  LiveCue? cue;
  int cueSerial = 0;

  static Map<String, dynamic> _payload(Map<String, dynamic> message) =>
      message['payload'] is Map ? Map<String, dynamic>.from(message['payload'] as Map) : message;

  void join() {
    final channel = db.channel('live:$sessionId', opts: RealtimeChannelConfig(private: true, key: me));
    channel
      ..onBroadcast(
        event: 'turn',
        callback: (message) {
          if (_closed) return;
          final turn = LiveTurn.fromJson(_payload(message));
          if (turn != null && turn.by != me && clock.receive(turn)) onFollow(turn.position);
        },
      )
      ..onBroadcast(
        event: 'cue',
        callback: (message) {
          if (_closed) return;
          final c = LiveCue.fromJson(_payload(message));
          if (c == null || (c.partId != null && !myPartIds.contains(c.partId))) return;
          cue = c;
          cueSerial++;
          notifyListeners();
        },
      )
      ..onPresenceSync((_) {
        if (_closed) return;
        var count = 0;
        LiveTurn? newest;
        for (final state in channel.presenceState()) {
          for (final p in state.presences) {
            count++;
            final t = LiveTurn.fromJson(p.payload['turn']);
            if (t != null && (newest == null || t.isAfter(newest))) newest = t;
          }
        }
        participants = count;
        if (newest != null && newest.by != me && clock.receive(newest)) onFollow(newest.position);
        notifyListeners();
      })
      ..subscribe((status, error) async {
        if (_closed) return;
        if (status == RealtimeSubscribeStatus.subscribed) {
          joined = true;
          await channel.track(_presence());
          if (_closed) return;
          notifyListeners();
        }
      });
    _channel = channel;
  }

  Map<String, dynamic> _presence() => {'name': name, if (clock.current != null) 'turn': clock.current!.toJson()};

  /// This device turned the page (and is following): tell everyone.
  Future<void> turned(StandPosition position) async {
    final channel = _channel;
    if (channel == null || !joined) return;
    final turn = clock.turn(position);
    await channel.sendBroadcastMessage(event: 'turn', payload: turn.toJson());
    await channel.track(_presence());
  }

  Future<void> sendCue(String text, {int? partId}) async {
    final channel = _channel;
    if (channel == null || !joined) return;
    final c = LiveCue(text: text, from: name, partId: partId);
    await channel.sendBroadcastMessage(event: 'cue', payload: c.toJson());
    // Senders see their own cue too, if it is meant for them.
    if (partId == null || myPartIds.contains(partId)) {
      cue = c;
      cueSerial++;
      notifyListeners();
    }
  }

  /// Leaving the stand leaves live mode too (the viewer calls this when it
  /// closes): presence drops, so the others' count goes down by one.
  Future<void> leave() async {
    _closed = true;
    final channel = _channel;
    _channel = null;
    joined = false;
    if (channel != null) await db.removeChannel(channel);
  }
}
