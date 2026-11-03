import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:praiseteam/features/annotations/annotation_layer.dart';
import 'package:praiseteam/features/annotations/annotations_controller.dart';
import 'package:praiseteam/features/annotations/ink.dart';
import 'package:praiseteam/features/viewer/sheet_transform.dart';
import 'package:praiseteam/features/viewer/sheet_viewport.dart';
import 'package:praiseteam/l10n/app_localizations.dart';

class RecordingInk extends SessionInk {
  final added = <InkStroke>[];
  final erased = <String>[];

  @override
  Future<Map<String, InkStroke>> build(int sessionId) async => {};

  @override
  InkStroke add({
    required int teamId,
    required int itemId,
    required int sheetId,
    required int pageIndex,
    required InkVisibility visibility,
    required InkTool tool,
    required int color,
    required double width,
    required List<InkPoint> points,
  }) {
    final stroke = InkStroke(
      id: 'stroke-${added.length}',
      teamId: teamId,
      sessionId: 1,
      itemId: itemId,
      sheetId: sheetId,
      pageIndex: pageIndex,
      ownerId: 'me',
      visibility: visibility,
      tool: tool,
      color: color,
      width: width,
      points: List.of(points),
    );
    added.add(stroke);
    state = AsyncData({...?state.value, stroke.id: stroke});
    return stroke;
  }

  @override
  void setDeleted(String strokeId, {required bool deleted}) {
    erased.add(strokeId);
    state = AsyncData({...state.requireValue, strokeId: state.requireValue[strokeId]!.withDeletedAt(DateTime.now())});
  }

  @override
  bool canErase(InkStroke stroke, {required bool isLeader}) => stroke.ownerId == 'me';
}

