import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/music_widgets.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'models.dart';
import 'sheet_upload.dart';
import 'songs_providers.dart';

/// Keeps preparation visible after returning from the system file picker and
/// prevents another tap from replacing a picker that is still delivering files.
class SheetUploadButton extends ConsumerStatefulWidget {
  const SheetUploadButton({super.key, required this.teamId, required this.version, required this.onChanged});

  final int teamId;
  final SongVersion version;
  final VoidCallback onChanged;

  @override
  ConsumerState<SheetUploadButton> createState() => _SheetUploadButtonState();
}

class _SheetUploadButtonState extends ConsumerState<SheetUploadButton> {
  bool _busy = false;
  bool _uploading = false;

  Future<void> _upload() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _uploading = false;
    });
    try {
      // Keep this in the original tap handler: Safari requires user activation
      // when opening its file picker.
      final sheet = await pickSheet();
      if (sheet == null || !mounted) return;
      if (sheet.pageSizes.isEmpty) {
        showMessage(context, l10n.uploadSheetHint);
        return;
      }

      String? key = widget.version.defaultKey;
      final label = TextEditingController();
      try {
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Text(l10n.uploadSheet),
              scrollable: true,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.pages(sheet.pageSizes.length)),
                  const SizedBox(height: 12),
                  KeyField(value: key, onChanged: (k) => setState(() => key = k)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: label,
                    decoration: InputDecoration(labelText: l10n.sheetLabel),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.uploadSheet)),
              ],
            ),
          ),
        );
        if (ok != true || !mounted) return;
        setState(() => _uploading = true);
        final done = await runGuarded(
          context,
          () => ref
              .read(songsRepositoryProvider)
              .uploadSheet(
                teamId: widget.teamId,
                versionId: widget.version.id,
                pdf: sheet.pdf,
                pageSizes: sheet.pageSizes,
                key: key,
                label: label.text,
              ),
        );
        // Keep failure messages visible; a progress snackbar must not dismiss
        // the error reported by runGuarded.
        if (done && mounted) widget.onChanged();
      } finally {
        label.dispose();
      }
    } on TimeoutException {
      if (mounted) showMessage(context, l10n.sheetPreparationTimeout);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextButton.icon(
      icon: _busy
          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.upload_file),
      label: Text(_busy ? (_uploading ? l10n.uploading : l10n.preparingSheet) : l10n.uploadSheet),
      onPressed: _busy ? null : _upload,
    );
  }
}
