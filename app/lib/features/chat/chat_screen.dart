import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth.dart';
import 'chat_providers.dart';
import 'chat_repository.dart';
import 'poll_widgets.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.teamId, required this.channelId});
  final int teamId;
  final int channelId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Personal read marker (nobody else can see it); clears my unread count.
  Future<void> _markRead() async {
    await ref.read(chatRepositoryProvider).markRead(widget.teamId, widget.channelId).catchError((_) {});
    ref.invalidate(channelsProvider(widget.teamId));
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    _focus.requestFocus();
    await runGuarded(context, () => ref.read(channelMessagesProvider(widget.teamId, widget.channelId).notifier).send(text));
  }

  Future<void> _poll() async {
    final draft = await showNewPollDialog(context);
    if (draft == null || !mounted) return;
    await runGuarded(
      context,
      () => ref.read(chatRepositoryProvider).createPoll(
            teamId: widget.teamId,
            channelId: widget.channelId,
            question: draft.question,
            options: draft.options,
            multiple: draft.multiple,
            anonymous: draft.anonymous,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentUserIdProvider);
    final channel = (ref.watch(channelsProvider(widget.teamId)).value ?? const <Channel>[])
        .where((c) => c.id == widget.channelId)
        .firstOrNull;
    final messages = ref.watch(channelMessagesProvider(widget.teamId, widget.channelId));
    // Opening the chat while messages arrive keeps it read.
    ref.listen(channelMessagesProvider(widget.teamId, widget.channelId), (prev, next) {
      if ((next.value?.length ?? 0) > (prev?.value?.length ?? 0)) _markRead();
    });
    final archived = channel?.archived ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(channel?.name ?? ''),
        actions: [
          if (channel != null)
            IconButton(
              tooltip: channel.muted ? l10n.unmute : l10n.mute,
              icon: Icon(channel.muted ? Icons.notifications_off_outlined : Icons.notifications_active_outlined),
              onPressed: () async {
                if (await runGuarded(context, () => ref.read(chatRepositoryProvider).setMuted(widget.teamId, widget.channelId, !channel.muted))) {
                  ref.invalidate(channelsProvider(widget.teamId));
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AsyncBody(
              value: messages,
              onRetry: () => ref.invalidate(channelMessagesProvider(widget.teamId, widget.channelId)),
              data: (list) => list.isEmpty
                  ? Center(child: Text(l10n.noMessages))
                  : ContentWidth(
                      child: ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final m = list[i];
                          final older = i + 1 < list.length ? list[i + 1] : null;
                          // Name shown once per run of messages from the same person.
                          final showName = m.senderId != me && (older == null || older.senderId != m.senderId);
                          return _Bubble(message: m, mine: m.senderId == me, showName: showName);
                        },
                      ),
                    ),
            ),
          ),
          if (!archived)
            SafeArea(
              top: false,
              child: ContentWidth(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: Row(
                    children: [
                      IconButton(tooltip: l10n.newPoll, icon: const Icon(Icons.poll_outlined), onPressed: _poll),
                      Expanded(
                        child: CallbackShortcuts(
                          // Enter sends on laptops; Shift+Enter makes a new line.
                          bindings: {const SingleActivator(LogicalKeyboardKey.enter): _send},
                          child: TextField(
                            controller: _input,
                            focusNode: _focus,
                            minLines: 1,
                            maxLines: 5,
                            maxLength: 4000,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(hintText: l10n.messageHint, counterText: '', isDense: true),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filled(tooltip: l10n.send, onPressed: _send, icon: const Icon(Icons.send)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends ConsumerWidget {
  const _Bubble({required this.message, required this.mine, required this.showName});
  final Message message;
  final bool mine;
  final bool showName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final m = message;
    final time = Text(DateFormats(context).time(m.createdAt), style: theme.textTheme.labelSmall);

    Widget content;
    if (m.deleted) {
      content = Text(l10n.deletedMessage, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant));
    } else if (m.pollId != null) {
      content = PollCard(pollId: m.pollId!);
    } else {
      content = Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: mine ? AppColors.teamInk : theme.colorScheme.surface,
          border: mine ? null : Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          m.body ?? '',
          style: theme.textTheme.bodyLarge?.copyWith(color: mine ? Colors.white : null),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: showName ? 10 : 3),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showName) Padding(padding: const EdgeInsets.only(left: 4, bottom: 2), child: Text(m.senderName, style: theme.textTheme.labelMedium)),
          GestureDetector(
            onLongPress: mine && !m.deleted && !m.pending && m.pollId == null
                ? () async {
                    final ok = await confirm(context, message: l10n.deleteMessage, confirmLabel: l10n.delete, destructive: true);
                    if (ok && context.mounted) await runGuarded(context, () => ref.read(chatRepositoryProvider).delete(m.id));
                  }
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (mine) ...[Opacity(opacity: m.pending ? 0.4 : 1, child: time), const SizedBox(width: 6)],
                Flexible(child: content),
                if (!mine) ...[const SizedBox(width: 6), time],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
