// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teams_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teamTime)
final teamTimeProvider = TeamTimeFamily._();

final class TeamTimeProvider
    extends $FunctionalProvider<TeamTime, TeamTime, TeamTime>
    with $Provider<TeamTime> {
  TeamTimeProvider._({
    required TeamTimeFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'teamTimeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamTimeHash();

  @override
  String toString() {
    return r'teamTimeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TeamTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeamTime create(Ref ref) {
    final argument = this.argument as int;
    return teamTime(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamTime>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TeamTimeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamTimeHash() => r'c0b5be4cd32ba5f87728cde30588f8f5e8d093d4';

final class TeamTimeFamily extends $Family
    with $FunctionalFamilyOverride<TeamTime, int> {
  TeamTimeFamily._()
    : super(
        retry: null,
        name: r'teamTimeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TeamTimeProvider call(int teamId) =>
      TeamTimeProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamTimeProvider';
}

@ProviderFor(teamsRepository)
final teamsRepositoryProvider = TeamsRepositoryProvider._();

final class TeamsRepositoryProvider
    extends
        $FunctionalProvider<TeamsRepository, TeamsRepository, TeamsRepository>
    with $Provider<TeamsRepository> {
  TeamsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamsRepositoryHash();

  @$internal
  @override
  $ProviderElement<TeamsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeamsRepository create(Ref ref) {
    return teamsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamsRepository>(value),
    );
  }
}

String _$teamsRepositoryHash() => r'75946a12b47672cef842f1bd86388f30f4321b7b';

/// The signed-in user's memberships (pending and active).

@ProviderFor(myMemberships)
final myMembershipsProvider = MyMembershipsProvider._();

/// The signed-in user's memberships (pending and active).

final class MyMembershipsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Membership>>,
          List<Membership>,
          FutureOr<List<Membership>>
        >
    with $FutureModifier<List<Membership>>, $FutureProvider<List<Membership>> {
  /// The signed-in user's memberships (pending and active).
  MyMembershipsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myMembershipsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myMembershipsHash();

  @$internal
  @override
  $FutureProviderElement<List<Membership>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Membership>> create(Ref ref) {
    return myMemberships(ref);
  }
}

String _$myMembershipsHash() => r'fab88ade5fc02f6fdbbab270d718ec787149509a';

/// Membership in [teamId], if active.

@ProviderFor(activeMembership)
final activeMembershipProvider = ActiveMembershipFamily._();

/// Membership in [teamId], if active.

final class ActiveMembershipProvider
    extends $FunctionalProvider<Membership?, Membership?, Membership?>
    with $Provider<Membership?> {
  /// Membership in [teamId], if active.
  ActiveMembershipProvider._({
    required ActiveMembershipFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'activeMembershipProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeMembershipHash();

  @override
  String toString() {
    return r'activeMembershipProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Membership?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Membership? create(Ref ref) {
    final argument = this.argument as int;
    return activeMembership(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Membership? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Membership?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveMembershipProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeMembershipHash() => r'575305a5828831417718ca883c8659591e6caefa';

/// Membership in [teamId], if active.

final class ActiveMembershipFamily extends $Family
    with $FunctionalFamilyOverride<Membership?, int> {
  ActiveMembershipFamily._()
    : super(
        retry: null,
        name: r'activeMembershipProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Membership in [teamId], if active.

  ActiveMembershipProvider call(int teamId) =>
      ActiveMembershipProvider._(argument: teamId, from: this);

  @override
  String toString() => r'activeMembershipProvider';
}

@ProviderFor(teamMembers)
final teamMembersProvider = TeamMembersFamily._();

final class TeamMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Member>>,
          List<Member>,
          FutureOr<List<Member>>
        >
    with $FutureModifier<List<Member>>, $FutureProvider<List<Member>> {
  TeamMembersProvider._({
    required TeamMembersFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'teamMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamMembersHash();

  @override
  String toString() {
    return r'teamMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Member>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Member>> create(Ref ref) {
    final argument = this.argument as int;
    return teamMembers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamMembersHash() => r'726691269aab2fc2b5ffc4c55732f07117ca2520';

final class TeamMembersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Member>>, int> {
  TeamMembersFamily._()
    : super(
        retry: null,
        name: r'teamMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TeamMembersProvider call(int teamId) =>
      TeamMembersProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamMembersProvider';
}

@ProviderFor(teamParts)
final teamPartsProvider = TeamPartsFamily._();

final class TeamPartsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Part>>,
          List<Part>,
          FutureOr<List<Part>>
        >
    with $FutureModifier<List<Part>>, $FutureProvider<List<Part>> {
  TeamPartsProvider._({
    required TeamPartsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'teamPartsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamPartsHash();

  @override
  String toString() {
    return r'teamPartsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Part>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Part>> create(Ref ref) {
    final argument = this.argument as int;
    return teamParts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamPartsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamPartsHash() => r'2372c32c8a39f460ea056ac8d4b4b068338ec3ed';

final class TeamPartsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Part>>, int> {
  TeamPartsFamily._()
    : super(
        retry: null,
        name: r'teamPartsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TeamPartsProvider call(int teamId) =>
      TeamPartsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamPartsProvider';
}

/// The last team the user opened, so the app reopens there.

@ProviderFor(LastTeam)
final lastTeamProvider = LastTeamProvider._();

/// The last team the user opened, so the app reopens there.
final class LastTeamProvider extends $NotifierProvider<LastTeam, int?> {
  /// The last team the user opened, so the app reopens there.
  LastTeamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastTeamProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastTeamHash();

  @$internal
  @override
  LastTeam create() => LastTeam();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$lastTeamHash() => r'69660004c279ee8ee06496ae627a0ce0e8a92962';

/// The last team the user opened, so the app reopens there.

abstract class _$LastTeam extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
