import 'package:flutter_test/flutter_test.dart';
import 'package:praiseteam/features/live/live_clock.dart';

StandPosition at(int item, int page) => StandPosition(itemId: item, pageIndex: page);

void main() {
  test('anyone can turn; everyone follows the latest turn', () {
    final a = LiveClock('a'), b = LiveClock('b');
    final t1 = a.turn(at(1, 1));
    expect(b.receive(t1), isTrue);
    final t2 = b.turn(at(2, 0));
    expect(t2.seq, greaterThan(t1.seq), reason: 'b saw t1, so its turn is later');
    expect(a.receive(t2), isTrue);
    expect(a.current!.position, at(2, 0));
  });

  test('two people turning at once: all devices settle on the same page', () {
    final a = LiveClock('a'), b = LiveClock('b'), c = LiveClock('c');
    final fromA = a.turn(at(1, 1));
    final fromB = b.turn(at(1, 2)); // concurrent: same sequence number
    expect(fromA.seq, fromB.seq);

    // Messages arrive in different orders on different devices.
    a.receive(fromB);
    b.receive(fromA);
    c
      ..receive(fromB)
      ..receive(fromA);
    expect({a.current!.position, b.current!.position, c.current!.position}, {at(1, 2)},
        reason: 'tie broken by sender id: "b" > "a"');
  });

  test('an old turn arriving late does not move anyone back', () {
    final a = LiveClock('a'), b = LiveClock('b');
    final old = a.turn(at(1, 0));
    final newer = a.turn(at(1, 1));
    expect(b.receive(newer), isTrue);
    expect(b.receive(old), isFalse);
    expect(b.current!.position, at(1, 1));
  });

  test('a late joiner adopts the newest position among everyone present', () {
    final late = LiveClock('z');
    final seen = [
      const LiveTurn(position: StandPosition(itemId: 1, pageIndex: 0), seq: 3, by: 'a'),
      const LiveTurn(position: StandPosition(itemId: 2, pageIndex: 1), seq: 7, by: 'b'),
      const LiveTurn(position: StandPosition(itemId: 2, pageIndex: 0), seq: 5, by: 'c'),
    ];
    for (final t in seen) {
      late.receive(t);
    }
    expect(late.current!.position, at(2, 1));
    expect(late.turn(at(3, 0)).seq, 8, reason: 'its next turn outranks everything it saw');
  });

  test('turns survive the wire format', () {
    const t = LiveTurn(position: StandPosition(itemId: 4, pageIndex: 2), seq: 9, by: 'u');
    final back = LiveTurn.fromJson(t.toJson())!;
    expect(back.position, t.position);
    expect((back.seq, back.by), (9, 'u'));
    expect(LiveTurn.fromJson({'item': 'x'}), isNull);
  });
}
