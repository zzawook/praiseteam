// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'songs_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(songsRepository)
final songsRepositoryProvider = SongsRepositoryProvider._();

final class SongsRepositoryProvider
    extends
        $FunctionalProvider<SongsRepository, SongsRepository, SongsRepository>
    with $Provider<SongsRepository> {
  SongsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'songsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$songsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SongsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SongsRepository create(Ref ref) {
    return songsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SongsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SongsRepository>(value),
    );
  }
}

String _$songsRepositoryHash() => r'ec98047322e3965f0a009ed4410ac5db43e686a9';

@ProviderFor(songLibrary)
final songLibraryProvider = SongLibraryFamily._();

final class SongLibraryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SongEntry>>,
          List<SongEntry>,
          FutureOr<List<SongEntry>>
        >
    with $FutureModifier<List<SongEntry>>, $FutureProvider<List<SongEntry>> {
  SongLibraryProvider._({
    required SongLibraryFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'songLibraryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$songLibraryHash();

  @override
  String toString() {
    return r'songLibraryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SongEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SongEntry>> create(Ref ref) {
    final argument = this.argument as int;
    return songLibrary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SongLibraryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$songLibraryHash() => r'd17e3e57459a9a18bb94ad012eea457d519e8ef0';

final class SongLibraryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<SongEntry>>, int> {
  SongLibraryFamily._()
    : super(
        retry: null,
        name: r'songLibraryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SongLibraryProvider call(int teamId) =>
      SongLibraryProvider._(argument: teamId, from: this);

  @override
  String toString() => r'songLibraryProvider';
}

@ProviderFor(songDetail)
final songDetailProvider = SongDetailFamily._();

final class SongDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<SongDetail>,
          SongDetail,
          FutureOr<SongDetail>
        >
    with $FutureModifier<SongDetail>, $FutureProvider<SongDetail> {
  SongDetailProvider._({
    required SongDetailFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'songDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$songDetailHash();

  @override
  String toString() {
    return r'songDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SongDetail> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<SongDetail> create(Ref ref) {
    final argument = this.argument as int;
    return songDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SongDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$songDetailHash() => r'72df73fcceaaf8de8906ff9d388cd0b840fd4ee5';

final class SongDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SongDetail>, int> {
  SongDetailFamily._()
    : super(
        retry: null,
        name: r'songDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SongDetailProvider call(int songId) =>
      SongDetailProvider._(argument: songId, from: this);

  @override
  String toString() => r'songDetailProvider';
}

@ProviderFor(songSheets)
final songSheetsProvider = SongSheetsFamily._();

final class SongSheetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Sheet>>,
          List<Sheet>,
          FutureOr<List<Sheet>>
        >
    with $FutureModifier<List<Sheet>>, $FutureProvider<List<Sheet>> {
  SongSheetsProvider._({
    required SongSheetsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'songSheetsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$songSheetsHash();

  @override
  String toString() {
    return r'songSheetsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Sheet>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Sheet>> create(Ref ref) {
    final argument = this.argument as int;
    return songSheets(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SongSheetsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$songSheetsHash() => r'c7d67c2f64568d6f8a9e5d590e5de5fe7105bc88';

final class SongSheetsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Sheet>>, int> {
  SongSheetsFamily._()
    : super(
        retry: null,
        name: r'songSheetsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SongSheetsProvider call(int songId) =>
      SongSheetsProvider._(argument: songId, from: this);

  @override
  String toString() => r'songSheetsProvider';
}

@ProviderFor(sheet)
final sheetProvider = SheetFamily._();

final class SheetProvider
    extends $FunctionalProvider<AsyncValue<Sheet>, Sheet, FutureOr<Sheet>>
    with $FutureModifier<Sheet>, $FutureProvider<Sheet> {
  SheetProvider._({
    required SheetFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'sheetProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sheetHash();

  @override
  String toString() {
    return r'sheetProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Sheet> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Sheet> create(Ref ref) {
    final argument = this.argument as int;
    return sheet(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SheetProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sheetHash() => r'ca871619ed0c4f2be0420dfb8f1f6c65af4fa55f';

final class SheetFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Sheet>, int> {
  SheetFamily._()
    : super(
        retry: null,
        name: r'sheetProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SheetProvider call(int sheetId) =>
      SheetProvider._(argument: sheetId, from: this);

  @override
  String toString() => r'sheetProvider';
}

/// PDF bytes, kept for the session (sheet files never change in place:
/// a new upload gets a new path).

@ProviderFor(sheetBytes)
final sheetBytesProvider = SheetBytesFamily._();

/// PDF bytes, kept for the session (sheet files never change in place:
/// a new upload gets a new path).

final class SheetBytesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Uint8List>,
          Uint8List,
          FutureOr<Uint8List>
        >
    with $FutureModifier<Uint8List>, $FutureProvider<Uint8List> {
  /// PDF bytes, kept for the session (sheet files never change in place:
  /// a new upload gets a new path).
  SheetBytesProvider._({
    required SheetBytesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sheetBytesProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sheetBytesHash();

  @override
  String toString() {
    return r'sheetBytesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Uint8List> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Uint8List> create(Ref ref) {
    final argument = this.argument as String;
    return sheetBytes(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SheetBytesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sheetBytesHash() => r'829a90c0b00dae85b1925b9e579479b244904e67';

/// PDF bytes, kept for the session (sheet files never change in place:
/// a new upload gets a new path).

final class SheetBytesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Uint8List>, String> {
  SheetBytesFamily._()
    : super(
        retry: null,
        name: r'sheetBytesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// PDF bytes, kept for the session (sheet files never change in place:
  /// a new upload gets a new path).

  SheetBytesProvider call(String storagePath) =>
      SheetBytesProvider._(argument: storagePath, from: this);

  @override
  String toString() => r'sheetBytesProvider';
}

@ProviderFor(topSongs)
final topSongsProvider = TopSongsFamily._();

final class TopSongsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TopSong>>,
          List<TopSong>,
          FutureOr<List<TopSong>>
        >
    with $FutureModifier<List<TopSong>>, $FutureProvider<List<TopSong>> {
  TopSongsProvider._({
    required TopSongsFamily super.from,
    required (int, StatsPeriod) super.argument,
  }) : super(
         retry: null,
         name: r'topSongsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$topSongsHash();

  @override
  String toString() {
    return r'topSongsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<TopSong>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TopSong>> create(Ref ref) {
    final argument = this.argument as (int, StatsPeriod);
    return topSongs(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is TopSongsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$topSongsHash() => r'7c6e7f66711653384adb39acf9406c81207f7b8a';

final class TopSongsFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<TopSong>>, (int, StatsPeriod)> {
  TopSongsFamily._()
    : super(
        retry: null,
        name: r'topSongsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TopSongsProvider call(int teamId, StatsPeriod period) =>
      TopSongsProvider._(argument: (teamId, period), from: this);

  @override
  String toString() => r'topSongsProvider';
}
