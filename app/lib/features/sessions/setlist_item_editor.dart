import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/music.dart';
import '../../core/music_widgets.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../songs/songs_providers.dart';
import 'models.dart';
import 'sessions_providers.dart';

/// Key, sheet, song form and notes of one song in the setlist.
Future<void> showSetlistItemEditor(BuildContext context, {required SetlistItem item}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: _ItemEditor(item: item),
      ),
    );

class _ItemEditor extends ConsumerStatefulWidget {
  const _ItemEditor({required this.item});
  final SetlistItem item;

  @override
  ConsumerState<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends ConsumerState<_ItemEditor> {
  late String? _key = widget.item.effectiveKey;
  late int? _sheetId = widget.item.sheetId;
  late final _form = TextEditingController(text: widget.item.songForm);
  late final _notes = TextEditingController(text: widget.item.notes);
  bool _busy = false;

  @override
  void dispose() {
    _form.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _done() {
    ref.invalidate(setlistProvider(widget.item.sessionId));
    Navigator.pop(context);
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final form = normalizeSongForm(_form.text);
    final ok = await runGuarded(
      context,
      () => ref.read(sessionsRepositoryProvider).updateItem(widget.item.id, {
        // Stored explicitly so history keeps this service's key even if
        // the song's default key changes later.
        'key': _key,
        'sheet_id': _sheetId,
        'song_form': form.isEmpty ? null : form,
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      }),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) _done();
  }

  Future<void> _remove() async {
    if (await runGuarded(context, () => ref.read(sessionsRepositoryProvider).deleteItem(widget.item.id))) {
      if (mounted) _done();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sheets = ref.watch(songSheetsProvider(widget.item.songId)).value ?? const [];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.item.song.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            KeyField(value: _key, onChanged: (k) => setState(() => _key = k)),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: sheets.any((s) => s.id == _sheetId) ? _sheetId : null,
              decoration: InputDecoration(labelText: l10n.sheet),
              items: [
                DropdownMenuItem<int?>(value: null, child: Text(l10n.noSheet)),
                for (final s in sheets)
                  DropdownMenuItem<int?>(
                    value: s.id,
                    child: Text([s.label ?? l10n.sheet, if (s.key != null) '(${s.key})'].join(' ')),
                  ),
              ],
              onChanged: (v) => setState(() => _sheetId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _form,
              decoration: InputDecoration(labelText: l10n.songForm, hintText: l10n.songFormHint),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLength: 500,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.notes, counterText: ''),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _busy ? null : _save, child: Text(l10n.save)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _remove,
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              child: Text(l10n.removeFromSetlist),
            ),
          ],
        ),
      ),
    );
  }
}
