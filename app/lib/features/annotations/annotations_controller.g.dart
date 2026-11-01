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
    r'a935885e4f3f9677357b8e69989fd8996200efbe';

/// Strokes of one session, by id, kept in sync with the server.
///
/// Local changes apply at once and go to the [StrokeOutbox], which keeps
/// them on the device until the server has them. What the screen shows is
/// the server's strokes (or the saved copy, offline) with the waiting
/// changes applied on top, so notes drawn offline stay visible after a
/// restart.

@ProviderFor(SessionInk)
final sessionInkProvider = SessionInkFamily._();

/// Strokes of one session, by id, kept in sync with the server.
///
/// Local changes apply at once and go to the [StrokeOutbox], which keeps
/// them on the device until the server has them. What the screen shows is
/// the server's strokes (or the saved copy, offline) with the waiting
/// changes applied on top, so notes drawn offline stay visible after a
/// restart.
final class SessionInkProvider
    extends $AsyncNotifierProvider<SessionInk, Map<String, InkStroke>> {
  /// Strokes of one session, by id, kept in sync with the server.
  ///
  /// Local changes apply at once and go to the [StrokeOutbox], which keeps
  /// them on the device until the server has them. What the screen shows is
  /// the server's strokes (or the saved copy, offline) with the waiting
  /// changes applied on top, so notes drawn offline stay visible after a
  /// restart.
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

String _$sessionInkHash() => r'7324629f1c5a9ef26dc3c05a0fd498f6875e1a60';

/// Strokes of one session, by id, kept in sync with the server.
///
/// Local changes apply at once and go to the [StrokeOutbox], which keeps
/// them on the device until the server has them. What the screen shows is
/// the server's strokes (or the saved copy, offline) with the waiting
/// changes applied on top, so notes drawn offline stay visible after a
/// restart.

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
  /// Local changes apply at once and go to the [StrokeOutbox], which keeps
  /// them on the device until the server has them. What the screen shows is
  /// the server's strokes (or the saved copy, offline) with the waiting
  /// changes applied on top, so notes drawn offline stay visible after a
  /// restart.

  SessionInkProvider call(int sessionId) =>
      SessionInkProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'sessionInkProvider';
}

/// Strokes of one session, by id, kept in sync with the server.
///
/// Local changes apply at once and go to the [StrokeOutbox], which keeps
/// them on the device until the server has them. What the screen shows is
/// the server's strokes (or the saved copy, offline) with the waiting
/// changes applied on top, so notes drawn offline stay visible after a
/// restart.

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
