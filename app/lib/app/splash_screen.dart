import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets.dart';
import '../features/teams/teams_providers.dart';
import '../l10n/app_localizations.dart';

/// Shown while memberships load, or when loading them failed.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final memberships = ref.watch(myMembershipsProvider);
    return Scaffold(
      body: memberships.hasError && !memberships.isLoading
          ? AsyncBody(
              value: AsyncError<Object>(memberships.error!, memberships.stackTrace ?? StackTrace.current),
              data: (_) => const SizedBox.shrink(),
              onRetry: () => ref.invalidate(myMembershipsProvider),
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.loading),
                ],
              ),
            ),
    );
  }
}
