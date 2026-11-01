// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setlist_viewer_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sheets used by a session's setlist, by id.

@ProviderFor(sessionSheets)
final sessionSheetsProvider = SessionSheetsFamily._();

/// Sheets used by a session's setlist, by id.

final class SessionSheetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<int, Sheet>>,
          Map<int, Sheet>,
          FutureOr<Map<int, Sheet>>
        >
    with $FutureModifier<Map<int, Sheet>>, $FutureProvider<Map<int, Sheet>> {
  /// Sheets used by a session's setlist, by id.
  SessionSheetsProvider._({
    required SessionSheetsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'sessionSheetsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionSheetsHash();

  @override
  String toString() {
    return r'sessionSheetsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<int, Sheet>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<int, Sheet>> create(Ref ref) {
    final argument = this.argument as int;
    return sessionSheets(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionSheetsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionSheetsHash() => r'6b9d3a046c06247edf32fb9ba5b36651b92d5774';

/// Sheets used by a session's setlist, by id.

final class SessionSheetsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<int, Sheet>>, int> {
  SessionSheetsFamily._()
    : super(
        retry: null,
        name: r'sessionSheetsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Sheets used by a session's setlist, by id.

  SessionSheetsProvider call(int sessionId) =>
      SessionSheetsProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'sessionSheetsProvider';
}
