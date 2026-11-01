// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rehearsals.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(rehearsalsRepository)
final rehearsalsRepositoryProvider = RehearsalsRepositoryProvider._();

final class RehearsalsRepositoryProvider
    extends
        $FunctionalProvider<
          RehearsalsRepository,
          RehearsalsRepository,
          RehearsalsRepository
        >
    with $Provider<RehearsalsRepository> {
  RehearsalsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rehearsalsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rehearsalsRepositoryHash();

  @$internal
  @override
  $ProviderElement<RehearsalsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RehearsalsRepository create(Ref ref) {
    return rehearsalsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RehearsalsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RehearsalsRepository>(value),
    );
  }
}

String _$rehearsalsRepositoryHash() =>
    r'3da67a21f8a7bf996ee916e3dd3305c565ff5439';

@ProviderFor(sessionRehearsals)
final sessionRehearsalsProvider = SessionRehearsalsFamily._();

final class SessionRehearsalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Rehearsal>>,
          List<Rehearsal>,
          FutureOr<List<Rehearsal>>
        >
    with $FutureModifier<List<Rehearsal>>, $FutureProvider<List<Rehearsal>> {
  SessionRehearsalsProvider._({
    required SessionRehearsalsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'sessionRehearsalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionRehearsalsHash();

  @override
  String toString() {
    return r'sessionRehearsalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Rehearsal>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Rehearsal>> create(Ref ref) {
    final argument = this.argument as int;
    return sessionRehearsals(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionRehearsalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionRehearsalsHash() => r'750b4c199bcc5ef2b4978461f902a2b6327a502c';

final class SessionRehearsalsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Rehearsal>>, int> {
  SessionRehearsalsFamily._()
    : super(
        retry: null,
        name: r'sessionRehearsalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SessionRehearsalsProvider call(int sessionId) =>
      SessionRehearsalsProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'sessionRehearsalsProvider';
}