void main() {
  test('zoom keeps its focal point and clamps the actual page, including letterboxing', () {
    const viewport = Size(800, 500);
    final page = fittedSheetRect(viewport, .7);
    expect(page, const Rect.fromLTWH(225, 0, 350, 500));
    final zoom = const SheetTransform().zoomAt(2, const Offset(400, 250), viewport, page);
    expect(zoom.toViewport(const Offset(400, 250)), const Offset(400, 250));
    // The enlarged portrait page is still narrower than the viewport, so it
    // stays centered horizontally, but can move vertically to either edge.
    expect(zoom.pan(const Offset(10000, 10000), viewport, page).offset, const Offset(-400, 0));
    expect(zoom.pan(const Offset(-10000, -10000), viewport, page).offset, const Offset(-400, -500));
    final reset = zoom.zoomAt(1, const Offset(400, 250), viewport, page);
    expect(reset.offset, Offset.zero);
  });

  test('toolbar and orientation resizing retain zoom and the paper point at the center', () {
    const before = Size(400, 600), after = Size(400, 500);
    final oldPage = fittedSheetRect(before, 2 / 3), newPage = fittedSheetRect(after, 2 / 3);
    final zoom = const SheetTransform()
        .zoomAt(2, before.center(Offset.zero), before, oldPage)
        .pan(const Offset(40, -60), before, oldPage);
    final resized = zoom.reframe(before, oldPage, after, newPage);
    final point = resized.toPage(after.center(Offset.zero)) - newPage.topLeft;
    expect(resized.scale, 2);
    expect(point.dx / newPage.width, closeTo(.45, 1e-6));
    expect(point.dy / newPage.height, closeTo(.55, 1e-6));
  });

  late RecordingInk ink;
  late ProviderContainer container;
  late ValueNotifier<InkSettings> settings;
  late List<int> turns;
  late List<InkAction> actions;

  Future<void> mount(WidgetTester tester, {InkMode mode = InkMode.pen, double aspectRatio = 2 / 3}) async {
    ink = RecordingInk();
    container = ProviderContainer(overrides: [sessionInkProvider(1).overrideWith(() => ink)]);
    settings = ValueNotifier(InkSettings(mode: mode));
    turns = [];
    actions = [];
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
      container.dispose();
    });
    await container.read(sessionInkProvider(1).future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                height: 600,
                child: ValueListenableBuilder<InkSettings>(
                  valueListenable: settings,
                  builder: (_, value, _) => SheetViewport(
                    aspectRatio: aspectRatio,
                    drawing: value.drawing,
                    stylusOnly: value.stylusOnly,
                    onTurn: turns.add,
                    builder: (blocked, scale) => Center(
                      child: AspectRatio(
                        aspectRatio: aspectRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const ColoredBox(key: ValueKey('paper'), color: Colors.white),
                            AnnotationLayer(
                              teamId: 1,
                              sessionId: 1,
                              itemId: 1,
                              sheetId: 1,
                              pageIndex: 0,
                              settings: value,
                              isLeader: true,
                              myId: 'me',
                              onAction: actions.add,
                              interactionBlocked: blocked,
                              onStylusSeen: () => settings.value = settings.value.copyWith(stylusOnly: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pinch(
    WidgetTester tester, {
    Offset center = const Offset(200, 300),
    double start = 40,
    double end = 80,
  }) async {
    final a = await tester.startGesture(center - Offset(start, 0), pointer: 11);
    await tester.pump();
    final b = await tester.startGesture(center + Offset(start, 0), pointer: 12);
    await tester.pump();
    await a.moveTo(center - Offset(end, 0));
    await b.moveTo(center + Offset(end, 0));
    await tester.pump();
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
  }

  testWidgets('a pinch in pen mode zooms paper and ink together without saving a mark', (tester) async {
    await mount(tester);
    await pinch(tester);
    expect(find.text('200%'), findsOneWidget);
    expect(ink.added, isEmpty);
    expect(actions, isEmpty);
    expect(turns, isEmpty);
    expect(tester.getRect(find.byKey(const ValueKey('paper'))), const Rect.fromLTWH(-200, -300, 800, 1200));
    expect(tester.getRect(find.byType(AnnotationLayer)), tester.getRect(find.byKey(const ValueKey('paper'))));
  });

  testWidgets('drawing zoomed saves original page fractions and proportional pen width', (tester) async {
    await mount(tester);
    await pinch(tester);
    final stroke = await tester.startGesture(const Offset(100, 120));
    await stroke.moveTo(const Offset(180, 240));
    await stroke.up();
    await tester.pumpAndSettle();
    final saved = ink.added.single;
    expect(saved.points.first.x, closeTo(.375, 1e-6));
    expect(saved.points.first.y, closeTo(.35, 1e-6));
    expect(saved.points.last.x, closeTo(.475, 1e-6));
    expect(saved.points.last.y, closeTo(.45, 1e-6));
    expect(saved.width, .004);
    await tester.tap(find.text('200%'));
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);
    expect(tester.getRect(find.byType(AnnotationLayer)), const Rect.fromLTWH(0, 0, 400, 600));
    expect(ink.added.single, same(saved), reason: 'fitting the page never rewrites ink');
    expect(turns, isEmpty);
  });

  testWidgets('two-finger pan in eraser mode cancels provisional erasures', (tester) async {
    await mount(tester);
    final stroke = await tester.startGesture(const Offset(160, 300));
    await stroke.moveTo(const Offset(240, 300));
    await stroke.up();
    await tester.pumpAndSettle();
    settings.value = settings.value.copyWith(mode: InkMode.eraser);
    await tester.pumpAndSettle();
    await pinch(tester); // first finger lands on the existing stroke
    expect(ink.erased, isEmpty);
    expect(ink.added.length, 1);
    expect(actions.whereType<Erased>(), isEmpty);
    // Now erase intentionally at the zoomed position and commit once.
    final eraser = await tester.startGesture(const Offset(200, 300));
    expect(ink.erased, isEmpty);
    await eraser.up();
    await tester.pumpAndSettle();
    expect(ink.erased, [ink.added.single.id]);
    expect(actions.whereType<Erased>().length, 1);
  });

  testWidgets('a second finger in the page margin still cancels provisional ink', (tester) async {
    await mount(tester, aspectRatio: .5);
    final first = await tester.startGesture(const Offset(200, 300), pointer: 1);
    await first.moveBy(const Offset(10, 0));
    final margin = await tester.startGesture(const Offset(20, 300), pointer: 2);
    await tester.pump();
    await first.moveTo(const Offset(260, 300));
    await margin.moveTo(const Offset(5, 300));
    await tester.pump();
    await first.up();
    await margin.up();
    await tester.pumpAndSettle();
    expect(ink.added, isEmpty);
    expect(turns, isEmpty);
  });

  testWidgets('pan then draw uses the new paper origin', (tester) async {
    await mount(tester, mode: InkMode.view);
    await pinch(tester);
    await tester.dragFrom(const Offset(200, 300), const Offset(30, 40));
    settings.value = settings.value.copyWith(mode: InkMode.pen);
    await tester.pumpAndSettle();
    final stroke = await tester.startGesture(const Offset(100, 120));
    await stroke.moveTo(const Offset(180, 240));
    await stroke.up();
    await tester.pumpAndSettle();
    expect(ink.added.single.points.first.x, closeTo(.3375, 1e-6));
    expect(ink.added.single.points.first.y, closeTo(190 / 600, 1e-6));
    expect(turns, isEmpty);
  });

  testWidgets('resizing retains magnification and cancels a stroke with stale hit-test coordinates', (tester) async {
    await mount(tester);
    await pinch(tester);
    final stroke = await tester.startGesture(const Offset(100, 120));
    await stroke.moveBy(const Offset(20, 0));
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    await stroke.up();
    await tester.pumpAndSettle();
    expect(find.text('200%'), findsOneWidget);
    expect(ink.added, isEmpty);
    expect(tester.getRect(find.byType(AnnotationLayer)), tester.getRect(find.byKey(const ValueKey('paper'))));
  });

  testWidgets('a pen takes over a palm that landed first without saving the palm mark', (tester) async {
    await mount(tester);
    final palm = await tester.startGesture(const Offset(200, 360), pointer: 1);
    await palm.moveBy(const Offset(20, 0));
    final pen = await tester.startGesture(const Offset(180, 300), pointer: 2, kind: PointerDeviceKind.stylus);
    await tester.pump();
    await pen.moveTo(const Offset(220, 300));
    await pen.up();
    await palm.up();
    await tester.pumpAndSettle();
    expect(ink.added.length, 1);
    expect(ink.added.single.points.first.x, closeTo(.45, 1e-6));
    expect(ink.added.single.points.first.y, closeTo(.5, 1e-6));
  });

  testWidgets('unzoomed swipes turn, zoomed drags pan, and fitting restores page turns', (tester) async {
    await mount(tester, mode: InkMode.view);
    await tester.dragFrom(const Offset(250, 300), const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(turns, [1]);
    await pinch(tester);
    final before = tester.getRect(find.byKey(const ValueKey('paper')));
    await tester.dragFrom(const Offset(200, 300), const Offset(30, 40));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey('paper'))).topLeft, before.topLeft + const Offset(30, 40));
    expect(turns, [1]);
    await tester.tap(find.text('200%'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(50, 300));
    expect(turns, [1, -1]);
  });

  testWidgets('a resting hand cannot move the paper or leave ink during a stylus stroke', (tester) async {
    await mount(tester);
    await pinch(tester);
    final before = tester.getRect(find.byKey(const ValueKey('paper')));
    final pen = await tester.startGesture(const Offset(180, 300), pointer: 10, kind: PointerDeviceKind.stylus);
    await tester.pump();
    final a = await tester.startGesture(const Offset(160, 380), pointer: 11);
    final b = await tester.startGesture(const Offset(240, 380), pointer: 12);
    await a.moveBy(const Offset(-50, 20));
    await b.moveBy(const Offset(50, 20));
    await pen.moveBy(const Offset(40, 0));
    await tester.pump();
    await pen.up();
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey('paper'))), before);
    expect(ink.added.length, 1);
    expect(turns, isEmpty);
  });
}
