import 'dart:math' as math;

/// Where the live stand is: an item of the setlist and a page of its sheet.
/// Using ids (not a flat page number) keeps every device in step even if
/// their page lists differ slightly.
class StandPosition {
  const StandPosition({required this.itemId, required this.pageIndex});
  final int itemId;
  final int pageIndex;

  Map<String, Object> toJson() => {'item': itemId, 'page': pageIndex};
  static StandPosition? fromJson(Object? json) =>
      json is Map && json['item'] is int && json['page'] is int && (json['page'] as int) >= 0
      ? StandPosition(itemId: json['item'] as int, pageIndex: json['page'] as int)
      : null;

  @override
  bool operator ==(Object other) => other is StandPosition && other.itemId == itemId && other.pageIndex == pageIndex;

  @override
  int get hashCode => Object.hash(itemId, pageIndex);
}

/// A page turn: where, plus a Lamport stamp (sequence, sender).
class LiveTurn {
  const LiveTurn({required this.position, required this.seq, required this.by});
  final StandPosition position;
  final int seq;
  final String by;

  /// Total order every device agrees on: higher sequence wins; on a tie
  /// the larger sender id wins. Wall clocks are never compared.
  bool isAfter(LiveTurn other) => seq != other.seq ? seq > other.seq : by.compareTo(other.by) > 0;

  Map<String, Object> toJson() => {...position.toJson(), 'seq': seq, 'by': by};
  static LiveTurn? fromJson(Object? json) {
    final position = StandPosition.fromJson(json);
    if (position == null || json is! Map || json['seq'] is! int || json['by'] is! String) return null;
    if ((json['seq'] as int) < 1 || (json['by'] as String).isEmpty) return null;
    return LiveTurn(position: position, seq: json['seq'] as int, by: json['by'] as String);
  }
}

/// Lamport clock for live mode. Anyone may turn the page; every device
/// applies the same rule, so all of them settle on the same page even when
/// two people turn at the same moment.
class LiveClock {
  LiveClock(this.me);
  final String me;
  int _seen = 0;
  LiveTurn? _current;

  LiveTurn? get current => _current;

  /// Reserve a version immediately, but only commit it with [receive] once
  /// the server acknowledges it. Unsent/failed local navigation must never
  /// appear in a snapshot offered to a joining peer.
  LiveTurn turn(StandPosition position) {
    _seen += 1;
    return LiveTurn(position: position, seq: _seen, by: me);
  }

  /// Forget the room's position when joining an empty room. Keep the logical
  /// counter monotonic for this client instance, including across reconnects.
  void clearPosition() => _current = null;

  /// A received turn/snapshot or an acknowledged local turn.
  /// Returns true if it becomes the current page.
  bool receive(LiveTurn turn) {
    _seen = math.max(_seen, turn.seq);
    final current = _current;
    if (current == null || turn.isAfter(current)) {
      _current = turn;
      return true;
    }
    return false;
  }
}
