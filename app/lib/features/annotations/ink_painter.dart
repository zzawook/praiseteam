import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import 'ink.dart';

/// A stroke being drawn right now (not yet saved).
class LiveInk {
  const LiveInk({required this.points, required this.tool, required this.color, required this.width});
  final List<InkPoint> points;
  final InkTool tool;
  final int color;
  final double width;
}

/// Paints strokes on one page. Coordinates are page fractions, so the
/// painter only needs the page's rendered size.
class InkPainter extends CustomPainter {
  InkPainter({required this.strokes, this.live, required this.revision});

  final List<InkStroke> strokes;
  final LiveInk? live;

  /// Bumps when strokes change, so repaints happen only then.
  final int revision;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      _paint(canvas, size, s.tool, s.color, s.width, s.points);
    }
    final l = live;
    if (l != null) _paint(canvas, size, l.tool, l.color, l.width, l.points);
  }

  static void _paint(Canvas canvas, Size size, InkTool tool, int argb, double width, List<InkPoint> points) {
    if (points.isEmpty) return;
    final color = Color(argb.toUnsigned(32));
    final px = width * size.width;
    switch (tool) {
      case InkTool.pen:
        // Pressure from a stylus varies; mouse and finger input is stored
        // at a constant 0.5, for which the shape simulates pressure.
        final realPressure = points.any((p) => (p.p - 0.5).abs() > 0.02);
        final outline = getStroke(
          [for (final p in points) PointVector(p.x * size.width, p.y * size.height, p.p)],
          options: StrokeOptions(
            size: px,
            thinning: 0.55,
            smoothing: 0.5,
            streamline: 0.4,
            simulatePressure: !realPressure,
            isComplete: true,
          ),
        );
        if (outline.length < 2) return;
        canvas.drawPath(Path()..addPolygon(outline, true), Paint()..color = color);
      case InkTool.highlighter:
        final path = Path()..moveTo(points.first.x * size.width, points.first.y * size.height);
        for (final p in points.skip(1)) {
          path.lineTo(p.x * size.width, p.y * size.height);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = px
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..blendMode = BlendMode.multiply,
        );
    }
  }

  @override
  bool shouldRepaint(covariant InkPainter old) => old.revision != revision || old.live != live;
}
