import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../annotations/stroke_outbox.dart';
import '../auth/auth.dart';
import '../notifications/push.dart';

/// A slim line while the server cannot be reached: what is shown is the
/// copy kept on this device, and notes go up later.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineStatusProvider.select((s) => s.online));
    if (online) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final waiting = ref.watch(strokeOutboxProvider);
    final foreground = theme.colorScheme.onInverseSurface;
    return Semantics(
      container: true,
      liveRegion: true,
      child: ColoredBox(
        color: theme.colorScheme.inverseSurface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.cloud_off_outlined, size: 18, color: foreground),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  [l10n.offlineShowingSaved, if (waiting > 0) l10n.offlineNotesWaiting(waiting)].join(' '),
                  style: theme.textTheme.bodySmall?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Signs out and removes everything kept on this device, so the next
/// person on a shared tablet finds nothing. Warns first if notes drawn
/// offline have not reached the server yet.
Future<void> signOutHere(BuildContext context, WidgetRef ref) async {
  final waiting = ref.read(strokeOutboxProvider);
  if (waiting > 0) {
    final l10n = AppLocalizations.of(context);
    final ok = await confirm(
      context,
      message: l10n.unsentNotesSignOut(waiting),
      confirmLabel: l10n.signOut,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
  }
  await runGuarded(context, () async {
    try {
      await ref.read(pushRegistrationProvider.notifier).disable();
    } catch (_) {
      // Offline: the token stays registered until the next sign-in here
      // takes it over, or it expires.
    }
    await ref.read(authRepositoryProvider).signOut();
    await ref.read(offlineStoreProvider).clear();
  });
}
