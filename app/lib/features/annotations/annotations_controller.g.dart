// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'annotations_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(annotationsRepository)
final annotationsRepositoryProvider = AnnotationsRepositoryProvider._();

final class AnnotationsRepositoryProvider
    extends
        $FunctionalProvider<
          AnnotationsRepository,
          AnnotationsRepository,
          AnnotationsRepository
        >
    with $Provider<AnnotationsRepository> {
  AnnotationsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'annotationsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$annotationsRepositoryHash();

  @$internal
  @override
  $ProviderElement<AnnotationsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AnnotationsRepository create(Ref ref) {
    return annotationsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnnotationsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnnotationsRepository>(value),
    );
  }
}

String _$annotationsRepositoryHash() =>
    r'4359a75b716b5bfbf64a26a1df46d4e36680f590';

/// Strokes of one session, by id, kept in sync with the server.
///
/// Local changes apply immediately and are sent in the background; failed
/// sends stay queued and are retried, in order, every few seconds. Because
/// strokes are immutable (insert, or set deleted_at) and ids come from the
/// device, a retry can never duplicate or conflict with anything.

@ProviderFor(SessionInk)
final sessionInkProvider = SessionInkFamily._();

/// Strokes of one session, by id, kept in sync with the server.
///
/// Local changes apply immediately and are sent in the background; failed
/// sends stay queued and are retried, in order, every few seconds. Because
/// strokes are immutable (insert, or set deleted_at) and ids come from the
/// device, a retry can never duplicate or conflict with anything.
final class SessionInkProvider
    extends $AsyncNotifierProvider<SessionInk, Map<String, InkStroke>> {
  /// Strokes of one session, by id, kept in sync with the server.
  ///
  /// Local changes apply immediately and are sent in the background; failed
  /// sends stay queued and are retried, in order, every few seconds. Because
  /// strokes are immutable (insert, or set deleted_at) and ids come from the
  /// device, a retry can never duplicate or conflict with anything.
  SessionInkProvider._({
    required SessionInkFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'sessionInkProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionInkHash();

  @override
  String toString() {
    return r'sessionInkProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SessionInk create() => SessionInk();

  @override
  bool operator ==(Object other) {
    return other is SessionInkProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionInkHash() => r'c83b7158c5cad52f21fb44cc7d0d4e1615d4634f';

/// Strokes of one session, by id, kept in sync with the server.
///
/// Local changes apply immediately and are sent in the background; failed
/// sends stay queued and are retried, in order, every few seconds. Because
/// strokes are immutable (insert, or set deleted_at) and ids come from the
/// device, a retry can never duplicate or conflict with anything.

final class SessionInkFamily extends $Family
    with
        $ClassFamilyOverride<
          SessionInk,
          AsyncValue<Map<String, InkStroke>>,
          Map<String, InkStroke>,
          FutureOr<Map<String, InkStroke>>,
          int
        > {
  SessionInkFamily._()
    : super(
        retry: null,
        name: r'sessionInkProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Strokes of one session, by id, kept in sync with the server.
  ///
  /// Local changes apply immediately and are sent in the background; failed
  /// sends stay queued and are retried, in order, every few seconds. Because
  /// strokes are immutable (insert, or set deleted_at) and ids come from the
  /// device, a retry can never duplicate or conflict with anything.

  SessionInkProvider call(int sessionId) =>
      SessionInkProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'sessionInkProvider';
}

/// Strokes of one session, by id, kept in sync with the server.
///
/// Local changes apply immediately and are sent in the background; failed
/// sends stay queued and are retried, in order, every few seconds. Because
/// strokes are immutable (insert, or set deleted_at) and ids come from the
/// device, a retry can never duplicate or conflict with anything.

abstract class _$SessionInk extends $AsyncNotifier<Map<String, InkStroke>> {
  late final _$args = ref.$arg as int;
  int get sessionId => _$args;

  FutureOr<Map<String, InkStroke>> build(int sessionId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<Map<String, InkStroke>>, Map<String, InkStroke>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, InkStroke>>,
                Map<String, InkStroke>
              >,
              AsyncValue<Map<String, InkStroke>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
