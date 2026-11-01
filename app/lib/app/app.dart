import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth.dart';
import '../features/settings/settings_providers.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class PraiseTeamApp extends ConsumerWidget {
  const PraiseTeamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: ref.watch(appLocaleProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => _ProfileLocaleSyncer(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Keeps the profile's language (used for push texts) equal to the
/// language the app is showing.
class _ProfileLocaleSyncer extends ConsumerWidget {
  const _ProfileLocaleSyncer({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = Localizations.localeOf(context).languageCode;
    final signedIn = ref.watch(currentUserIdProvider) != null;
    if (signedIn && ref.watch(profileLocaleSyncProvider) != code) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(profileLocaleSyncProvider.notifier).sync(code).catchError((_) {});
      });
    }
    return child;
  }
}
