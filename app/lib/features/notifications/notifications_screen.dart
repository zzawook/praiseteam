import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../sessions/models.dart';
import '../sessions/sessions_providers.dart';
import 'notifications_providers.dart';

/// Title and body for a notification, in the app's language.
({String title, String body}) describeNotification(AppLocalizations l10n, AppNotification n) {
  String p(String key) => n.params[key]?.toString() ?? '';
  return switch (n.category) {
    'member_join_request' => (
        title: l10n.notifJoinRequestTitle,
        body: l10n.notifJoinRequestBody(p('user_name'), p('team_name')),
      ),
    'member_approved' => (title: l10n.notifApprovedTitle, body: l10n.notifApprovedBody(p('team_name'))),
    'setlist_published' => (
        title: l10n.notifSetlistTitle(p('session_title')),
        body: [for (final s in (n.params['songs'] as List? ?? const [])) s.toString()].join(', '),
      ),
    'setlist_updated' => (
        title: l10n.notifSetlistUpdatedTitle(p('session_title')),
        body: describeSetlistChanges(l10n, SetlistChanges.fromJson((n.params['summary'] as Map?)?.cast<String, dynamic>())),
      ),
    'assignment_requested' => (title: l10n.notifAssignmentRequested(p('session_title'), p('part_name')), body: p('team_name')),
    'assignment_declined' => (
        title: l10n.notifAssignmentDeclined(p('user_name'), p('session_title'), p('part_name')),
        body: p('reason'),
      ),
    'assignment_removed' => (title: l10n.notifAssignmentRemoved(p('session_title'), p('part_name')), body: ''),
    'assignment_nudge' => (title: l10n.notifAssignmentNudge(p('session_title'), p('part_name')), body: ''),
    'swap_requested' => (title: l10n.notifSwapRequested(p('user_name'), p('session_title'), p('part_name')), body: p('message')),
    'swap_filled' => (title: l10n.notifSwapFilled(p('user_name'), p('session_title'), p('part_name')), body: ''),
    'service_reminder' => (title: l10n.notifServiceReminder(p('session_title'), p('part_name')), body: ''),
    'rehearsal_scheduled' => (title: l10n.notifRehearsalScheduled(_when(n.params['starts_at'])), body: p('location')),
    'rehearsal_reminder' => (title: l10n.notifRehearsalReminder(_when(n.params['starts_at'])), body: p('location')),
    'announcement' => (title: l10n.notifAnnouncementTitle(p('title')), body: p('preview')),
    'chat_message' => (title: l10n.notifChatTitle(p('channel_name')), body: '${p('sender_name')}: ${p('preview')}'),
    _ => (title: l10n.notifFallback, body: ''),
  };
}

String _when(Object? iso) {
  final t = iso is String ? DateTime.tryParse(iso)?.toLocal() : null;
  return t == null ? '' : DateFormat('M/d HH:mm').format(t);
}

/// Where tapping a notification (in the list or as a push) leads.
String notificationRoute(AppNotification n) {
  final team = n.teamId;
  final session = n.params['session_id'];
  return switch (n.category) {
    'setlist_published' || 'setlist_updated' || 'service_reminder' || 'rehearsal_scheduled' || 'rehearsal_reminder'
        when session != null =>
      '/t/$team/sessions/$session',
    'assignment_requested' || 'assignment_declined' || 'assignment_removed' || 'assignment_nudge' || 'swap_requested' || 'swap_filled' =>
      '/t/$team/rotation',
    'member_join_request' || 'member_approved' => '/t/$team/team',
    'announcement' => '/t/$team/announcements',
    'chat_message' when n.params['channel_id'] != null => '/t/$team/chat/${n.params['channel_id']}',
    _ => '/t/$team/home',
  };
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key, required this.teamId});
  final int teamId;

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Opening the list is what "read" means for notifications.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(notificationsProvider.notifier).markAllRead().catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navNotifications)),
      body: AsyncBody(
        value: notifications,
        onRetry: () => ref.invalidate(notificationsProvider),
        data: (items) => items.isEmpty
            ? Center(child: Text(l10n.notificationsEmpty, style: theme.textTheme.bodyLarge))
            : ContentWidth(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(indent: 20),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    final text = describeNotification(l10n, n);
                    final when = DateFormat.MMMd(locale).add_jm().format(n.createdAt.toLocal());
                    return ListTile(
                      onTap: n.teamId == null ? null : () => context.go(notificationRoute(n)),
                      title: Text(
                        text.title,
                        style: n.readAt == null ? const TextStyle(fontWeight: FontWeight.w700) : null,
                      ),
                      subtitle: Text(text.body.isEmpty ? when : '${text.body}\n$when'),
                      isThreeLine: text.body.isNotEmpty,
                    );
                  },
                ),
              ),
      ),
    );
  }
}
