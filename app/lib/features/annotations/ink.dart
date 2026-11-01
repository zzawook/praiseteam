import 'dart:math' as math;
import 'dart:typed_data';

/// A point of a stroke in page coordinates: x and y are fractions of the
/// page width/height (0..1), so a stroke lands on the same spot of the
/// sheet on a phone, a tablet or a laptop. Pressure is 0..1.
typedef InkPoint = ({double x, double y, double p});

enum InkVisibility { team, private }

enum InkTool { pen, highlighter }

/// One stroke. Immutable: erasing sets [deletedAt].
class InkStroke {
  const InkStroke({
    required this.id,
    required this.teamId,
    required this.sessionId,
    required this.itemId,
    required this.sheetId,
    required this.pageIndex,
    required this.ownerId,
    required this.visibility,
    required this.tool,
    required this.color,
    required this.width,
    required this.points,
    this.deletedAt,
  });

  final String id;
  final int teamId;
  final int sessionId;
  final int itemId;
  final int sheetId;
  final int pageIndex;
  final String ownerId;
  final InkVisibility visibility;
  final InkTool tool;

  /// ARGB
  final int color;

  /// Fraction of the page width.
  final double width;
  final List<InkPoint> points;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  InkStroke withDeletedAt(DateTime? value) => InkStroke(
        id: id,
        teamId: teamId,
        sessionId: sessionId,
        itemId: itemId,
        sheetId: sheetId,
        pageIndex: pageIndex,
        ownerId: ownerId,
        visibility: visibility,
        tool: tool,
        color: color,
        width: width,
        points: points,
        deletedAt: value,
      );

  /// From a `strokes` row (PostgREST or Realtime payload).
  factory InkStroke.fromRow(Map<String, dynamic> row) => InkStroke(
        id: row['id'] as String,
        teamId: row['team_id'] as int,
        sessionId: row['session_id'] as int,
        itemId: row['setlist_item_id'] as int,
        sheetId: row['sheet_id'] as int,
        pageIndex: row['page_index'] as int,
        ownerId: row['owner_id'] as String,
        visibility: InkVisibility.values.byName(row['visibility'] as String),
        tool: InkTool.values.byName(row['tool'] as String),
        color: row['color'] as int,
        width: (row['width'] as num).toDouble(),
        points: decodePoints(fromPgBytea(row['points'] as String)),
        deletedAt: row['deleted_at'] == null ? null : DateTime.parse(row['deleted_at'] as String),
      );

  Map<String, Object?> toInsertRow() => {
        'id': id,
        'team_id': teamId,
        'session_id': sessionId,
        'setlist_item_id': itemId,
        'sheet_id': sheetId,
        'page_index': pageIndex,
        'visibility': visibility.name,
        'tool': tool.name,
        'color': color.toSigned(32),
        'width': width,
        'points': toPgBytea(encodePoints(points)),
      };
}

const _bytesPerPoint = 5;

/// Packs points as little-endian uint16 x, uint16 y, uint8 pressure.
Uint8List encodePoints(List<InkPoint> points) {
  final data = ByteData(points.length * _bytesPerPoint);
  var o = 0;
  int q16(double v) => (v.clamp(0.0, 1.0) * 65535).round();
  for (final p in points) {
    data
      ..setUint16(o, q16(p.x), Endian.little)
      ..setUint16(o + 2, q16(p.y), Endian.little)
      ..setUint8(o + 4, (p.p.clamp(0.0, 1.0) * 255).round());
    o += _bytesPerPoint;
  }
  return data.buffer.asUint8List();
}

List<InkPoint> decodePoints(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  return [
    for (var o = 0; o + _bytesPerPoint <= bytes.length; o += _bytesPerPoint)
      (
        x: data.getUint16(o, Endian.little) / 65535,
        y: data.getUint16(o + 2, Endian.little) / 65535,
        p: data.getUint8(o + 4) / 255,
      ),
  ];
}

/// PostgreSQL bytea in hex form ("\x0a1b..."), as PostgREST and Realtime
/// exchange it.
String toPgBytea(Uint8List bytes) {
  final out = StringBuffer(r'\x');
  for (final b in bytes) {
    out.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return out.toString();
}

Uint8List fromPgBytea(String text) {
  final hex = text.startsWith(r'\x') ? text.substring(2) : text;
  final out = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(hex.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}

/// Ramer–Douglas–Peucker: drops points closer than [epsilon] (in page
/// fractions) to the line through their neighbours. Keeps the stroke's
/// shape while cutting storage several times over.
List<InkPoint> simplify(List<InkPoint> points, {double epsilon = 0.0008}) {
  if (points.length < 3) return points;
  final keep = List<bool>.filled(points.length, false)
    ..[0] = true
    ..[points.length - 1] = true;
  final stack = <(int, int)>[(0, points.length - 1)];
  while (stack.isNotEmpty) {
    final (start, end) = stack.removeLast();
    var maxDistance = 0.0;
    var index = -1;
    for (var i = start + 1; i < end; i++) {
      final d = _distanceToSegment(points[i], points[start], points[end]);
      if (d > maxDistance) {
        maxDistance = d;
        index = i;
      }
    }
    if (index != -1 && maxDistance > epsilon) {
      keep[index] = true;
      stack
        ..add((start, index))
        ..add((index, end));
    }
  }
  return [for (var i = 0; i < points.length; i++) if (keep[i]) points[i]];
}

double _distanceToSegment(InkPoint p, InkPoint a, InkPoint b) {
  final dx = b.x - a.x, dy = b.y - a.y;
  final lengthSquared = dx * dx + dy * dy;
  if (lengthSquared == 0) return math.sqrt(math.pow(p.x - a.x, 2) + math.pow(p.y - a.y, 2));
  final t = (((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSquared).clamp(0.0, 1.0);
  final cx = a.x + t * dx, cy = a.y + t * dy;
  return math.sqrt(math.pow(p.x - cx, 2) + math.pow(p.y - cy, 2));
}

/// Shortest distance from [p] to the stroke's polyline, in page fractions.
double distanceToStroke(InkPoint p, List<InkPoint> stroke) {
  if (stroke.isEmpty) return double.infinity;
  if (stroke.length == 1) return _distanceToSegment(p, stroke.first, stroke.first);
  var best = double.infinity;
  for (var i = 0; i < stroke.length - 1; i++) {
    best = math.min(best, _distanceToSegment(p, stroke[i], stroke[i + 1]));
  }
  return best;
}
