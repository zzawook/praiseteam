import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:praiseteam/features/annotations/annotation_layer.dart';
import 'package:praiseteam/features/annotations/annotations_controller.dart';
import 'package:praiseteam/features/viewer/sheet_pdf_page.dart';

import 'flow_helpers.dart';

/// Real native PDF rendering, transformed touch input and the normal ink outbox.
Future<void> checkNativeZoom(
  MobileFlow flow,
  ProviderContainer container,
) async {
  final tester = flow.tester;
  final layer = find.byType(AnnotationLayer).first;
  final pdf = find.byType(SheetPdfPage).first;
  final documentBuilder = find
      .descendant(of: pdf, matching: find.byType(PdfDocumentViewBuilder))
      .first;
  final reference = tester
      .widget<PdfDocumentViewBuilder>(documentBuilder)
      .documentRef;
  final baseRect = tester.getRect(layer);
  final before = {...container.read(sessionInkProvider(107)).requireValue.keys};
  Future<void> zoomControl(String tooltip) async {
    final target = find.byTooltip(tooltip).hitTestable();
    await flow.until(() => target.evaluate().isNotEmpty, reason: tooltip);
    // These controls are already visible inside a horizontal PageView.
    // ensureVisible would try to center them by moving the page itself.
    await tester.tap(target.first);
    await flow.settle(350);
  }

  // Zoom while viewing, then open the handwriting toolbar. Resizing the
  // available page area must retain the zoom rather than silently fitting.
  await flow.tapText('완료');
  await zoomControl('확대');
  await zoomControl('확대');
  await flow.see('200%');
  await flow.tapText('필기');
  await flow.see('200%');
  final zoomedRect = tester.getRect(layer);
  expect(zoomedRect.width, closeTo(baseRect.width * 2, .5));
  expect(tester.getRect(pdf).topLeft.dx, closeTo(zoomedRect.left, .01));
  expect(tester.getRect(pdf).topLeft.dy, closeTo(zoomedRect.top, .01));
  expect(tester.getRect(pdf).width, closeTo(zoomedRect.width, .01));

  final box = tester.renderObject<RenderBox>(layer);
  final center = box.localToGlobal(box.size.center(Offset.zero));
  final start = center + const Offset(25, 0);
  final expected = box.globalToLocal(start);
  final stroke = await tester.startGesture(start);
  for (var i = 1; i <= 32; i++) {
    await stroke.moveTo(
      center +
          Offset(
            25 * math.cos(i * math.pi / 16),
            25 * math.sin(i * math.pi / 16),
          ),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  await stroke.up();
  await flow.until(
    () => container
        .read(sessionInkProvider(107))
        .requireValue
        .keys
        .any((id) => !before.contains(id)),
    reason: 'native zoomed ink saved',
  );
  final saved = container
      .read(sessionInkProvider(107))
      .requireValue
      .values
      .singleWhere((s) => !before.contains(s.id));
  expect(saved.points.first.x, closeTo(expected.dx / box.size.width, .002));
  expect(saved.points.first.y, closeTo(expected.dy / box.size.height, .002));
  expect(saved.width, .004);
  await flow.shot('08a-zoomed-annotation');
  await zoomControl('화면 맞춤');
  await flow.see('100%');
  expect(tester.getRect(layer).width, closeTo(baseRect.width, .5));
  expect(
    container
        .read(sessionInkProvider(107))
        .requireValue[saved.id]!
        .points
        .first
        .x,
    closeTo(saved.points.first.x, .0001),
  );

  // First finger lands on the real stroke with the eraser selected. Adding a
  // second finger must turn it into navigation, never a persistent deletion.
  await flow.tooltip('지우개');
  final atFit = tester.renderObject<RenderBox>(layer);
  final point = atFit.localToGlobal(
    Offset(
      saved.points.first.x * atFit.size.width,
      saved.points.first.y * atFit.size.height,
    ),
  );
  final a = await tester.startGesture(point, pointer: 21);
  await tester.pump();
  final b = await tester.startGesture(point + const Offset(50, 0), pointer: 22);
  await tester.pump();
  await a.moveTo(point - const Offset(25, 0));
  await b.moveTo(point + const Offset(75, 0));
  await tester.pump();
  await a.up();
  await b.up();
  await flow.settle(600);
  expect(
    container.read(sessionInkProvider(107)).requireValue[saved.id]!.isDeleted,
    isFalse,
  );
  expect(
    container.read(sessionInkProvider(107)).requireValue.length,
    before.length + 1,
  );
  await flow.contains('1 / 5');
  await zoomControl('화면 맞춤');
  await flow.tooltip('펜');
  expect(
    tester.widget<PdfDocumentViewBuilder>(documentBuilder).documentRef,
    same(reference),
    reason: 'zoom, ink and toolbar changes must retain the loaded PDF',
  );
  await flow.shot('08b-annotation-after-fit');
}
