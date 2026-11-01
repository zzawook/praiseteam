// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rotation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(rotationRepository)
final rotationRepositoryProvider = RotationRepositoryProvider._();

final class RotationRepositoryProvider
    extends
        $FunctionalProvider<
          RotationRepository,
          RotationRepository,
          RotationRepository
        >
    with $Provider<RotationRepository> {
  RotationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rotationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rotationRepositoryHash();

  @$internal
  @override
  $ProviderElement<RotationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RotationRepository create(Ref ref) {
    return rotationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RotationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RotationRepository>(value),
    );
  }
}

String _$rotationRepositoryHash() =>
    r'ec46787d0fe0dcf9ec68fc6bcea4d3afbd910876';

@ProviderFor(rotationBoard)
final rotationBoardProvider = RotationBoardFamily._();

final class RotationBoardProvider
    extends
        $FunctionalProvider<
          AsyncValue<RotationBoard>,
          RotationBoard,
          FutureOr<RotationBoard>
        >
    with $FutureModifier<RotationBoard>, $FutureProvider<RotationBoard> {
  RotationBoardProvider._({
    required RotationBoardFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'rotationBoardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$rotationBoardHash();

  @override
  String toString() {
    return r'rotationBoardProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RotationBoard> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RotationBoard> create(Ref ref) {
    final argument = this.argument as int;
    return rotationBoard(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RotationBoardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$rotationBoardHash() => r'9fe34b4acc04bdf422e3877043db5f90a4f74406';

final class RotationBoardFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RotationBoard>, int> {
  RotationBoardFamily._()
    : super(
        retry: null,
        name: r'rotationBoardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RotationBoardProvider call(int teamId) =>
      RotationBoardProvider._(argument: teamId, from: this);

  @override
  String toString() => r'rotationBoardProvider';
}

/// Visible blockouts: your own, and everyone's for leaders (RLS).

@ProviderFor(blockouts)
final blockoutsProvider = BlockoutsFamily._();

/// Visible blockouts: your own, and everyone's for leaders (RLS).

final class BlockoutsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Blockout>>,
          List<Blockout>,
          FutureOr<List<Blockout>>
        >
    with $FutureModifier<List<Blockout>>, $FutureProvider<List<Blockout>> {
  /// Visible blockouts: your own, and everyone's for leaders (RLS).
  BlockoutsProvider._({
    required BlockoutsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'blockoutsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$blockoutsHash();

  @override
  String toString() {
    return r'blockoutsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Blockout>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Blockout>> create(Ref ref) {
    final argument = this.argument as int;
    return blockouts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BlockoutsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$blockoutsHash() => r'05bbf5208423de33ce4cb2a9de0053baa8a6c2b7';

/// Visible blockouts: your own, and everyone's for leaders (RLS).

final class BlockoutsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Blockout>>, int> {
  BlockoutsFamily._()
    : super(
        retry: null,
        name: r'blockoutsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Visible blockouts: your own, and everyone's for leaders (RLS).

  BlockoutsProvider call(int teamId) =>
      BlockoutsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'blockoutsProvider';
}
