// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prefetch.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps what the music stand needs on the device: every service in the
/// next 7 days and every upcoming service I serve at, with its setlist,
/// sheets (the PDFs too), notes and rehearsals. Runs after sign-in and again each time
/// the connection comes back. The value is how many services are ready.

@ProviderFor(offlinePrefetch)
final offlinePrefetchProvider = OfflinePrefetchProvider._();

/// Keeps what the music stand needs on the device: every service in the
/// next 7 days and every upcoming service I serve at, with its setlist,
/// sheets (the PDFs too), notes and rehearsals. Runs after sign-in and again each time
/// the connection comes back. The value is how many services are ready.

final class OfflinePrefetchProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Keeps what the music stand needs on the device: every service in the
  /// next 7 days and every upcoming service I serve at, with its setlist,
  /// sheets (the PDFs too), notes and rehearsals. Runs after sign-in and again each time
  /// the connection comes back. The value is how many services are ready.
  OfflinePrefetchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offlinePrefetchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offlinePrefetchHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return offlinePrefetch(ref);
  }
}

String _$offlinePrefetchHash() => r'3ebffb637afc79b86cd6ae8722ef37bfe591d1ff';
