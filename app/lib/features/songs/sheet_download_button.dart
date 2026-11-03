import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'models.dart';
import 'songs_providers.dart';

/// A portable, readable name, independent of the private Storage object path.
/// Bound UTF-8 bytes rather than characters so long Korean titles also fit
/// common filesystem limits. Never alter the stored PDF or its metadata.
String sheetDownloadFilename(String songTitle, String versionTitle, Sheet sheet) {
  final parts = [
    songTitle,
    versionTitle,
    ?sheet.key,
    ?sheet.label,
  ].map((s) => s.trim().replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '')).where((s) => s.isNotEmpty);
  final name = parts
      .join(' - ')
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f\x7f]'), '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[ .]+|[ .]+$'), '');
  final result = StringBuffer();
  var bytes = 0;
  for (final rune in name.runes) {
    final character = String.fromCharCode(rune);
    bytes += utf8.encode(character).length;
    if (bytes > 220) break;
    result.write(character);
  }
  var stem = result.toString().trim().replaceFirst(RegExp(r'[ .]+$'), '');
  if (stem.isEmpty) stem = 'sheet';
  if (RegExp(r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)', caseSensitive: false).hasMatch(stem)) {
    stem = '_$stem';
  }
  return '$stem.pdf';
}

class SheetDownloadButton extends ConsumerStatefulWidget {
  const SheetDownloadButton({super.key, required this.sheet, required this.songTitle, required this.versionTitle});
  final Sheet sheet;
  final String songTitle;
  final String versionTitle;

  @override
  ConsumerState<SheetDownloadButton> createState() => _SheetDownloadButtonState();
}

class _SheetDownloadButtonState extends ConsumerState<SheetDownloadButton> {
  bool _busy = false;

  Future<void> _download() async {
    if (_busy) return;
    final path = widget.sheet.storagePath;
    final filename = sheetDownloadFilename(widget.songTitle, widget.versionTitle, widget.sheet);
    final title = AppLocalizations.of(context).downloadSheet;
    setState(() => _busy = true);
    try {
      // Reuse the authenticated, per-user cached download used by the viewer.
      // No public link, new storage policy, or annotated PDF export is needed.
      final bytes = await ref.read(sheetBytesProvider(path).future).timeout(const Duration(seconds: 60));
      if (!mounted) return;
      // Native: the system save dialog writes these bytes to the chosen URI.
      // Web: the default mode downloads a PDF blob without opening a popup.
      // Web returns null after starting a download, as does native cancellation;
      // do not interpret that as an error or claim the user saved the file.
      await FilePicker.saveFile(fileName: filename, bytes: bytes, mimeType: 'application/pdf', dialogTitle: title);
    } catch (error) {
      if (mounted) {
        ref.invalidate(sheetBytesProvider(path)); // a failed fetch can be retried
        showError(context, error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      // A disabled button otherwise lets a repeated tap reach the sheet row's
      // preview action. Keep that tap here while a download/save is pending.
      onTap: _busy ? () {} : null,
      excludeFromSemantics: true,
      behavior: HitTestBehavior.opaque,
      child: IconButton(
        tooltip: _busy ? l10n.downloadingSheet : l10n.downloadSheet,
        onPressed: _busy ? null : _download,
        icon: _busy
            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.download_outlined),
      ),
    );
  }
}
