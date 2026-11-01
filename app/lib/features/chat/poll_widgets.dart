import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'chat_providers.dart';
import 'chat_repository.dart';

/// Ask for a question and options; returns them, or null if cancelled.
Future<({String question, List<String> options, bool multiple, bool anonymous})?> showNewPollDialog(
  BuildContext context,
) {
  final l10n = AppLocalizations.of(context);
  final question = TextEditingController();
  final options = [TextEditingController(), TextEditingController()];
  var multiple = false;
  var anonymous = false;
  return showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.newPoll),
        scrollable: true,
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: question,
                maxLength: 200,
                decoration: InputDecoration(labelText: l10n.pollQuestion, counterText: ''),
              ),
              for (var i = 0; i < options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: options[i],
                    maxLength: 100,
                    decoration: InputDecoration(labelText: l10n.pollOption(i + 1), counterText: ''),
                  ),
                ),
              if (options.length < 10)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => options.add(TextEditingController())),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addOption),
                  ),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.multipleChoice),
                value: multiple,
                onChanged: (v) => setState(() => multiple = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.anonymousPoll),
                value: anonymous,
                onChanged: (v) => setState(() => anonymous = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              final labels = [
                for (final o in options)
                  if (o.text.trim().isNotEmpty) o.text.trim(),
              ];
              if (question.text.trim().isEmpty || labels.length < 2) return;
              Navigator.pop(context, (
                question: question.text.trim(),
                options: labels,
                multiple: multiple,
                anonymous: anonymous,
              ));
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    ),
  );
}

/// A poll inside a chat: options with live counts, my choice, voters.
class PollCard extends ConsumerStatefulWidget {
  const PollCard({super.key, required this.pollId});
  final int pollId;

  @override
  ConsumerState<PollCard> createState() => _PollCardState();
}

class _PollCardState extends ConsumerState<PollCard> {
  Set<int>? _picked;

  Future<void> _vote(Poll poll, Set<int> choice) async {
    setState(() => _picked = choice);
    final ok = await runGuarded(context, () => ref.read(chatRepositoryProvider).vote(poll.id, choice.toList()));
    if (ok) ref.invalidate(pollProvider(widget.pollId));
    if (mounted) setState(() => _picked = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final poll = ref.watch(pollProvider(widget.pollId));

    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: AsyncBody(
        value: poll,
        onRetry: () => ref.invalidate(pollProvider(widget.pollId)),
        data: (p) {
          final mine =
              _picked ??
              {
                for (final o in p.options)
                  if (o.mine) o.id,
              };
          final total = p.total;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.question, style: theme.textTheme.titleMedium),
              if (p.anonymous || p.closed)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    [if (p.anonymous) l10n.anonymous, if (p.closed) l10n.pollClosed].join('  '),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 8),
              for (final o in p.options)
                Semantics(
                  button: true,
                  selected: mine.contains(o.id),
                  label: '${o.label}, ${l10n.votes(o.votes)}',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: p.closed
                        ? null
                        : () {
                            final next = p.multiple
                                ? (mine.contains(o.id) ? ({...mine}..remove(o.id)) : {...mine, o.id})
                                : (mine.contains(o.id) ? <int>{} : {o.id});
                            _vote(p, next);
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                mine.contains(o.id)
                                    ? (p.multiple ? Icons.check_box : Icons.radio_button_checked)
                                    : (p.multiple ? Icons.check_box_outline_blank : Icons.radio_button_unchecked),
                                size: 20,
                                color: mine.contains(o.id) ? AppColors.teamInk : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(o.label)),
                              Text(l10n.votes(o.votes), style: theme.textTheme.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: total == 0 ? 0 : o.votes / total,
                              minHeight: 4,
                              color: AppColors.teamInk,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          if (o.voters != null && o.voters!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(o.voters!.join(', '), style: theme.textTheme.bodySmall),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
