import 'package:flutter/material.dart';

import '../../core/dates.dart';
import '../../l10n/app_localizations.dart';
import 'models.dart';

/// Create one session (optionally repeated weekly) or edit an existing one.
/// Returns the rows to write: several when repeating, one otherwise.
Future<List<Map<String, Object?>>?> showSessionEditor(
  BuildContext context, {
  Session? session,
  List<String> recentTitles = const [],
}) =>
    showDialog(
      context: context,
      builder: (_) => _SessionEditor(session: session, recentTitles: recentTitles),
    );

class _SessionEditor extends StatefulWidget {
  const _SessionEditor({this.session, required this.recentTitles});
  final Session? session;
  final List<String> recentTitles;

  @override
  State<_SessionEditor> createState() => _SessionEditorState();
}

class _SessionEditorState extends State<_SessionEditor> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.session?.title);
  late final _location = TextEditingController(text: widget.session?.location);
  late final _theme = TextEditingController(text: widget.session?.theme);
  late final _notes = TextEditingController(text: widget.session?.notes);
  late DateTime _date;
  late TimeOfDay _time;
  bool _repeat = false;
  int _weeks = 4;

  @override
  void initState() {
    super.initState();
    final start = widget.session?.startsAt.toLocal() ?? _nextSunday();
    _date = DateTime(start.year, start.month, start.day);
    _time = TimeOfDay(hour: start.hour, minute: start.minute);
  }

  DateTime _nextSunday() {
    final now = DateTime.now();
    final days = (DateTime.sunday - now.weekday) % 7;
    final d = now.add(Duration(days: days == 0 ? 7 : days));
    return DateTime(d.year, d.month, d.day, 11);
  }

  @override
  void dispose() {
    for (final c in [_title, _location, _theme, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _blankToNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final start = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final count = widget.session == null && _repeat ? _weeks : 1;
    Navigator.pop(context, [
      for (var i = 0; i < count; i++)
        {
          'title': _title.text.trim(),
          // Local wall-clock time each week (DST-safe), stored as UTC.
          'starts_at': DateTime(start.year, start.month, start.day + 7 * i, start.hour, start.minute)
              .toUtc()
              .toIso8601String(),
          'location': _blankToNull(_location),
          'theme': _blankToNull(_theme),
          'notes': _blankToNull(_notes),
        },
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formats = DateFormats(context);
    final suggestions = widget.recentTitles.take(5).toList();

    return AlertDialog(
      title: Text(widget.session == null ? l10n.addSession : l10n.editSession),
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
                autofocus: widget.session == null,
                maxLength: 80,
                decoration: InputDecoration(labelText: l10n.sessionTitle, hintText: l10n.sessionTitleHint, counterText: ''),
                validator: (v) => (v ?? '').trim().isEmpty ? l10n.sessionTitle : null,
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in suggestions)
                      ActionChip(label: Text(t), onPressed: () => setState(() => _title.text = t)),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event),
                      label: Text(formats.dayWithWeekday(_date)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule),
                      label: Text(_time.format(context)),
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: _time);
                        if (picked != null) setState(() => _time = picked);
                      },
                    ),
                  ),
                ],
              ),
              if (widget.session == null) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.repeatWeekly),
                  value: _repeat,
                  onChanged: (v) => setState(() => _repeat = v),
                ),
                if (_repeat)
                  Row(
                    children: [
                      IconButton(
                        onPressed: _weeks > 2 ? () => setState(() => _weeks--) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text(l10n.repeatCount(_weeks)),
                      IconButton(
                        onPressed: _weeks < 12 ? () => setState(() => _weeks++) : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
              ],
              const SizedBox(height: 12),
              TextFormField(controller: _location, maxLength: 80, decoration: InputDecoration(labelText: l10n.location, counterText: '')),
              const SizedBox(height: 12),
              TextFormField(controller: _theme, maxLength: 200, decoration: InputDecoration(labelText: l10n.theme, counterText: '')),
              const SizedBox(height: 12),
              TextFormField(controller: _notes, maxLines: 3, maxLength: 2000, decoration: InputDecoration(labelText: l10n.notes, counterText: '')),
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
