import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:praiseteam/app/app.dart';
import 'package:praiseteam/app/router.dart';
import 'package:praiseteam/core/env.dart';
import 'package:praiseteam/features/songs/sheet_download_button.dart';
import 'package:praiseteam/features/songs/songs_providers.dart';
import 'package:praiseteam/main.dart' as app;

import 'flow_helpers.dart';

// Run with e2e/android_download.py on the disposable QA emulator. The host
// handles the real system dialog and checks the saved file's SHA-256.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android downloads original PDF and recovers from save cancellation',
    (tester) async {
      expect(Env.demo, isTrue);
      await app.main();
      final flow = MobileFlow(tester, binding);
      await flow.see('할 일');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PraiseTeamApp)),
      );
      container.read(routerProvider).go('/t/1/songs/1');
      await flow.see('공유 영상 편곡');
      final target = find.byType(SheetDownloadButton).first;
      await flow.reveal(target);
      final button = tester.widget<SheetDownloadButton>(target);
      final name = sheetDownloadFilename(
        button.songTitle,
        button.versionTitle,
        button.sheet,
      );
      final bytes = await container.read(
        sheetBytesProvider(button.sheet.storagePath).future,
      );
      debugPrint(
        'NATIVE_SHEET_FILE ${jsonEncode({'name': name, 'sha256': sha256.convert(bytes).toString()})}',
      );
      final icon = find
          .descendant(of: target, matching: find.byType(IconButton))
          .first;
      for (var attempt = 0; attempt < 3; attempt++) {
        debugPrint(
          attempt == 0
              ? 'NATIVE_SHEET_SAVE_READY'
              : 'NATIVE_SHEET_CANCEL_READY_$attempt',
        );
        await flow.tap(icon);
        await flow.until(
          () => tester.widget<IconButton>(icon).onPressed != null,
          reason: 'system save dialog completed',
          seconds: 90,
        );
        expect(find.byType(SnackBar), findsNothing);
      }
      await flow.shot('song-detail-after-save');
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
