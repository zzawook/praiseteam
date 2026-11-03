import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A local viewport transform. It never changes the page-normalized ink data.
@immutable
class SheetTransform {
  const SheetTransform({this.scale = 1, this.offset = Offset.zero});

  static const maxScale = 4.0;
  final double scale;
  final Offset offset;

  bool get zoomed => scale > 1.001;
  Offset toPage(Offset viewportPoint) => (viewportPoint - offset) / scale;
  Offset toViewport(Offset pagePoint) => pagePoint * scale + offset;

  Matrix4 get matrix => Matrix4.identity()
    ..translateByDouble(offset.dx, offset.dy, 0, 1)
    ..scaleByDouble(scale, scale, 1, 1);

  SheetTransform zoomAt(double newScale, Offset focal, Size viewport, Rect page) =>
      pinch(newScale, focal, focal, viewport, page);

  SheetTransform pinch(double newScale, Offset startFocal, Offset focal, Size viewport, Rect page) {
    final nextScale = newScale.clamp(1.0, maxScale);
    return SheetTransform(scale: nextScale, offset: focal - toPage(startFocal) * nextScale).bounded(viewport, page);
  }

  SheetTransform pan(Offset delta, Size viewport, Rect page) =>
      SheetTransform(scale: scale, offset: offset + delta).bounded(viewport, page);

  /// Toolbars, live cues and orientation can resize the viewport. Keep the
  /// same paper point in its center and retain magnification when that happens.
  SheetTransform reframe(Size before, Rect oldPage, Size after, Rect newPage) {
    if (before.isEmpty || oldPage.isEmpty) return const SheetTransform();
    final oldCenter = toPage(before.center(Offset.zero)) - oldPage.topLeft;
    final point =
        newPage.topLeft +
        Offset(oldCenter.dx / oldPage.width * newPage.width, oldCenter.dy / oldPage.height * newPage.height);
    return SheetTransform(scale: scale, offset: after.center(Offset.zero) - point * scale).bounded(after, newPage);
  }

  SheetTransform bounded(Size viewport, Rect page) {
    double axis(double offset, double start, double length, double available) {
      if (length * scale <= available) return (available - length * scale) / 2 - start * scale;
      return offset.clamp(available - (start + length) * scale, -start * scale);
    }

    return SheetTransform(
      scale: scale,
      offset: Offset(
        axis(offset.dx, page.left, page.width, viewport.width),
        axis(offset.dy, page.top, page.height, viewport.height),
      ),
    );
  }
}

/// Matches the centered AspectRatio used by the PDF and its annotation layer.
Rect fittedSheetRect(Size viewport, double? aspectRatio) {
  if (aspectRatio == null || viewport.isEmpty) return Offset.zero & viewport;
  final width = math.min(viewport.width, viewport.height * aspectRatio);
  final size = Size(width, math.min(viewport.height, width / aspectRatio));
  return Alignment.center.inscribe(size, Offset.zero & viewport);
}
