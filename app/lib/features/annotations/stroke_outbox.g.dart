// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stroke_outbox.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Note changes that have not reached the server yet, oldest first.
///
/// Kept on the device, so notes drawn without a connection survive a
/// restart and go up once the server is reachable. Strokes are immutable
/// with ids made on the device, so sending one twice changes nothing. A
/// change the server refuses (for example, its author left the team) can
/// never succeed and is dropped; a change that fails for want of a
/// connection waits for the connection to come back.
///
/// The state is the number of changes waiting.

@ProviderFor(StrokeOutbox)
final strokeOutboxProvider = StrokeOutboxProvider._();

/// Note changes that have not reached the server yet, oldest first.
///
/// Kept on the device, so notes drawn without a connection survive a
/// restart and go up once the server is reachable. Strokes are immutable
/// with ids made on the device, so sending one twice changes nothing. A
/// change the server refuses (for example, its author left the team) can
/// never succeed and is dropped; a change that fails for want of a
/// connection waits for the connection to come back.
///
/// The state is the number of changes waiting.
final class StrokeOutboxProvider extends $NotifierProvider<StrokeOutbox, int> {
  /// Note changes that have not reached the server yet, oldest first.
  ///
  /// Kept on the device, so notes drawn without a connection survive a
  /// restart and go up once the server is reachable. Strokes are immutable
  /// with ids made on the device, so sending one twice changes nothing. A
  /// change the server refuses (for example, its author left the team) can
  /// never succeed and is dropped; a change that fails for want of a
  /// connection waits for the connection to come back.
  ///
  /// The state is the number of changes waiting.
  StrokeOutboxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'strokeOutboxProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$strokeOutboxHash();

  @$internal
  @override
  StrokeOutbox create() => StrokeOutbox();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$strokeOutboxHash() => r'ded5772a6b55eb2e6f4c4a5a41d3e6c0fbc09714';

/// Note changes that have not reached the server yet, oldest first.
///
/// Kept on the device, so notes drawn without a connection survive a
/// restart and go up once the server is reachable. Strokes are immutable
/// with ids made on the device, so sending one twice changes nothing. A
/// change the server refuses (for example, its author left the team) can
/// never succeed and is dropped; a change that fails for want of a
/// connection waits for the connection to come back.
///
/// The state is the number of changes waiting.

abstract class _$StrokeOutbox extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
