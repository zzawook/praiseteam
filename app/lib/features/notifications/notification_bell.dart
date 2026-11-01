import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import 'notifications_providers.dart';

/// App-bar bell with the unread count; opens the notification list.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, required this.teamId});
  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    return IconButton(
      tooltip: AppLocalizations.of(context).navNotifications,
      onPressed: () => context.push('/t/$teamId/notifications'),
      icon: unread == 0
          ? const Icon(Icons.notifications_none)
          : Badge.count(count: unread, child: const Icon(Icons.notifications)),
    );
  }
}
