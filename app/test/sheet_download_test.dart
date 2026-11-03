import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:praiseteam/features/songs/models.dart';
import 'package:praiseteam/features/songs/sheet_download_button.dart';
import 'package:praiseteam/features/songs/songs_providers.dart';
import 'package:praiseteam/l10n/app_localizations.dart';

final sheet = Sheet(
  id: 1,
  key: 'G',
  label: '밴드 악보',
  storagePath: '1/private-id.pdf',
  pageCount: 2,
  pageSizes: const [],
  sizeBytes: 8,
  createdAt: DateTime(2026),
);
final pdf = Uint8List.fromList([37, 80, 68, 70, 45, 0, 128, 255]);

class SaveDialog extends FilePickerPlatform {
  final calls = <({String name, Uint8List bytes, String mime})>[];
  Completer<Uri?>? pending;
  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    calls.add((name: fileName, bytes: bytes, mime: mimeType));
    return pending == null ? null : await pending!.future;
  }
}

void main() {
  late FilePickerPlatform previous;
  late SaveDialog saver;
  var rowTaps = 0;
  setUp(() {
    rowTaps = 0;
    previous = FilePickerPlatform.instance;
    FilePickerPlatform.instance = saver = SaveDialog();
  });
  tearDown(() => FilePickerPlatform.instance = previous);

  Future<void> open(WidgetTester tester, Future<Uint8List> Function() read) => tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [sheetBytesProvider(sheet.storagePath).overrideWith((ref) => read())],
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListTile(
            onTap: () => rowTaps++,
            trailing: SheetDownloadButton(sheet: sheet, songTitle: '주일 찬양', versionTitle: '팀 편곡'),
          ),
        ),
      ),
    ),
  );

  test('download names preserve Korean, remain portable and fit byte-based filesystem limits', () {
    expect(sheetDownloadFilename('주일 찬양', '팀 편곡', sheet), '주일 찬양 - 팀 편곡 - G - 밴드 악보.pdf');
    final name = sheetDownloadFilename('../곡/이름', '피아노: 편곡', sheet.copyWith(label: '악보.PDF'));
    expect(name, '-곡-이름 - 피아노- 편곡 - G - 악보.pdf');
    expect(utf8.encode(sheetDownloadFilename('찬양🎵' * 200, '팀', sheet)).length, lessThanOrEqualTo(224));
  });

  testWidgets('one download at a time, original bytes and PDF MIME, native cancel permits retry', (tester) async {
    final bytes = Completer<Uint8List>();
    saver.pending = Completer<Uri?>();
    await open(tester, () => bytes.future);
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
    expect(saver.calls, isEmpty);
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(rowTaps, 0, reason: 'a busy download must not open the sheet preview underneath');
    bytes.complete(pdf);
    await tester.pump();
    expect(saver.calls.single.bytes, pdf);
    expect(saver.calls.single.mime, 'application/pdf');
    expect(saver.calls.single.name, '주일 찬양 - 팀 편곡 - G - 밴드 악보.pdf');
    expect(tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
    saver.pending!.complete(null);
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing, reason: 'cancelling is not an error');
    saver.pending = null;
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(saver.calls.length, 2);
  });

  testWidgets('a failed fetch is visible and can be retried', (tester) async {
    var attempts = 0;
    await open(tester, () async {
      if (attempts++ == 0) throw Exception('Download unavailable');
      return pdf;
    });
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(saver.calls, isEmpty);
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(saver.calls.single.bytes, pdf);
  });

  testWidgets('leaving the page while fetching does not open a save dialog later', (tester) async {
    final bytes = Completer<Uint8List>();
    await open(tester, () => bytes.future);
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    bytes.complete(pdf);
    await tester.pump();
    expect(saver.calls, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
