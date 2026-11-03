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
import 'package:praiseteam/core/music_widgets.dart';
import 'package:praiseteam/features/annotations/annotation_layer.dart';
import 'package:praiseteam/features/chat/chat_repository.dart';
import 'package:praiseteam/features/live/live_clock.dart';
import 'package:praiseteam/features/live/live_session.dart';
import 'package:praiseteam/features/songs/sheet_upload.dart';
import 'package:praiseteam/features/songs/songs_providers.dart';
import 'package:praiseteam/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'flow_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native workflows with real isolated local accounts', (
    tester,
  ) async {
    expect(Env.demo, isFalse);
    expect(Env.devLogin, isTrue);
    final backend = Uri.parse(Env.supabaseUrl);
    expect(['10.0.2.2', '127.0.0.1', 'localhost'], contains(backend.host));
    expect(backend.port, 54321, reason: 'Never mutate a hosted backend.');
    final fixtureUrl = Uri.parse(
      const String.fromEnvironment(
        'NATIVE_FIXTURE_URL',
        defaultValue: 'http://10.0.2.2:3939/fixture',
      ),
    );
    final fixture =
        jsonDecode((await http.get(fixtureUrl)).body) as Map<String, dynamic>;
    final team = fixture['team'] as int, service = fixture['service'] as int;
    final actors = (fixture['actors'] as List).cast<Map<String, dynamic>>();
    final peer = SupabaseClient(
      Env.supabaseUrl,
      Env.supabasePublishableKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await peer.auth.signInWithPassword(
      email: actors[1]['email'] as String,
      password: fixture['password'] as String,
    );
    LiveSession? livePeer;
    try {
      await app.main();
      final flow = MobileFlow(tester, binding);
      await flow.see('이메일');
      await flow.shot('20-native-login');
      await flow.enter('이메일', fixture['onboardingEmail'] as String);
      await flow.enter('비밀번호', fixture['onboardingPassword'] as String);
      await flow.tapText('계정 만들기');
      await flow.see('팀 이름');
      await flow.enter('팀 이름', fixture['onboardingTeam'] as String);
      await flow.tapText('만들기');
      await flow.see('할 일');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PraiseTeamApp)),
      );
      final router = container.read(routerProvider),
          db = Supabase.instance.client;
      final onboardingId = db.auth.currentUser!.id;
      final ownTeam = await db
          .from('teams')
          .select('id,invite_code')
          .eq('name', fixture['onboardingTeam'])
          .single();
      final ownTeamId = ownTeam['id'] as int;
      await flow.shot('21-created-team');
      await peer.rpc(
        'join_team',
        params: {'p_invite_code': ownTeam['invite_code']},
      );
      expect(peer.auth.currentUser!.id, actors[1]['id']);
      expect(
        (await db
            .from('team_members')
            .select('status')
            .eq('team_id', ownTeamId)
            .eq('user_id', actors[1]['id'])
            .single())['status'],
        'pending',
      );
      router.go('/t/$ownTeamId/team');
      await flow.see('파트 정하기');
      await tester.drag(find.byType(ListView).last, const Offset(0, 500));
      await flow.see('승인');
      await flow.tapText('승인');
      expect(
        (await db
            .from('team_members')
            .select('status')
            .eq('team_id', ownTeamId)
            .eq('user_id', actors[1]['id'])
            .single())['status'],
        'active',
      );
      await flow.shot('22-approved-member');
      router.go('/t/$ownTeamId/settings');
      await flow.see('프로필');
      await flow.tapText('계정 삭제');
      await flow.contains('유일한 관리자');
      await flow.shot('23-last-owner-protection');
      await flow.tapText('취소');
      router.go('/t/$ownTeamId/team');
      await flow.see('김하늘');
      await flow.tapText('김하늘');
      await flow.tapText('관리자');
      expect(
        (await db
            .from('team_members')
            .select('role')
            .eq('team_id', ownTeamId)
            .eq('user_id', actors[1]['id'])
            .single())['role'],
        'owner',
      );
      router.go('/t/$ownTeamId/settings');
      await flow.see('프로필');
      await flow.tapText('계정 삭제');
      await flow.contains('복구할 수 없다는');
      await flow.tap(find.byType(CheckboxListTile));
      await flow.tap(find.widgetWithText(FilledButton, '계정 삭제'));
      await flow.see('이메일');
      expect(db.auth.currentSession, isNull);
      expect(
        await peer.from('profiles').select('id').eq('id', onboardingId),
        isEmpty,
      );
      await flow.shot('24-account-deleted');

      await flow.enter('이메일', actors[0]['email'] as String);
      await flow.enter('비밀번호', fixture['password'] as String);
      await flow.tapText('로그인');
      await flow.see('할 일');
      await flow.shot('25-real-backend-home');
      router.go('/t/$team/songs');
      await flow.see('곡 추가');
      await flow.tapText('곡 추가');
      await flow.enter('곡 이름', 'Native QA Hymn');
      await flow.enter('가수·버전', 'Native acoustic');
      await flow.enter('BPM', '92');
      await flow.tap(find.byType(KeyField));
      await flow.tapText('G');
      await flow.tapText('저장');
      await flow.see('버전 추가');
      final song = await db
          .from('songs')
          .select('id')
          .eq('team_id', team)
          .eq('title', 'Native QA Hymn')
          .single();
      final songId = song['id'] as int;
      final firstVersion = await db
          .from('song_versions')
          .select('id')
          .eq('song_id', songId)
          .single();
      final versionId = firstVersion['id'] as int;
      await flow.tapText('버전 추가');
      await flow.enter('가수·버전', 'Native full band');
      await flow.enter('BPM', '105');
      await flow.tapText('저장');
      await flow.see('Native full band');
      final reference = await db
          .from('song_links')
          .select('url')
          .eq('team_id', team)
          .limit(1)
          .single();
      await flow.tap(find.text('링크 추가').first);
      await flow.enter('주소 (https://...)', reference['url'] as String);
      await flow.enter('이름 (선택)', '참고 영상');
      await flow.tapText('저장');
      await flow.see('참고 영상');
      expect(
        (await db.from('song_versions').select('id').eq('song_id', songId))
            .length,
        2,
      );
      await flow.shot('26-created-song-versions');

      // The native PDF decoder and real Storage upload run on the device.
      // The OS document picker is checked separately on the emulator.
      final sourceSheet = await db
          .from('sheets')
          .select('storage_path')
          .eq('team_id', team)
          .limit(1)
          .single();
      final bytes = await db.storage
          .from('sheets')
          .download(sourceSheet['storage_path'] as String);
      final sizes = await readPageSizes(bytes);
      expect(sizes, isNotEmpty);
      await container
          .read(songsRepositoryProvider)
          .uploadSheet(
            teamId: team,
            versionId: versionId,
            pdf: bytes,
            pageSizes: sizes,
            key: 'G',
            label: 'Native QA score',
          );
      router.go('/t/$team/songs');
      await flow.see('곡 추가');
      router.go('/t/$team/songs/$songId');
      await flow.see('Native QA score');
      await flow.tapText('Native QA score');
      await flow.until(
        () => find.byType(PdfViewer).evaluate().isNotEmpty,
        reason: 'native PDF preview',
      );
      await flow.settle(1000);
      await flow.shot('27-native-pdf-preview');

      router.go('/t/$team/sessions');
      await flow.see('로테이션');
      await flow.tapText('예배 추가');
      await flow.enter('예배 이름', 'Native QA Worship');
      await flow.enter('장소', 'QA Hall');
      await flow.tapText('템플릿으로 저장');
      await flow.tapText('저장');
      await flow.see('곡 추가');
      final created = await db
          .from('sessions')
          .select('id')
          .eq('team_id', team)
          .eq('title', 'Native QA Worship')
          .single();
      final createdService = created['id'] as int;
      await flow.tapText('곡 추가');
      await flow.tapText('Native QA Hymn');
      await flow.tap(find.textContaining('Native acoustic'));
      await flow.contains('92 BPM');
      await flow.tapText('Native QA Hymn');
      await flow.see('참고 링크');
      await flow.tapText('콘티 수정');
      await flow.see('송폼');
      await flow.enter('BPM', '100');
      const rawSongForm = ' intro  → v1, C x2\n후렴 한 번 더 / ending ';
      await flow.enter('송폼', rawSongForm);
      await flow.enter('메모', '마지막 후렴 두 번');
      await flow.tapText('저장');
      await flow.tapText('콘티 공지하기');
      await flow.tapText('콘티 공지하기');
      await flow.see('공지됨');
      final item = await db
          .from('setlist_items')
          .select('version_id,bpm,song_form')
          .eq('session_id', createdService)
          .single();
      expect(item['version_id'], versionId);
      expect(item['bpm'], 100);
      expect(item['song_form'], rawSongForm);
      expect(
        (await db
                .from('session_templates')
                .select('id')
                .eq('team_id', team)
                .eq('title', 'Native QA Worship'))
            .length,
        1,
      );
      await flow.shot('28-created-published-service');

      router.go('/t/$team/rotation');
      await flow.see('로테이션');
      await flow.tapText('표');
      await flow.shot('29-native-rota-table');
      await flow.tooltip('메뉴 표시');
      await flow.tapText('자동 배정');
      await flow.contains('자리를 초안으로');
      await flow.shot('30-auto-assignment');
      await flow.tap(find.textContaining('보내기 ('));
      await flow.tap(find.textContaining('보내기 ('));
      expect(
        await db
            .from('assignments')
            .select('id')
            .eq('team_id', team)
            .eq('status', 'draft'),
        isEmpty,
      );
      await flow.tapText('불가능 날짜');
      await flow.contains('가족 일정');
      await flow.shot('31-native-blockouts');
      router.go('/t/$team/home');
      await flow.see('할 일');
      await flow.tapText('수락');
      await flow.tap(find.text('참석').first);
      await flow.shot('32-rota-and-rehearsal-response');

      final items = await db
          .from('setlist_items')
          .select('id')
          .eq('session_id', service)
          .order('position', ascending: true);
      StandPosition? peerPosition;
      livePeer = LiveSession(
        db: peer,
        sessionId: service,
        me: actors[1]['id'] as String,
        name: 'Native Peer',
        myPartIds: {},
        onFollow: (position) => peerPosition = position,
      )..join();
      await flow.until(
        () => livePeer!.joined,
        reason: 'authenticated realtime peer',
      );
      router.go('/t/$team/sessions/$service');
      await flow.see('라이브하기');
      await flow.tapText('라이브하기');
      await flow.contains('2명 함께');
      await flow.until(
        () => livePeer!.participants == 2,
        reason: 'both live clients see each other',
      );
      await tester.drag(find.byType(PageView), const Offset(-330, 0));
      await flow.contains('2 / 5');
      await flow.until(
        () => peerPosition?.pageIndex == 1,
        reason: 'peer follows native page swipe',
      );
      await livePeer.turned(
        StandPosition(itemId: items.first['id'] as int, pageIndex: 0),
      );
      await flow.contains('1 / 5');
      await livePeer.turned(
        StandPosition(itemId: items.first['id'] as int, pageIndex: 1),
      );
      await flow.contains('2 / 5');
      await flow.shot('33-remote-page-follow');
      await livePeer.sendCue('한 번 더');
      await flow.see('Native Peer');
      await flow.shot('34-remote-live-cue');
      await flow.tap(find.byType(Switch));
      await livePeer.turned(
        StandPosition(itemId: items[1]['id'] as int, pageIndex: 0),
      );
      await flow.settle(500);
      expect(find.textContaining('2 / 5'), findsWidgets);
      await flow.tap(find.byType(Switch));
      await flow.contains('3 / 5');
      peerPosition = null;
      await tester.drag(find.byType(PageView), const Offset(-330, 0));
      await flow.until(
        () => peerPosition != null,
        reason: 'native swipe broadcast to peer',
      );
      await flow.shot('35-live-follow-rejoined');
      await livePeer.leave();
      livePeer = null;

      router.go('/t/$team/sessions/$service');
      await flow.see('라이브하기');
      await flow.tapText('악보 보기');
      await flow.see('필기');
      await flow.tapText('필기');
      await flow.see('나만 보기');
      await flow.until(
        () => tester
            .widgetList<PdfPageView>(find.byType(PdfPageView))
            .any((w) => w.document != null),
        reason: 'PDF rendered before drawing',
      );
      final pageRect = tester.getRect(find.byType(AnnotationLayer).first);
      Future<void> circle(Offset center) async {
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
        await flow.settle(900);
      }

      await circle(pageRect.center);
      final mine = db.auth.currentUser!.id;
      final private = await db
          .from('strokes')
          .select('id')
          .eq('session_id', service)
          .eq('owner_id', mine)
          .eq('visibility', 'private');
      expect(private, isNotEmpty);
      expect(
        await peer.from('strokes').select('id').eq('id', private.last['id']),
        isEmpty,
      );
      await flow.tapText('팀 공용');
      await circle(pageRect.center + const Offset(0, 45));
      final shared = await db
          .from('strokes')
          .select('id')
          .eq('session_id', service)
          .eq('owner_id', mine)
          .eq('visibility', 'team');
      expect(shared, isNotEmpty);
      expect(
        await peer.from('strokes').select('id').eq('id', shared.last['id']),
        isNotEmpty,
      );
      await flow.shot('36-private-and-team-ink');
      await flow.tooltip('실행 취소');
      await flow.tooltip('다시 실행');
      await flow.tapText('완료');

      router.go('/t/$team/chat');
      await flow.see('전체');
      await flow.tapText('전체');
      await flow.contains('다음 팀 모임');
      await flow.enter('메시지', 'Native device message');
      await flow.tooltip('보내기');
      await flow.see('Native device message');
      expect(
        await peer
            .from('messages')
            .select('id')
            .eq('channel_id', fixture['channel'])
            .eq('body', 'Native device message'),
        isNotEmpty,
      );
      final peerChat = ChatRepository(peer);
      await peerChat.send(
        id: peerChat.newMessageId(),
        teamId: team,
        channelId: fixture['channel'] as int,
        body: 'Peer realtime reply',
      );
      await flow.see('Peer realtime reply');
      await flow.tooltip('투표 만들기');
      await flow.enter('질문', 'Native rehearsal poll');
      await flow.enter('선택지 1', 'Friday');
      await flow.enter('선택지 2', 'Saturday');
      await flow.tapText('만들기');
      await flow.see('Native rehearsal poll');
      await flow.tapText('Friday');
      await flow.shot('37-chat-realtime-and-poll');
      router.go('/t/$team/announcements');
      await flow.see('공지');
      await flow.tapText('공지 쓰기');
      await flow.enter('제목', 'Native preparation notice');
      await flow.enter('내용', '토요일 연습 때 최종 콘티를 확인해 주세요.');
      await flow.tapText('맨 위에 고정');
      await flow.tapText('저장');
      await flow.see('Native preparation notice');
      expect(
        await peer
            .from('announcements')
            .select('id')
            .eq('team_id', team)
            .eq('title', 'Native preparation notice'),
        isNotEmpty,
      );
      await flow.shot('38-pinned-announcement');
      router.go('/t/$team/settings');
      await flow.see('프로필');
      await flow.tapText('캘린더에 구독');
      await flow.see('복사');
      expect(await db.from('calendar_feeds').select('token'), isNotEmpty);
      await flow.tapText('복사');
      await flow.shot('39-native-settings');
      expect(tester.takeException(), isNull);
    } finally {
      await livePeer?.leave();
      await peer.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
