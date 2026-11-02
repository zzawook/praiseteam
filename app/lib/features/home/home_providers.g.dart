// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Rehearsals in the next four weeks, for to-dos and my schedule.

@ProviderFor(upcomingRehearsals)
final upcomingRehearsalsProvider = UpcomingRehearsalsFamily._();

/// Rehearsals in the next four weeks, for to-dos and my schedule.

final class UpcomingRehearsalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Rehearsal>>,
          List<Rehearsal>,
          FutureOr<List<Rehearsal>>
        >
    with $FutureModifier<List<Rehearsal>>, $FutureProvider<List<Rehearsal>> {
  /// Rehearsals in the next four weeks, for to-dos and my schedule.
  UpcomingRehearsalsProvider._({
    required UpcomingRehearsalsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'upcomingRehearsalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$upcomingRehearsalsHash();

  @override
  String toString() {
    return r'upcomingRehearsalsProvider'
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
    return upcomingRehearsals(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UpcomingRehearsalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$upcomingRehearsalsHash() =>
    r'af46ff1dcb317bf88f2864cca1b5297fe42503b5';

/// Rehearsals in the next four weeks, for to-dos and my schedule.

final class UpcomingRehearsalsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Rehearsal>>, int> {
  UpcomingRehearsalsFamily._()
    : super(
        retry: null,
        name: r'upcomingRehearsalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Rehearsals in the next four weeks, for to-dos and my schedule.

  UpcomingRehearsalsProvider call(int teamId) =>
      UpcomingRehearsalsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'upcomingRehearsalsProvider';
}

/// Times each person was asked to serve (sent requests) in the last 8 weeks.

@ProviderFor(servingCounts)
final servingCountsProvider = ServingCountsFamily._();

/// Times each person was asked to serve (sent requests) in the last 8 weeks.

final class ServingCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, int>>,
          Map<String, int>,
          FutureOr<Map<String, int>>
        >
    with $FutureModifier<Map<String, int>>, $FutureProvider<Map<String, int>> {
  /// Times each person was asked to serve (sent requests) in the last 8 weeks.
  ServingCountsProvider._({
    required ServingCountsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'servingCountsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$servingCountsHash();

  @override
  String toString() {
    return r'servingCountsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, int>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, int>> create(Ref ref) {
    final argument = this.argument as int;
    return servingCounts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ServingCountsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$servingCountsHash() => r'f768b9850045ca97ea3a59eef04954e854e24788';

/// Times each person was asked to serve (sent requests) in the last 8 weeks.

final class ServingCountsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, int>>, int> {
  ServingCountsFamily._()
    : super(
        retry: null,
        name: r'servingCountsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Times each person was asked to serve (sent requests) in the last 8 weeks.

  ServingCountsProvider call(int teamId) =>
      ServingCountsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'servingCountsProvider';
}
