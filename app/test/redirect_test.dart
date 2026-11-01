import 'package:flutter_test/flutter_test.dart';
import 'package:praiseteam/app/redirect.dart';
import 'package:praiseteam/features/teams/models.dart';

Membership membership(int teamId, MemberStatus status) => Membership(
      teamId: teamId,
      role: TeamRole.member,
      status: status,
      team: Team(id: teamId, name: 'T$teamId', timezone: 'Asia/Singapore', inviteCode: 'ABCDEFGH', joinRequiresApproval: true),
    );

String? redirect(
  String location, {
  bool signedIn = true,
  bool loading = false,
  bool failed = false,
  List<Membership> memberships = const [],
  int? lastTeamId,
  int? routeTeamId,
}) =>
    resolveRedirect(
      uri: Uri.parse(location),
      signedIn: signedIn,
      membershipsLoading: loading,
      membershipsFailed: failed,
      memberships: memberships,
      lastTeamId: lastTeamId,
      routeTeamId: routeTeamId,
    );

void main() {
  final active1 = [membership(1, MemberStatus.active)];

  test('signed out goes to login, remembering where they were headed', () {
    expect(redirect('/t/1/sessions/9', signedIn: false), '/login?from=%2Ft%2F1%2Fsessions%2F9');
    expect(redirect('/login', signedIn: false), isNull);
    expect(redirect('/', signedIn: false), '/login');
  });

  test('waits on splash while memberships load or failed', () {
    expect(redirect('/login?from=%2Ft%2F1%2Fteam', loading: true), '/splash?from=%2Ft%2F1%2Fteam');
    expect(redirect('/splash', failed: true), isNull);
  });

  test('no team: welcome; pending only: pending page', () {
    expect(redirect('/'), '/welcome');
    expect(redirect('/', memberships: [membership(1, MemberStatus.pending)]), '/pending');
    expect(redirect('/welcome', memberships: [membership(1, MemberStatus.pending)]), isNull,
        reason: 'joining another team stays possible while pending');
  });

  test('active member lands on the last opened team, else the first', () {
    final both = [membership(1, MemberStatus.active), membership(2, MemberStatus.active)];
    expect(redirect('/', memberships: both, lastTeamId: 2), '/t/2/home');
    expect(redirect('/login', memberships: both, lastTeamId: 99), '/t/1/home');
  });

  test('restores the original destination after sign-in and loading', () {
    expect(redirect('/splash?from=%2Ft%2F1%2Fteam', memberships: active1), '/t/1/team');
    expect(redirect('/login?from=%2Ft%2F1%2Fsessions%2F9', memberships: active1), '/t/1/sessions/9');
  });

  test('does not restore a destination in a team the user is not active in', () {
    expect(redirect('/splash?from=%2Ft%2F5%2Fteam', memberships: active1), '/t/1/home');
    expect(redirect('/splash?from=https%3A%2F%2Fevil.example', memberships: active1), '/t/1/home');
    expect(redirect('/splash?from=%2F%2Fevil.example%2Ft%2F1%2Fteam', memberships: active1), '/t/1/home');
  });

  test('a team route the user is not active in is replaced', () {
    final ms = [membership(1, MemberStatus.active), membership(3, MemberStatus.pending)];
    expect(redirect('/t/3/team', memberships: ms, routeTeamId: 3), '/t/1/home');
    expect(redirect('/t/1/settings', memberships: ms, routeTeamId: 1), isNull);
  });
}
