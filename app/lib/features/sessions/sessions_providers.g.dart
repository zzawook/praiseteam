// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sessions_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionsRepository)
final sessionsRepositoryProvider = SessionsRepositoryProvider._();

final class SessionsRepositoryProvider
    extends
        $FunctionalProvider<
          SessionsRepository,
          SessionsRepository,
          SessionsRepository
        >
    with $Provider<SessionsRepository> {
  SessionsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SessionsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SessionsRepository create(Ref ref) {
    return sessionsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionsRepository>(value),
    );
  }
}

String _$sessionsRepositoryHash() =>
    r'6b407896506ebe4372b9c89db1b3753f58b8c3ca';

@ProviderFor(upcomingSessions)
final upcomingSessionsProvider = UpcomingSessionsFamily._();

final class UpcomingSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Session>>,
          List<Session>,
          FutureOr<List<Session>>
        >
    with $FutureModifier<List<Session>>, $FutureProvider<List<Session>> {
  UpcomingSessionsProvider._({
    required UpcomingSessionsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'upcomingSessionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$upcomingSessionsHash();

  @override
  String toString() {
    return r'upcomingSessionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Session>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Session>> create(Ref ref) {
    final argument = this.argument as int;
    return upcomingSessions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UpcomingSessionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$upcomingSessionsHash() => r'513e6840edcf05b172c2a1c290ed58fb6c8f3590';

final class UpcomingSessionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Session>>, int> {
  UpcomingSessionsFamily._()
    : super(
        retry: null,
        name: r'upcomingSessionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UpcomingSessionsProvider call(int teamId) =>
      UpcomingSessionsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'upcomingSessionsProvider';
}

@ProviderFor(pastSessions)
final pastSessionsProvider = PastSessionsFamily._();

final class PastSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Session>>,
          List<Session>,
          FutureOr<List<Session>>
        >
    with $FutureModifier<List<Session>>, $FutureProvider<List<Session>> {
  PastSessionsProvider._({
    required PastSessionsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'pastSessionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pastSessionsHash();

  @override
  String toString() {
    return r'pastSessionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Session>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Session>> create(Ref ref) {
    final argument = this.argument as int;
    return pastSessions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PastSessionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pastSessionsHash() => r'38d9b79ac2b77f347ae08cd3d490749e1dd70974';

final class PastSessionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Session>>, int> {
  PastSessionsFamily._()
    : super(
        retry: null,
        name: r'pastSessionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PastSessionsProvider call(int teamId) =>
      PastSessionsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'pastSessionsProvider';
}

@ProviderFor(session)
final sessionProvider = SessionFamily._();

final class SessionProvider
    extends $FunctionalProvider<AsyncValue<Session>, Session, FutureOr<Session>>
    with $FutureModifier<Session>, $FutureProvider<Session> {
  SessionProvider._({
    required SessionFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'sessionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionHash();

  @override
  String toString() {
    return r'sessionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Session> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Session> create(Ref ref) {
    final argument = this.argument as int;
    return session(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionHash() => r'144791e9cf3db2b7375d7a1347f27e6857a38c66';

final class SessionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Session>, int> {
  SessionFamily._()
    : super(
        retry: null,
        name: r'sessionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SessionProvider call(int sessionId) =>
      SessionProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'sessionProvider';
}

@ProviderFor(sessionTemplates)
final sessionTemplatesProvider = SessionTemplatesFamily._();

final class SessionTemplatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SessionTemplate>>,
          List<SessionTemplate>,
          FutureOr<List<SessionTemplate>>
        >
    with
        $FutureModifier<List<SessionTemplate>>,
        $FutureProvider<List<SessionTemplate>> {
  SessionTemplatesProvider._({
    required SessionTemplatesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'sessionTemplatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionTemplatesHash();

  @override
  String toString() {
    return r'sessionTemplatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SessionTemplate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SessionTemplate>> create(Ref ref) {
    final argument = this.argument as int;
    return sessionTemplates(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionTemplatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionTemplatesHash() => r'4a6bff8920e225da0d2983a60bcd05587a9aeeb6';

final class SessionTemplatesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<SessionTemplate>>, int> {
  SessionTemplatesFamily._()
    : super(
        retry: null,
        name: r'sessionTemplatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SessionTemplatesProvider call(int teamId) =>
      SessionTemplatesProvider._(argument: teamId, from: this);

  @override
  String toString() => r'sessionTemplatesProvider';
}

@ProviderFor(setlist)
final setlistProvider = SetlistFamily._();

final class SetlistProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SetlistItem>>,
          List<SetlistItem>,
          FutureOr<List<SetlistItem>>
        >
    with
        $FutureModifier<List<SetlistItem>>,
        $FutureProvider<List<SetlistItem>> {
  SetlistProvider._({
    required SetlistFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'setlistProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$setlistHash();

  @override
  String toString() {
    return r'setlistProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SetlistItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SetlistItem>> create(Ref ref) {
    final argument = this.argument as int;
    return setlist(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SetlistProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$setlistHash() => r'a5b8aeb82c7838c4a016cb29fd5692a574523623';

final class SetlistFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<SetlistItem>>, int> {
  SetlistFamily._()
    : super(
        retry: null,
        name: r'setlistProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SetlistProvider call(int sessionId) =>
      SetlistProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'setlistProvider';
}
