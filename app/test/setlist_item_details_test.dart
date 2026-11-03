import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:praiseteam/app/theme.dart';
import 'package:praiseteam/features/sessions/models.dart';
import 'package:praiseteam/features/sessions/setlist_item_details.dart';
import 'package:praiseteam/features/songs/models.dart';
import 'package:praiseteam/l10n/app_localizations.dart';

const reference = SongLink(id: 1, versionId: 11, label: '이번 편곡 영상', url: 'https://youtu.be/aqz-KE-bpKQ?t=42');
const otherReference = SongLink(id: 2, versionId: 12, label: '다른 편곡 영상', url: 'https://example.com/other');
const rawForm = '  intro → v1, Chorus x2\n후렴 한 번 더 / ending  ';
const entry = SetlistItem(
  id: 5,
  sessionId: 3,
  position: 1,
  songId: 1,
  versionId: 11,
  key: 'A',
  bpm: 108,
  songForm: rawForm,
  notes: '마지막 후렴 두 번',
  song: SetlistSong(
    title: '주일 찬양',
    versions: [
      SetlistVersion(links: [otherReference]),
    ],
  ),
  version: SetlistVersion(name: '이번 편곡', defaultKey: 'G', bpm: 72, links: [reference]),
);

void main() {
  Future<void> open(
    WidgetTester tester, {
    bool canEdit = false,
    SetlistItem item = entry,
    ValueChanged<SetlistItemAction?>? onAction,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final action = await showSetlistItemDetails(context, item: item, canEdit: canEdit);
                onAction?.call(action);
              },
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  testWidgets('members see service-specific details and only the selected arrangement links', (tester) async {
    await open(tester, onAction: (_) {});
    expect(find.text('선택한 버전: 이번 편곡'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('108 BPM'), findsOneWidget);
    expect(find.text('72 BPM'), findsNothing);
    expect(find.text(rawForm), findsOneWidget);
    expect(find.text('마지막 후렴 두 번'), findsOneWidget);
    expect(find.text(reference.label!), findsOneWidget);
    expect(find.text(otherReference.label!), findsNothing);
    expect(find.text('콘티 수정'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('곡 전체 정보'), findsOneWidget);
  });

  testWidgets('leaders read first and explicitly choose to edit', (tester) async {
    SetlistItemAction? action;
    await open(tester, canEdit: true, onAction: (value) => action = value);
    expect(find.byType(TextField), findsNothing);
    await tester.ensureVisible(find.text('콘티 수정'));
    await tester.tap(find.text('콘티 수정'));
    await tester.pumpAndSettle();
    expect(action, SetlistItemAction.edit);
  });

  testWidgets('missing references do not silently play another arrangement', (tester) async {
    await open(
      tester,
      item: entry.copyWith(version: entry.version!.copyWith(links: [])),
      onAction: (_) {},
    );
    expect(find.textContaining('이 버전에는 참고 링크가 없어요'), findsOneWidget);
    expect(find.text(otherReference.label!), findsNothing);
    expect(find.text('곡 전체 정보'), findsOneWidget);
  });

  testWidgets('references launch the exact saved URL and report launch failures', (tester) async {
    String? launched;
    var success = true;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'launch') {
        launched = (call.arguments as Map)['url'] as String;
        return success;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    await open(tester, onAction: (_) {});
    await tester.tap(find.text(reference.label!));
    await tester.pumpAndSettle();
    expect(launched, reference.url);
    success = false;
    await tester.tap(find.text(reference.label!));
    await tester.pumpAndSettle();
    expect(find.text('링크를 열지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
  });

  testWidgets('compact phones can scroll to navigation actions', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SetlistItemAction? action;
    await open(
      tester,
      item: entry.copyWith(notes: List.filled(20, '예배 전달 사항').join('\n')),
      onAction: (v) => action = v,
    );
    await tester.ensureVisible(find.text('악보 보기'));
    await tester.tap(find.text('악보 보기'));
    await tester.pumpAndSettle();
    expect(action, SetlistItemAction.viewSheet);
    expect(tester.takeException(), isNull);
  });
}
