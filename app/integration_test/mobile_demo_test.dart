import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  testWidgets(
    'native sample team: services, songs, rota, PDF ink, chat and settings',
    (tester) async {
      expect(
        Env.demo,
        isTrue,
        reason: 'This suite is for the isolated sample build.',
      );
      await app.main();
      final flow = MobileFlow(tester, binding);
      await flow.see('할 일');
      await flow.shot('01-home');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PraiseTeamApp)),
      );
      final router = container.read(routerProvider);

      router.go('/t/1/sessions/107');
      await flow.see('라이브하기');
      await flow.shot('02-service-setlist');
      await flow.tapText('In Jesus Name');
      await flow.see('송폼');
      await flow.enter('BPM', '108');
      await flow.enter('메모', '마지막 후렴 두 번');
      await flow.tapText('저장');
      await flow.contains('108 BPM');
      await flow.tapText('바뀐 내용 공지하기');
      await flow.tapText('바뀐 내용 공지하기');
      await flow.shot('03-published-setlist');

      router.go('/t/1/songs');
      await flow.see('In Jesus Name');
      await flow.shot('04-song-library');
      await flow.tapText('In Jesus Name');
      await flow.see('공유 영상 편곡');
      await flow.reveal(find.text('팀 편곡'));
      await flow.shot('05-song-versions');

      router.go('/t/1/rotation');
      await flow.see('로테이션');
      await flow.tapText('표');
      await flow.shot('06-rotation-table');
      await flow.tapText('불가능 날짜');
      await flow.contains('가족 일정');
      await flow.shot('07-blockouts');

      router.go('/t/1/sessions/107');
      await flow.see('라이브하기');
      await flow.tapText('라이브하기');
      await flow.see('필기');
      await flow.contains('1 / 5');
      await flow.shot('08-live-stand');
      await flow.tapText('필기');
      await flow.see('나만 보기');
      await flow.until(
        () => tester
            .widgetList<PdfPageView>(find.byType(PdfPageView))
            .any((page) => page.document != null),
        reason: 'native PDF is rendered',
      );
      final center = tester.getRect(find.byType(AnnotationLayer).first).center;
      Future<void> circle(Offset origin) async {
        final gesture = await tester.startGesture(origin + const Offset(25, 0));
        for (var i = 1; i <= 32; i++) {
          await gesture.moveTo(
            origin +
                Offset(
                  25 * math.cos(i * math.pi / 16),
                  13 * math.sin(i * math.pi / 16),
                ),
          );
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await flow.settle();
      }

      await circle(center);
      await flow.tapText('팀 공용');
      await circle(center + const Offset(0, 40));
      await flow.shot('09-score-annotations');
      await flow.tapText('완료');

      router.go('/t/1/chat');
      await flow.see('전체');
      await flow.shot('10-channels');
      await flow.tapText('전체');
      await flow.contains('다음 팀 모임');
      await flow.enter('메시지', '시뮬레이터에서 보낸 메시지입니다.');
      await flow.tooltip('보내기');
      await flow.see('시뮬레이터에서 보낸 메시지입니다.');
      await flow.tapText('토요일 점심');
      await flow.shot('11-chat-poll');

      router.go('/t/1/settings');
      await flow.see('프로필');
      await flow.shot('12-settings');
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
