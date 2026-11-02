import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth.dart';
import '../core/dates.dart';
import '../core/env.dart';
import '../core/team_time.dart';
import '../demo/demo_banner.dart';
import '../features/teams/teams_providers.dart';
import '../features/notifications/push.dart';
import '../features/settings/settings_providers.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class PraiseTeamApp extends ConsumerWidget {
  const PraiseTeamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => '${AppLocalizations.of(context).appTitle}${Env.demo ? ' Demo' : ''}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: ref.watch(appLocaleProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => _TeamClock(
        child: DemoBanner(
          child: _ProfileLocaleSyncer(child: PushHandler(child: child ?? const SizedBox.shrink())),
        ),
      ),
    );
  }
}

class _TeamClock extends ConsumerWidget {
  const _TeamClock({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final memberships = ref.watch(myMembershipsProvider).value ?? const [];
    return ListenableBuilder(
      listenable: router.routeInformationProvider,
      builder: (context, _) {
        final path = router.routeInformationProvider.value.uri.pathSegments;
        final id = path.length > 1 && path.first == 't' ? int.tryParse(path[1]) : null;
        final zone = memberships.where((m) => m.teamId == id).firstOrNull?.team.timezone;
        return TeamTimeScope(time: TeamTime(zone ?? TeamTime.defaultZone), child: child);
      },
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
