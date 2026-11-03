import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:praiseteam/app/app.dart';
import 'package:praiseteam/app/router.dart';
import 'package:praiseteam/core/env.dart';
import 'package:praiseteam/core/providers.dart';
import 'package:praiseteam/features/annotations/annotation_layer.dart';
import 'package:praiseteam/features/annotations/stroke_outbox.dart';
import 'package:praiseteam/features/offline/prefetch.dart';
import 'package:praiseteam/features/songs/song_artwork.dart';
import 'package:praiseteam/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'flow_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android picker, thumbnails and durable offline notes', (
    tester,
  ) async {
    expect(Env.demo, isFalse);
    expect(Env.devLogin, isTrue);
    expect(Env.supabaseUrl, 'http://10.0.2.2:3940');
    final control = Uri.parse('http://10.0.2.2:3939/fixture');
    final fixture =
        jsonDecode((await http.get(control)).body) as Map<String, dynamic>;
    final team = fixture['team'] as int, service = fixture['service'] as int;
    try {
      await app.main();
      final flow = MobileFlow(tester, binding);
      await flow.see('이메일');
      await flow.enter('이메일', fixture['actors'][0]['email'] as String);
      await flow.enter('비밀번호', fixture['password'] as String);
      await flow.tapText('로그인');
      await flow.see('할 일');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PraiseTeamApp)),
      );
      final router = container.read(routerProvider),
          db = Supabase.instance.client;
      final ready = await container.read(offlinePrefetchProvider.future);
      expect(
        ready,
        greaterThan(0),
        reason: 'Real native database has prefetched services.',
      );

      router.go('/t/$team/songs');
      await flow.see('In Jesus Name');
      final artwork = tester
          .widgetList<SongArtwork>(find.byType(SongArtwork))
          .firstWhere((w) => w.url != null);
      final thumbnail = await http.get(Uri.parse(artwork.url!));
      expect(
        thumbnail.statusCode,
        200,
        reason: 'YouTube thumbnail is reachable from the emulator.',
      );
      await flow.until(
        () => tester
            .widgetList<RawImage>(find.byType(RawImage))
            .any((w) => w.image != null),
        reason: 'decoded network thumbnail',
        seconds: 30,
      );
      await flow.shot('41-native-thumbnails');
      await flow.tapText('In Jesus Name');
      await flow.see('공유 영상 편곡');
      // The host selects only e2e/sheet.png in the real Android DocumentsUI.
      debugPrint('NATIVE_PICKER_READY');
      await flow.tapText('악보 올리기');
      await flow.see('1쪽', seconds: 90);
      await flow.enter('악보 이름 (예: 코드, 드럼)', 'Android file picker chart');
      await flow.tap(find.widgetWithText(FilledButton, '악보 올리기'));
      await flow.see('Android file picker chart');
      await flow.tapText('Android file picker chart');
      await flow.until(
        () => find.byType(PdfViewer).evaluate().isNotEmpty,
        reason: 'picked image converted to PDF and opened',
      );
      await flow.shot('42-picked-image-as-pdf');
      expect(
        await db
            .from('sheets')
            .select('id')
            .eq('team_id', team)
            .eq('label', 'Android file picker chart'),
        isNotEmpty,
      );

      router.go('/t/$team/home');
      await flow.see('할 일');
      expect(
        (await http.post(control.replace(path: '/offline'))).statusCode,
        200,
      );
      // A real failed HTTP request sets the app's reachability; no provider overrides.
      try {
        await db.from('teams').select('id').eq('id', team);
      } catch (_) {}
      await flow.until(
        () => !container.read(reachabilityProvider).online,
        reason: 'backend connection lost',
      );
      router.go('/t/$team/sessions/$service');
      await flow.see('악보 보기');
      await flow.tapText('악보 보기');
      await flow.see('필기');
      await flow.tapText('필기');
      await flow.see('나만 보기');
      await flow.until(
        () => tester
            .widgetList<PdfPageView>(find.byType(PdfPageView))
            .any((w) => w.document != null),
        reason: 'PDF loaded from native persistent cache while offline',
      );
      final center = tester.getRect(find.byType(AnnotationLayer).first).center;
      final gesture = await tester.startGesture(center + const Offset(25, 0));
      for (var i = 1; i <= 32; i++) {
        await gesture.moveTo(
          center +
              Offset(
                25 * math.cos(i * math.pi / 16),
                13 * math.sin(i * math.pi / 16),
              ),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await flow.until(
        () => container.read(strokeOutboxProvider) > 0,
        reason: 'offline annotation queued',
      );
      final pending = await container
          .read(offlineStoreProvider)
          .pending(db.auth.currentUser!.id);
      expect(
        pending,
        hasLength(1),
        reason: 'Ink is persisted to native SQLite, not only memory.',
      );
      final strokeId =
          (jsonDecode(pending.single.payload) as Map)['id'] as String;
      await flow.shot('43-offline-score-and-ink');
      expect(
        (await http.post(control.replace(path: '/online'))).statusCode,
        200,
      );
      await flow.until(
        () =>
            container.read(reachabilityProvider).online &&
            container.read(strokeOutboxProvider) == 0,
        reason: 'automatic reconnect and outbox drain',
        seconds: 60,
      );
      expect(
        await container
            .read(offlineStoreProvider)
            .pending(db.auth.currentUser!.id),
        isEmpty,
      );
      expect(
        await db.from('strokes').select('id').eq('id', strokeId),
        hasLength(1),
      );
      await flow.shot('44-offline-ink-synced');
      expect(tester.takeException(), isNull);
    } finally {
      await http.post(control.replace(path: '/online'));
    }
  }, timeout: const Timeout(Duration(minutes: 8)));
}
