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
import 'package:praiseteam/features/annotations/annotation_layer.dart';
import 'package:praiseteam/main.dart' as app;

import 'flow_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('capture native store screens with fictional team data', (
    tester,
  ) async {
    expect(Env.demo, isFalse);
    expect(Env.devLogin, isTrue);
    expect(Env.supabaseUrl, 'http://10.0.2.2:54321');
    final fixture = jsonDecode(
      (await http.get(Uri.parse('http://10.0.2.2:3939/fixture'))).body,
    ) as Map<String, dynamic>;
    final team = fixture['team'], service = fixture['service'];
    await app.main();
    final f = MobileFlow(tester, binding);
    await f.see('이메일');
    await f.enter('이메일', fixture['actors'][0]['email'] as String);
    await f.enter('비밀번호', fixture['password'] as String);
    await f.tapText('로그인');
    await f.see('할 일');
    final router = ProviderScope.containerOf(
      tester.element(find.byType(PraiseTeamApp)),
    ).read(routerProvider);
    router.go('/t/$team/sessions/$service');
    await f.see('라이브하기');
    await f.until(
      () => tester
          .widgetList<RawImage>(find.byType(RawImage))
          .any((w) => w.image != null),
      reason: 'setlist artwork',
    );
    await f.shot('01-service');
    router.go('/t/$team/songs');
    await f.see('In Jesus Name');
    await f.settle(1000);
    await f.shot('02-songs');
    router.go('/t/$team/rotation');
    await f.see('로테이션');
    await f.tapText('표');
    await f.shot('03-rota');
    router.go('/t/$team/sessions/$service');
    await f.see('라이브하기');
    await f.tapText('라이브하기');
    await f.see('필기');
    await f.until(
      () => tester
          .widgetList<PdfPageView>(find.byType(PdfPageView))
          .any((w) => w.document != null),
      reason: 'native PDF',
    );
    await f.shot('04-live');
    await f.tapText('필기');
    await f.see('나만 보기');
    final rect = tester.getRect(find.byType(AnnotationLayer).first);
    final center = Offset(
      rect.left + rect.width * .36,
      rect.top + rect.height * .2,
    );
    final gesture = await tester.startGesture(center + const Offset(23, 0));
    for (var i = 1; i <= 32; i++) {
      await gesture.moveTo(
        center +
            Offset(
              23 * math.cos(i * math.pi / 16),
              12 * math.sin(i * math.pi / 16),
            ),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await f.shot('05-notes');
    router.go('/t/$team/chat/${fixture['channel']}');
    await f.contains('다음 팀 모임');
    await f.shot('06-chat');
    router.go('/t/$team/home');
    await f.see('할 일');
    await f.shot('07-home');
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
