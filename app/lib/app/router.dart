import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/announcements/announcements.dart';
import '../features/auth/auth.dart';
import '../features/chat/channels_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/rotation/blockouts_screen.dart';
import '../features/rotation/rotation_screen.dart';
import '../features/sessions/session_screen.dart';
import '../features/sessions/sessions_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/songs/models.dart';
import '../features/songs/song_detail_screen.dart';
import '../features/songs/songs_screen.dart';
import '../features/songs/stats_screen.dart';
import '../features/teams/pending_screen.dart';
import '../features/teams/team_screen.dart';
import '../features/teams/teams_providers.dart';
import '../features/teams/welcome_screen.dart';
import '../features/viewer/setlist_viewer_screen.dart';
import '../features/viewer/sheet_preview_screen.dart';
import 'redirect.dart';
import 'shell.dart';
import 'splash_screen.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // Re-run redirects whenever auth or memberships change.
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(sessionProvider, (_, _) => refresh.value++)
    ..listen(myMembershipsProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  int? teamIdOf(GoRouterState state) => int.tryParse(state.pathParameters['teamId'] ?? '');
  int idOf(GoRouterState state, String name) => int.parse(state.pathParameters[name]!);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final memberships = ref.read(myMembershipsProvider);
      final routeTeamId = teamIdOf(state);
      final target = resolveRedirect(
        uri: state.uri,
        signedIn: session.value != null,
        // A reload caused by a dependency change (e.g. a different user
        // signed in) means the previous list no longer applies.
        membershipsLoading: memberships.isLoading && (!memberships.hasValue || memberships.isReloading),
        membershipsFailed: memberships.hasError && !memberships.isLoading,
        memberships: memberships.value ?? const [],
        lastTeamId: ref.read(lastTeamProvider),
        routeTeamId: routeTeamId,
      );
      if (target == null && routeTeamId != null) {
        ref.read(lastTeamProvider.notifier).remember(routeTeamId);
      }
      return target;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/pending', builder: (_, _) => const PendingScreen()),
      GoRoute(
        path: '/t/:teamId/notifications',
        builder: (_, state) => NotificationsScreen(teamId: teamIdOf(state)!),
      ),
      // Chat rooms and announcements open full screen (the input bar must not
      // sit on top of the phone's bottom navigation).
      GoRoute(
        path: '/t/:teamId/chat/:channelId',
        builder: (_, state) => ChatScreen(teamId: teamIdOf(state)!, channelId: idOf(state, 'channelId')),
      ),
      GoRoute(
        path: '/t/:teamId/announcements',
        builder: (_, state) => AnnouncementsScreen(teamId: teamIdOf(state)!),
      ),
      // The music stand: full screen, outside the navigation shell.
      GoRoute(
        path: '/t/:teamId/stand/:sessionId',
        builder: (_, state) => SetlistViewerScreen(
          teamId: teamIdOf(state)!,
          sessionId: idOf(state, 'sessionId'),
          initialItemId: int.tryParse(state.uri.queryParameters['item'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/t/:teamId/sheets/:sheetId',
        builder: (_, state) => SheetPreviewScreen(
          sheetId: idOf(state, 'sheetId'),
          initial: state.extra is Sheet ? state.extra! as Sheet : null,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          teamId: teamIdOf(state)!,
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/t/:teamId/sessions',
            builder: (_, state) => SessionsScreen(teamId: teamIdOf(state)!),
            routes: [
              GoRoute(
                path: ':sessionId',
                builder: (_, state) => SessionScreen(teamId: teamIdOf(state)!, sessionId: idOf(state, 'sessionId')),
              ),
            ],
          ),
          GoRoute(
            path: '/t/:teamId/songs',
            builder: (_, state) => SongsScreen(teamId: teamIdOf(state)!),
            routes: [
              GoRoute(path: 'stats', builder: (_, state) => StatsScreen(teamId: teamIdOf(state)!)),
              GoRoute(
                path: ':songId',
                builder: (_, state) => SongDetailScreen(teamId: teamIdOf(state)!, songId: idOf(state, 'songId')),
              ),
            ],
          ),
          GoRoute(
            path: '/t/:teamId/chat',
            builder: (_, state) => ChannelsScreen(teamId: teamIdOf(state)!),
          ),
          GoRoute(
            path: '/t/:teamId/rotation',
            builder: (_, state) => RotationScreen(teamId: teamIdOf(state)!),
          ),
          GoRoute(
            path: '/t/:teamId/blockouts',
            builder: (_, state) => BlockoutsScreen(teamId: teamIdOf(state)!),
          ),
          GoRoute(
            path: '/t/:teamId/team',
            builder: (_, state) => TeamScreen(teamId: teamIdOf(state)!),
          ),
          GoRoute(
            path: '/t/:teamId/settings',
            builder: (_, state) => SettingsScreen(teamId: teamIdOf(state)!),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
