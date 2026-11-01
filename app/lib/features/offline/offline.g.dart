// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reads for the signed-in user that keep working offline (see
/// [ReadThrough]). Saved answers belong to the user who fetched them.

@ProviderFor(readThrough)
final readThroughProvider = ReadThroughProvider._();

/// Reads for the signed-in user that keep working offline (see
/// [ReadThrough]). Saved answers belong to the user who fetched them.

final class ReadThroughProvider
    extends $FunctionalProvider<ReadThrough, ReadThrough, ReadThrough>
    with $Provider<ReadThrough> {
  /// Reads for the signed-in user that keep working offline (see
  /// [ReadThrough]). Saved answers belong to the user who fetched them.
  ReadThroughProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readThroughProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readThroughHash();

  @$internal
  @override
  $ProviderElement<ReadThrough> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReadThrough create(Ref ref) {
    return readThrough(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReadThrough value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReadThrough>(value),
    );
  }
}

String _$readThroughHash() => r'7ea98d3f247fa8c469fa652d6f69f3fafe51f845';
