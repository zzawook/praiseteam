import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/music.dart';
import '../../core/music_widgets.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../songs/models.dart';
import '../songs/songs_providers.dart';
import 'models.dart';
import 'sessions_providers.dart';

/// Version, key, tempo, sheet, song form and notes of one song in the setlist.
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
  late int? _versionId = widget.item.versionId;
  late String? _key = widget.item.effectiveKey;
  late final _bpm = TextEditingController(text: widget.item.effectiveBpm?.toString());
  String? _bpmError;
  late int? _sheetId = widget.item.sheetId;
  late final _form = TextEditingController(text: widget.item.songForm);
  late final _notes = TextEditingController(text: widget.item.notes);
  bool _busy = false;

  @override
  void dispose() {
    _bpm.dispose();
    _form.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _done() {
    ref.invalidate(setlistProvider(widget.item.sessionId));
    Navigator.pop(context);
  }

  /// Another version brings its own key, tempo and sheet, which can still
  /// be changed for this service.
  void _switchVersion(SongVersion v) {
    setState(() {
      _versionId = v.id;
      _key = v.defaultKey ?? _key;
      _bpm.text = v.bpm?.toString() ?? '';
      _bpmError = null;
      _sheetId = (v.sheets.where((s) => s.key == _key).firstOrNull ?? v.sheets.firstOrNull)?.id;
    });
  }

  Future<void> _save(SongVersion? version) async {
    final bpmText = _bpm.text.trim();
    final bpm = int.tryParse(bpmText);
    if (bpmText.isNotEmpty && (bpm == null || bpm < 20 || bpm > 300)) {
      setState(() => _bpmError = '20–300');
      return;
    }
    setState(() => _busy = true);
    final form = normalizeSongForm(_form.text);
    final ok = await runGuarded(
      context,
      () => ref.read(sessionsRepositoryProvider).updateItem(widget.item.id, {
        // Stored explicitly so history keeps this service's key and tempo
        // even if the song's own change later.
        'version_id': ?version?.id,
        'key': _key,
        'bpm': bpm,
        // Only a sheet of the version this service plays.
        'sheet_id': version != null && version.sheets.any((s) => s.id == _sheetId) ? _sheetId : null,
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
    final versions = ref.watch(songVersionsProvider(widget.item.songId)).value ?? const <SongVersion>[];
    // A copy kept from before versions has none: its song's only version.
    final version = versions.where((v) => v.id == _versionId).firstOrNull ?? (versions.length == 1 ? versions.first : null);
    final sheets = version?.sheets ?? const <Sheet>[];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.item.song.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            if (versions.length > 1) ...[
              DropdownButtonFormField<int>(
                // Re-created once the versions arrive.
                key: ValueKey(('version', versions.length)),
                initialValue: version?.id,
                decoration: InputDecoration(labelText: l10n.version),
                items: [
                  for (final v in versions)
                    DropdownMenuItem(
                      value: v.id,
                      child: Text(
                        [v.name ?? l10n.unnamedVersion, ?v.defaultKey, if (v.bpm != null) '${v.bpm} BPM'].join('  '),
                      ),
                    ),
                ],
                onChanged: (id) => _switchVersion(versions.firstWhere((v) => v.id == id)),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: KeyField(
                    key: ValueKey(('key', _versionId)),
                    value: _key,
                    onChanged: (k) => setState(() => _key = k),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _bpm,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.bpm, errorText: _bpmError),
                    onChanged: (_) => _bpmError == null ? null : setState(() => _bpmError = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              // Re-created when the sheets arrive or the version changes.
              key: ValueKey(('sheet', version?.id, sheets.length, _sheetId)),
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
            FilledButton(onPressed: _busy ? null : () => _save(version), child: Text(l10n.save)),
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
