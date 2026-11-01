import '../features/teams/models.dart';

const _entryPoints = {'/', '/login', '/splash', '/pending'};

/// Where a user may be. Pure so it can be tested without widgets (see
/// test/redirect_test.dart). Returns the location to go to, or null to stay.
///
/// The original destination (a shared link, a tapped notification) is
/// carried through /login and /splash as `?from=` and restored once the
/// user is signed in and their teams are loaded.
String? resolveRedirect({
  required Uri uri,
  required bool signedIn,
  required bool membershipsLoading,
  required bool membershipsFailed,
  required List<Membership> memberships,
  int? lastTeamId,
  int? routeTeamId,
}) {
  final location = uri.path;
  final from = uri.queryParameters['from'];

  String via(String target) {
    final original = from ?? (_entryPoints.contains(location) || location == '/welcome' ? null : uri.toString());
    return original == null ? target : Uri(path: target, queryParameters: {'from': original}).toString();
  }

  if (!signedIn) return location == '/login' ? null : via('/login');
  if (membershipsLoading || membershipsFailed) return location == '/splash' ? null : via('/splash');

  final active = memberships.where((m) => m.isActive).toList();
  if (active.isEmpty) {
    // Joining or creating is always allowed; otherwise wait for approval.
    if (location == '/welcome') return null;
    final hasPending = memberships.any((m) => m.status == MemberStatus.pending);
    final target = hasPending ? '/pending' : '/welcome';
    return location == target ? null : target;
  }

  bool isActiveTeam(int? id) => id != null && active.any((m) => m.teamId == id);
  String home() => '/t/${isActiveTeam(lastTeamId) ? lastTeamId : active.first.teamId}/home';

  if (_entryPoints.contains(location)) {
    final target = from == null ? null : Uri.tryParse(from);
    // In-app paths only: no scheme or host, so `from` can't leave the app.
    final inApp = target != null && !target.hasScheme && !target.hasAuthority;
    final segments = inApp ? target.pathSegments : const <String>[];
    if (segments.length >= 3 && segments[0] == 't' && isActiveTeam(int.tryParse(segments[1]))) {
      return from;
    }
    return home();
  }

  if (routeTeamId != null && !isActiveTeam(routeTeamId)) return home();
  return null;
}
