import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:praiseteam/features/annotations/ink.dart';

void main() {
  test('points survive encode/decode within 16-bit precision', () {
    final points = <InkPoint>[(x: 0.0, y: 1.0, p: 0.5), (x: 0.123456, y: 0.654321, p: 1.0), (x: 1.0, y: 0.0, p: 0.0)];
    final decoded = decodePoints(encodePoints(points));
    expect(decoded.length, 3);
    for (var i = 0; i < 3; i++) {
      expect(decoded[i].x, closeTo(points[i].x, 1 / 65535));
      expect(decoded[i].y, closeTo(points[i].y, 1 / 65535));
      expect(decoded[i].p, closeTo(points[i].p, 1 / 255));
    }
    expect(encodePoints(points).length, 15, reason: '5 bytes per point, matching the database check');
  });

  test('bytea hex round trip matches the Postgres format', () {
    final bytes = Uint8List.fromList([0, 1, 127, 128, 255]);
    expect(toPgBytea(bytes), r'\x00017f80ff');
    expect(fromPgBytea(r'\x00017f80ff'), bytes);
  });

  test('simplify drops points on a straight line and keeps corners', () {
    final line = [for (var i = 0; i <= 100; i++) (x: i / 100, y: 0.5, p: 0.5)];
    expect(simplify(line).length, 2);
    final corner = [
      for (var i = 0; i <= 50; i++) (x: i / 100, y: 0.2, p: 0.5),
      for (var i = 1; i <= 50; i++) (x: 0.5, y: 0.2 + i / 100, p: 0.5),
    ];
    final kept = simplify(corner);
    expect(kept.length, 3);
    expect(kept[1].x, closeTo(0.5, 1e-9));
  });

  test('distance to a stroke is measured to the nearest segment', () {
    final stroke = <InkPoint>[(x: 0.1, y: 0.1, p: 1), (x: 0.9, y: 0.1, p: 1)];
    expect(distanceToStroke((x: 0.5, y: 0.15, p: 0), stroke), closeTo(0.05, 1e-9));
    expect(distanceToStroke((x: 0.0, y: 0.1, p: 0), stroke), closeTo(0.1, 1e-9));
  });

  test('stroke rows round trip through the insert shape', () {
    const stroke = InkStroke(
      id: '0198f1c2-0000-7000-8000-000000000001',
      teamId: 1,
      sessionId: 2,
      itemId: 3,
      sheetId: 4,
      pageIndex: 0,
      ownerId: 'u',
      visibility: InkVisibility.private,
      tool: InkTool.highlighter,
      color: 0xFFF2A007,
      width: 0.02,
      points: [(x: 0.25, y: 0.75, p: 0.5)],
    );
    final row = {...stroke.toInsertRow(), 'owner_id': 'u', 'deleted_at': null};
    final back = InkStroke.fromRow(row);
    expect(back.visibility, InkVisibility.private);
    expect(back.tool, InkTool.highlighter);
    expect(back.color.toUnsigned(32), 0xFFF2A007);
    expect(back.points.single.x, closeTo(0.25, 1 / 65535));
    expect(row['color'], isNegative, reason: 'ARGB stored as a signed 32-bit integer');
  });
}
