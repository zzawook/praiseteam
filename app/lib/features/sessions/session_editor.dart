import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'models.dart';
import 'session_templates.dart';
import 'sessions_providers.dart';

/// Adds services (one, or one a week) or edits [session], and saves them.
/// A new service can start from one of the team's templates, or become one.
/// Returns the ids of the services saved; null when cancelled. On a failed
/// save the dialog stays open with what was entered.
Future<List<int>?> showSessionEditor(
  BuildContext context, {
  required int teamId,
  Session? session,
  List<Session> upcoming = const [],
}) => showDialog(
  context: context,
  builder: (_) => _SessionEditor(teamId: teamId, session: session, upcoming: upcoming),
);

class _SessionEditor extends ConsumerStatefulWidget {
  const _SessionEditor({required this.teamId, this.session, required this.upcoming});
  final int teamId;
  final Session? session;

  /// Services already planned: a template skips the weeks they fill.
  final List<Session> upcoming;

  @override
  ConsumerState<_SessionEditor> createState() => _SessionEditorState();
}

class _SessionEditorState extends ConsumerState<_SessionEditor> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.session?.title);
  late final _location = TextEditingController(text: widget.session?.location);
  late final _theme = TextEditingController(text: widget.session?.theme);
  late final _notes = TextEditingController(text: widget.session?.notes);
  late DateTime _date;
  late TimeOfDay _time;
  bool _repeat = false;
  int _weeks = 4;
  bool _saveTemplate = false;
  bool _busy = false;

  bool get _isNew => widget.session == null;

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

  /// Whether the form holds what [t] fills in; its chip then shows chosen.
  bool _follows(SessionTemplate t) =>
      _title.text.trim() == t.title &&
      _date.weekday == t.weekday &&
      _time.hour == t.hour &&
      _time.minute == t.minute &&
      _location.text.trim() == (t.location ?? '');

  void _apply(SessionTemplate t) {
    final start = t.nextStart(DateTime.now(), widget.upcoming);
    setState(() {
      _title.text = t.title;
      _location.text = t.location ?? '';
      _date = DateTime(start.year, start.month, start.day);
      _time = TimeOfDay(hour: t.hour, minute: t.minute);
    });
  }

  /// A new service whose title no template has yet can be kept as one.
  bool _canSaveTemplate(List<SessionTemplate>? templates) =>
      _isNew &&
      templates != null &&
      _title.text.trim().isNotEmpty &&
      templates.every((t) => t.title != _title.text.trim());

  Future<void> _submit(List<SessionTemplate>? templates) async {
    if (!_form.currentState!.validate()) return;
    final start = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final count = _isNew && _repeat ? _weeks : 1;
    final rows = [
      for (var i = 0; i < count; i++)
        {
          'title': _title.text.trim(),
          // Local wall-clock time each week (DST-safe), stored as UTC.
          'starts_at': DateTime(
            start.year,
            start.month,
            start.day + 7 * i,
            start.hour,
            start.minute,
          ).toUtc().toIso8601String(),
          'location': _blankToNull(_location),
          'theme': _blankToNull(_theme),
          'notes': _blankToNull(_notes),
        },
    ];
    final repo = ref.read(sessionsRepositoryProvider);
    final session = widget.session;
    setState(() => _busy = true);
    final ids = await runGuardedValue(context, () async {
      if (session == null) return repo.createSessions(widget.teamId, rows);
      await repo.updateSession(session.id, rows.first);
      return [session.id];
    });
    if (!mounted) return;
    if (ids == null) {
      setState(() => _busy = false);
      return;
    }
    // The services are saved by now, so a failed template only reports.
    if (_saveTemplate && _canSaveTemplate(templates)) {
      final fields = templateFields(title: _title.text, weekday: _date.weekday, time: _time, location: _location.text);
      if (await runGuarded(context, () => repo.createTemplate(widget.teamId, fields))) {
        ref.invalidate(sessionTemplatesProvider(widget.teamId));
      }
      if (!mounted) return;
    }
    Navigator.pop(context, ids);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final formats = DateFormats(context);
    final templates = _isNew ? ref.watch(sessionTemplatesProvider(widget.teamId)).value : null;
    final muted = TextStyle(color: theme.colorScheme.onSurfaceVariant);
    final dateButton = OutlinedButton.icon(
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
    );
    final timeButton = OutlinedButton.icon(
      icon: const Icon(Icons.schedule),
      label: Text(_time.format(context)),
      onPressed: () async {
        final picked = await showTimePicker(context: context, initialTime: _time);
        if (picked != null) setState(() => _time = picked);
      },
    );

    return AlertDialog(
      title: Text(_isNew ? l10n.addSession : l10n.editSession),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (templates != null && templates.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(child: Text(l10n.templates, style: theme.textTheme.labelLarge)),
                    TextButton(
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute<void>(builder: (_) => SessionTemplatesScreen(teamId: widget.teamId))),
                      child: Text(l10n.editTemplates),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in templates)
                      ChoiceChip(
                        label: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: t.title),
                              TextSpan(text: '  ${templateSchedule(formats, t)}', style: muted),
                            ],
                          ),
                        ),
                        selected: _follows(t),
                        onSelected: (_) => _apply(t),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _title,
                autofocus: _isNew && (templates == null || templates.isEmpty),
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: l10n.sessionTitle,
                  hintText: l10n.sessionTitleHint,
                  counterText: '',
                ),
                validator: (v) => (v ?? '').trim().isEmpty ? l10n.sessionTitle : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              // Side by side when there is room; stacked on a phone, where
              // half the dialog would break the date over two lines.
              if (MediaQuery.sizeOf(context).width < 480)
                Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 8, children: [dateButton, timeButton])
              else
                Row(
                  spacing: 12,
                  children: [
                    Expanded(child: dateButton),
                    Expanded(child: timeButton),
                  ],
                ),
              if (_isNew) ...[
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
              TextFormField(
                controller: _location,
                maxLength: 80,
                decoration: InputDecoration(labelText: l10n.location, counterText: ''),
                onChanged: (_) => setState(() {}),
              ),
              if (_canSaveTemplate(templates))
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.saveAsTemplate),
                  subtitle: Text(l10n.saveAsTemplateHint),
                  value: _saveTemplate,
                  onChanged: (v) => setState(() => _saveTemplate = v),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _theme,
                maxLength: 200,
                decoration: InputDecoration(labelText: l10n.theme, counterText: ''),
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
        FilledButton(onPressed: _busy ? null : () => _submit(templates), child: Text(l10n.save)),
      ],
    );
  }
}
