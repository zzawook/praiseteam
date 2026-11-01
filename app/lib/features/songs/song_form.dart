import 'package:flutter/material.dart';

import '../../core/music_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'models.dart';

/// A new song: its own columns and those of its first version.
typedef NewSong = ({Map<String, Object?> song, Map<String, Object?> version});

/// Adds a song with its first version. Returns what to write, or null.
Future<NewSong?> showNewSongForm(BuildContext context) => showDialog(
      context: context,
      builder: (_) => const _SongFormDialog(song: null),
    );

/// Edits what every version of [song] shares: title, time signature, tags,
/// notes. Returns the columns to write, or null.
Future<Map<String, Object?>?> showSongForm(BuildContext context, {required Song song}) async =>
    (await showDialog<NewSong>(
      context: context,
      builder: (_) => _SongFormDialog(song: song),
    ))
        ?.song;

/// Adds a version, or edits [version]: its name, key and tempo. Returns the
/// columns to write, or null.
Future<Map<String, Object?>?> showVersionForm(BuildContext context, {SongVersion? version}) => showDialog(
      context: context,
      builder: (_) => _VersionFormDialog(version: version),
    );

String? _blankToNull(String s) => s.trim().isEmpty ? null : s.trim();

String? _bpmError(String? v) {
  final text = (v ?? '').trim();
  if (text.isEmpty) return null;
  final n = int.tryParse(text);
  return n == null || n < 20 || n > 300 ? '20–300' : null;
}

/// Name, key and tempo of a version, shared by both forms.
class _VersionFields extends StatelessWidget {
  const _VersionFields({required this.name, required this.bpm, required this.musicalKey, required this.onKey});
  final TextEditingController name;
  final TextEditingController bpm;
  final String? musicalKey;
  final ValueChanged<String?> onKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: name,
          maxLength: 120,
          decoration: InputDecoration(labelText: l10n.versionName, hintText: l10n.versionNameHint, counterText: ''),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: KeyField(value: musicalKey, onChanged: onKey)),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: bpm,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.bpm),
                validator: _bpmError,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SongFormDialog extends StatefulWidget {
  const _SongFormDialog({required this.song});

  /// Null to add a song, which then also takes its first version.
  final Song? song;

  @override
  State<_SongFormDialog> createState() => _SongFormDialogState();
}

class _SongFormDialogState extends State<_SongFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.song?.title);
  late final _time = TextEditingController(text: widget.song?.timeSignature);
  late final _tags = TextEditingController(text: widget.song?.tags.join(', '));
  late final _notes = TextEditingController(text: widget.song?.notes);
  final _versionName = TextEditingController();
  final _bpm = TextEditingController();
  String? _key;

  bool get _isNew => widget.song == null;

  @override
  void dispose() {
    for (final c in [_title, _time, _tags, _notes, _versionName, _bpm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop<NewSong>(context, (
      song: <String, Object?>{
        'title': _title.text.trim(),
        'time_signature': _blankToNull(_time.text),
        'tags': [
          for (final t in _tags.text.split(','))
            if (t.trim().isNotEmpty) t.trim(),
        ],
        'notes': _blankToNull(_notes.text),
      },
      version: <String, Object?>{
        'name': _blankToNull(_versionName.text),
        'default_key': _key,
        'bpm': int.tryParse(_bpm.text.trim()),
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_isNew ? l10n.addSong : l10n.editSong),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _title,
                autofocus: _isNew,
                maxLength: 120,
                decoration: InputDecoration(labelText: l10n.songTitle, counterText: ''),
                validator: (v) => (v ?? '').trim().isEmpty ? l10n.songTitle : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _time,
                      decoration: InputDecoration(labelText: l10n.timeSignature, hintText: '4/4'),
                      validator: (v) {
                        final text = (v ?? '').trim();
                        return text.isEmpty || RegExp(r'^\d{1,2}/\d{1,2}$').hasMatch(text) ? null : '4/4';
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _tags,
                      decoration: InputDecoration(labelText: l10n.tags, hintText: l10n.tagsHint),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                maxLength: 2000,
                decoration: InputDecoration(labelText: l10n.notes, counterText: ''),
              ),
              if (_isNew) ...[
                const SizedBox(height: 20),
                Text(l10n.firstVersion, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  l10n.firstVersionHint,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                _VersionFields(
                  name: _versionName,
                  bpm: _bpm,
                  musicalKey: _key,
                  onKey: (k) => setState(() => _key = k),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}

class _VersionFormDialog extends StatefulWidget {
  const _VersionFormDialog({this.version});
  final SongVersion? version;

  @override
  State<_VersionFormDialog> createState() => _VersionFormDialogState();
}

class _VersionFormDialogState extends State<_VersionFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.version?.name);
  late final _bpm = TextEditingController(text: widget.version?.bpm?.toString());
  late String? _key = widget.version?.defaultKey;

  @override
  void dispose() {
    _name.dispose();
    _bpm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, <String, Object?>{
      'name': _blankToNull(_name.text),
      'default_key': _key,
      'bpm': int.tryParse(_bpm.text.trim()),
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.version == null ? l10n.addVersion : l10n.editVersion),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: _VersionFields(name: _name, bpm: _bpm, musicalKey: _key, onKey: (k) => setState(() => _key = k)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
