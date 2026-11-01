import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../announcements/announcements.dart';
import '../notifications/notification_bell.dart';
import '../teams/models.dart';
import '../teams/parts.dart' show partKindLabel;
import '../teams/teams_providers.dart';
import 'chat_providers.dart';
import 'chat_repository.dart';

/// The chat tab: announcements first, then my channels.
class ChannelsScreen extends ConsumerWidget {
  const ChannelsScreen({super.key, required this.teamId});
  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final narrow = MediaQuery.sizeOf(context).width < Breakpoints.rail;
    final isLeader = ref.watch(activeMembershipProvider(teamId))?.role.isLeader ?? false;
    final channels = ref.watch(channelsProvider(teamId));
    final hasNew = ref.watch(hasNewAnnouncementsProvider(teamId)).value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: narrow ? TeamSwitcher(teamId: teamId) : Text(l10n.navChat),
        actions: [NotificationBell(teamId: teamId)],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(channelsProvider(teamId)),
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              ListTile(
                leading: const Icon(Icons.campaign_outlined, color: AppColors.teamInk),
                title: Text(l10n.announcements, style: theme.textTheme.titleMedium),
                trailing: hasNew
                    ? Text(l10n.newBadge, style: theme.textTheme.labelLarge?.copyWith(color: AppColors.teamInk))
                    : const Icon(Icons.chevron_right),
                onTap: () async {
                  await context.push('/t/$teamId/announcements');
                  ref.invalidate(hasNewAnnouncementsProvider(teamId));
                },
              ),
              const Divider(),
              SectionHeader(
                l10n.channels,
                trailing: isLeader
                    ? AddButton(
                        label: l10n.newChannel,
                        icon: Icons.add_comment_outlined,
                        onPressed: () => _newChannel(context, ref),
                      )
                    : null,
              ),
              AsyncBody(
                value: channels,
                onRetry: () => ref.invalidate(channelsProvider(teamId)),
                data: (list) => Column(
                  children: [
                    for (final c in list) ...[
                      _ChannelRow(teamId: teamId, channel: c),
                      const Divider(indent: 72),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _newChannel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final parts = await ref.read(teamPartsProvider(teamId).future);
    if (!context.mounted) return;
    final name = TextEditingController();
    final picked = <int>{};
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.newChannel),
          scrollable: true,
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: name, maxLength: 40, decoration: InputDecoration(labelText: l10n.channelName, counterText: '')),
                const SizedBox(height: 8),
                Text(l10n.channelPartsHint, style: Theme.of(context).textTheme.bodySmall),
                for (final kind in PartKind.values)
                  if (parts.any((p) => p.kind == kind)) ...[
                    const SizedBox(height: 12),
                    Text(partKindLabel(l10n, kind), style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final p in parts.where((p) => p.kind == kind))
                          FilterChip(
                            label: Text(p.name),
                            selected: picked.contains(p.id),
                            onSelected: (on) => setState(() => on ? picked.add(p.id) : picked.remove(p.id)),
                          ),
                      ],
                    ),
                  ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, name.text.trim().isNotEmpty), child: Text(l10n.create)),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    if (await runGuarded(context, () => ref.read(chatRepositoryProvider).createPartsChannel(teamId, name.text, picked.toList()))) {
      ref.invalidate(channelsProvider(teamId));
    }
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.teamId, required this.channel});
  final int teamId;
  final Channel channel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = channel;
    final icon = switch (c.kind) {
      'team' => Icons.groups_outlined,
      'session' => Icons.event_note_outlined,
      _ => Icons.queue_music_outlined,
    };
    // Whole team in ink, part groups in violet, one service in amber.
    final palette = AppPalette.of(context);
    final kindColor = switch (c.kind) {
      'team' => theme.colorScheme.primary,
      'session' => palette.pending,
      _ => palette.people[1],
    };
    final last = c.lastBody ?? '';
    final subtitle = c.archived
        ? l10n.archivedChannel
        : last.isEmpty
            ? l10n.noMessages
            : (c.lastIsPoll ? l10n.pollPreview(last) : last);
    return ListTile(
      onTap: () => context.push('/t/$teamId/chat/${c.id}'),
      leading: CircleAvatar(
        backgroundColor: c.archived ? theme.colorScheme.surfaceContainerHighest : kindColor.withValues(alpha: 0.16),
        foregroundColor: c.archived ? theme.colorScheme.onSurfaceVariant : kindColor,
        child: Icon(icon, size: 20),
      ),
      title: Row(
        children: [
          Expanded(child: Text(c.name, overflow: TextOverflow.ellipsis)),
          if (c.muted) Icon(Icons.notifications_off_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (c.lastAt != null) Text(DateFormats(context).time(c.lastAt!), style: theme.textTheme.labelSmall),
          if (c.unread > 0) ...[
            const SizedBox(height: 4),
            Badge.count(count: c.unread, backgroundColor: c.muted ? theme.colorScheme.outline : AppColors.teamInk),
          ],
        ],
      ),
    );
  }
}
