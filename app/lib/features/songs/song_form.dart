import 'package:flutter/material.dart';

import '../../core/music_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'models.dart';

/// Add or edit a song's basic info. Returns the columns to write, or null.
Future<Map<String, Object?>?> showSongForm(BuildContext context, {Song? song}) => showDialog(
      context: context,
      builder: (_) => _SongFormDialog(song: song),
    );

class _SongFormDialog extends StatefulWidget {
  const _SongFormDialog({this.song});
  final Song? song;

  @override
  State<_SongFormDialog> createState() => _SongFormDialogState();
}

class _SongFormDialogState extends State<_SongFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.song?.title);
  late final _artist = TextEditingController(text: widget.song?.artist);
  late final _bpm = TextEditingController(text: widget.song?.bpm?.toString());
  late final _time = TextEditingController(text: widget.song?.timeSignature);
  late final _tags = TextEditingController(text: widget.song?.tags.join(', '));
  late final _notes = TextEditingController(text: widget.song?.notes);
  late String? _key = widget.song?.defaultKey;

  @override
  void dispose() {
    for (final c in [_title, _artist, _bpm, _time, _tags, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _blankToNull(String s) => s.trim().isEmpty ? null : s.trim();

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, <String, Object?>{
      'title': _title.text.trim(),
      'artist': _blankToNull(_artist.text),
      'default_key': _key,
      'bpm': int.tryParse(_bpm.text.trim()),
      'time_signature': _blankToNull(_time.text),
      'tags': [
        for (final t in _tags.text.split(','))
          if (t.trim().isNotEmpty) t.trim(),
      ],
      'notes': _blankToNull(_notes.text),
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.song == null ? l10n.addSong : l10n.editSong),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                autofocus: widget.song == null,
                maxLength: 120,
                decoration: InputDecoration(labelText: l10n.songTitle, counterText: ''),
                validator: (v) => (v ?? '').trim().isEmpty ? l10n.songTitle : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _artist,
                maxLength: 120,
                decoration: InputDecoration(labelText: l10n.artist, counterText: ''),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: KeyField(value: _key, onChanged: (k) => setState(() => _key = k))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _bpm,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l10n.bpm),
                      validator: (v) {
                        final text = (v ?? '').trim();
                        if (text.isEmpty) return null;
                        final n = int.tryParse(text);
                        return n == null || n < 20 || n > 300 ? '20–300' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
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
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tags,
                decoration: InputDecoration(labelText: l10n.tags, hintText: l10n.tagsHint),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                maxLength: 2000,
                decoration: InputDecoration(labelText: l10n.notes, counterText: ''),
              ),
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
