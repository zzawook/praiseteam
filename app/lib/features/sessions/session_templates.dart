import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'models.dart';
import 'sessions_providers.dart';

/// "일 오전 11:00", or "일요일 오전 11:00" when not [short].
String templateSchedule(DateFormats formats, SessionTemplate t, {bool short = true}) =>
    '${formats.weekdayName(t.weekday, short: short)} ${formats.time(DateTime(2024, 1, 1, t.hour, t.minute))}';

/// A template row: [time] as 'HH:MM', a blank place as none.
Map<String, Object?> templateFields({
  required String title,
  required int weekday,
  required TimeOfDay time,
  required String location,
}) => {
  'title': title.trim(),
  'weekday': weekday,
  'start_time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
  'location': location.trim().isEmpty ? null : location.trim(),
};

/// The team's weekly services, which adding a service offers to start from.
class SessionTemplatesScreen extends ConsumerWidget {
  const SessionTemplatesScreen({super.key, required this.teamId});
  final int teamId;

  Future<void> _delete(BuildContext context, WidgetRef ref, SessionTemplate t) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirm(
      context,
      message: l10n.deleteTemplateConfirm(t.title),
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    if (await runGuarded(context, () => ref.read(sessionsRepositoryProvider).deleteTemplate(t.id))) {
      ref.invalidate(sessionTemplatesProvider(teamId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final formats = DateFormats(context);
    final templates = ref.watch(sessionTemplatesProvider(teamId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sessionTemplates)),
      body: AsyncBody(
        value: templates,
        onRetry: () => ref.invalidate(sessionTemplatesProvider(teamId)),
        data: (templates) => ContentWidth(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              SectionHeader(
                l10n.weeklyServices,
                trailing: AddButton(
                  label: l10n.addTemplate,
                  onPressed: () => showTemplateEditor(context, teamId: teamId, others: templates),
                ),
              ),
              if (templates.isEmpty)
                Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 8), child: Text(l10n.noTemplates))
              else
                for (final t in templates)
                  ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                    title: Text(t.title),
                    subtitle: Text([templateSchedule(formats, t, short: false), ?t.location].join('  ')),
                    onTap: () => showTemplateEditor(context, teamId: teamId, template: t, others: templates),
                    trailing: IconButton(
                      tooltip: l10n.delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(context, ref, t),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Adds a template, or edits [template], and saves it. [others] are the
/// team's templates, whose titles a new title must not repeat.
Future<void> showTemplateEditor(
  BuildContext context, {
  required int teamId,
  SessionTemplate? template,
  required List<SessionTemplate> others,
}) => showDialog(
  context: context,
  builder: (_) => _TemplateEditor(teamId: teamId, template: template, others: others),
);

class _TemplateEditor extends ConsumerStatefulWidget {
  const _TemplateEditor({required this.teamId, this.template, required this.others});
  final int teamId;
  final SessionTemplate? template;
  final List<SessionTemplate> others;

  @override
  ConsumerState<_TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends ConsumerState<_TemplateEditor> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.template?.title);
  late final _location = TextEditingController(text: widget.template?.location);
  late int _weekday = widget.template?.weekday ?? DateTime.sunday;
  late TimeOfDay _time = switch (widget.template) {
    final t? => TimeOfDay(hour: t.hour, minute: t.minute),
    null => const TimeOfDay(hour: 11, minute: 0),
  };
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final fields = templateFields(title: _title.text, weekday: _weekday, time: _time, location: _location.text);
    final repo = ref.read(sessionsRepositoryProvider);
    final template = widget.template;
    setState(() => _busy = true);
    final ok = await runGuarded(
      context,
      () => template == null ? repo.createTemplate(widget.teamId, fields) : repo.updateTemplate(template.id, fields),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    ref.invalidate(sessionTemplatesProvider(widget.teamId));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final formats = DateFormats(context);

    return AlertDialog(
      title: Text(widget.template == null ? l10n.addTemplate : l10n.editTemplate),
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
                autofocus: widget.template == null,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: l10n.sessionTitle,
                  hintText: l10n.sessionTitleHint,
                  counterText: '',
                ),
                validator: (v) {
                  final title = (v ?? '').trim();
                  if (title.isEmpty) return l10n.sessionTitle;
                  if (widget.others.any((t) => t.id != widget.template?.id && t.title == title)) {
                    return l10n.templateTitleTaken;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(l10n.weekday, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final day in const [7, 1, 2, 3, 4, 5, 6])
                    ChoiceChip(
                      label: Text(formats.weekdayName(day, short: true)),
                      selected: _weekday == day,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _weekday = day),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.schedule),
                label: Text(_time.format(context)),
                onPressed: () async {
                  final picked = await showTimePicker(context: context, initialTime: _time);
                  if (picked != null) setState(() => _time = picked);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _location,
                maxLength: 80,
                decoration: InputDecoration(labelText: l10n.location, counterText: ''),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _busy ? null : _save, child: Text(l10n.save)),
      ],
    );
  }
}
