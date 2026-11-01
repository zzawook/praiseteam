import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/providers.dart';
import '../auth/auth.dart';
import 'models.dart';
import 'teams_repository.dart';

part 'teams_providers.g.dart';

@Riverpod(keepAlive: true)
TeamsRepository teamsRepository(Ref ref) => TeamsRepository(ref.watch(supabaseProvider));

/// The signed-in user's memberships (pending and active).
@Riverpod(keepAlive: true)
Future<List<Membership>> myMemberships(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(teamsRepositoryProvider).myMemberships(userId);
}

/// Membership in [teamId], if active.
@riverpod
Membership? activeMembership(Ref ref, int teamId) {
  final memberships = ref.watch(myMembershipsProvider).value ?? const [];
  for (final m in memberships) {
    if (m.teamId == teamId && m.isActive) return m;
  }
  return null;
}

@riverpod
Future<List<Member>> teamMembers(Ref ref, int teamId) =>
    ref.watch(teamsRepositoryProvider).members(teamId);

@riverpod
Future<List<Part>> teamParts(Ref ref, int teamId) =>
    ref.watch(teamsRepositoryProvider).parts(teamId);

/// The last team the user opened, so the app reopens there.
@Riverpod(keepAlive: true)
class LastTeam extends _$LastTeam {
  static const _key = 'last_team_id';

  @override
  int? build() => ref.watch(sharedPreferencesProvider).getInt(_key);

  void remember(int teamId) {
    if (state == teamId) return;
    ref.read(sharedPreferencesProvider).setInt(_key, teamId);
    state = teamId;
  }
}
