import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Drives the installed Flutter app, including its native plugins.
class MobileFlow {
  MobileFlow(this.tester, this.binding);
  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;
  bool _surfaceReady = false;

  Future<void> settle([int milliseconds = 500]) async {
    await tester.pump(Duration(milliseconds: milliseconds));
  }

  Future<void> until(
    bool Function() ready, {
    String reason = 'screen',
    int seconds = 25,
  }) async {
    // Complete a native route transition before inspecting text that may
    // also have existed on the outgoing screen.
    await tester.pump(const Duration(milliseconds: 500));
    final deadline = DateTime.now().add(Duration(seconds: seconds));
    while (!ready() && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    if (!ready()) {
      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data)
          .whereType<String>()
          .take(70);
      throw TestFailure(
        'Timed out waiting for $reason. Visible text: ${labels.join(' | ')}',
      );
    }
  }

  Future<void> see(String text, {int seconds = 25}) => until(
    () => find.text(text).evaluate().isNotEmpty,
    reason: text,
    seconds: seconds,
  );

  Future<void> contains(String text, {int seconds = 25}) => until(
    () => find.textContaining(text).evaluate().isNotEmpty,
    reason: text,
    seconds: seconds,
  );

  Finder field(String label) => find.byWidgetPredicate(
    (w) =>
        w is TextField &&
        (w.decoration?.labelText == label || w.decoration?.hintText == label),
    description: 'text field $label',
  );

  Future<void> reveal(Finder target) async {
    final notice = find.byType(SnackBar);
    if (notice.evaluate().isNotEmpty) {
      await tester.drag(notice.last, const Offset(0, 160));
      await settle(400);
    }
    await until(
      () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
      reason: 'screen data loaded',
    );
    // An item editor can leave its parent list scrolled below a toolbar.
    // Search from the top before scrolling down through lazy slivers.
    if (target.evaluate().isEmpty) {
      final scroll = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      if (scroll.evaluate().isNotEmpty) {
        for (var i = 0; i < 12; i++) {
          final state = tester.state<ScrollableState>(scroll.last);
          if (state.position.pixels <= state.position.minScrollExtent + 1) {
            break;
          }
          await tester.drag(scroll.last, const Offset(0, 500));
          await settle(200);
          if (target.evaluate().isNotEmpty) break;
        }
      }
    }
    for (var i = 0; target.evaluate().isEmpty && i < 8; i++) {
      final scroll = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      if (scroll.evaluate().isEmpty) break;
      await tester.drag(scroll.last, const Offset(0, -280));
      await settle(250);
    }
    if (target.evaluate().isEmpty) {
      await shot('failure');
      throw TestFailure('Control not found: $target');
    }
    await Scrollable.ensureVisible(tester.element(target.last), alignment: .5);
    await settle(150);
  }

  Future<void> tap(Finder target) async {
    await reveal(target);
    await tester.tap(target.last);
    await settle(350);
  }

  Future<void> tapText(String text) => tap(find.text(text));
  Future<void> tooltip(String text) => tap(find.byTooltip(text));

  Future<void> enter(String label, String value) async {
    final target = field(label);
    await reveal(target);
    await tester.enterText(target.last, value);
    // Dismiss the keyboard without submitting fields with onSubmitted
    // handlers (for example, creating a team).
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(250);
  }

  Future<void> shot(String name) async {
    await settle(350);
    if (Platform.isAndroid && !_surfaceReady) {
      await binding.convertFlutterSurfaceToImage();
      _surfaceReady = true;
      await settle(250);
    }
    await binding.takeScreenshot(name);
    debugPrint('NATIVE CHECKPOINT: $name');
  }
}
