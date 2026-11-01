import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../songs/models.dart';
import '../songs/songs_providers.dart';

/// Read-only view of one sheet. The music-stand viewer with annotations
/// (M3) builds on this.
class SheetPreviewScreen extends ConsumerWidget {
  const SheetPreviewScreen({super.key, required this.sheetId, this.initial});
  final int sheetId;
  final Sheet? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sheet = initial != null ? AsyncData(initial!) : ref.watch(sheetProvider(sheetId));
    return Scaffold(
      appBar: AppBar(title: Text(sheet.value?.label ?? l10n.sheet)),
      body: AsyncBody(
        value: sheet,
        onRetry: () => ref.invalidate(sheetProvider(sheetId)),
        data: (sheet) {
          final bytes = ref.watch(sheetBytesProvider(sheet.storagePath));
          return AsyncBody(
            value: bytes,
            onRetry: () => ref.invalidate(sheetBytesProvider(sheet.storagePath)),
            data: (data) => PdfViewer.data(
              data,
              sourceName: sheet.storagePath,
              params: const PdfViewerParams(backgroundColor: Colors.white),
            ),
          );
        },
      ),
    );
  }
}
