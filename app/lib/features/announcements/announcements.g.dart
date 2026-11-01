// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcements.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(announcementsRepository)
final announcementsRepositoryProvider = AnnouncementsRepositoryProvider._();

final class AnnouncementsRepositoryProvider
    extends
        $FunctionalProvider<
          AnnouncementsRepository,
          AnnouncementsRepository,
          AnnouncementsRepository
        >
    with $Provider<AnnouncementsRepository> {
  AnnouncementsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'announcementsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$announcementsRepositoryHash();

  @$internal
  @override
  $ProviderElement<AnnouncementsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AnnouncementsRepository create(Ref ref) {
    return announcementsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnnouncementsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnnouncementsRepository>(value),
    );
  }
}

String _$announcementsRepositoryHash() =>
    r'e1e38458ccf5e4f7ec3f876f6e4323813e023042';

@ProviderFor(announcements)
final announcementsProvider = AnnouncementsFamily._();

final class AnnouncementsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Announcement>>,
          List<Announcement>,
          FutureOr<List<Announcement>>
        >
    with
        $FutureModifier<List<Announcement>>,
        $FutureProvider<List<Announcement>> {
  AnnouncementsProvider._({
    required AnnouncementsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'announcementsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$announcementsHash();

  @override
  String toString() {
    return r'announcementsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Announcement>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Announcement>> create(Ref ref) {
    final argument = this.argument as int;
    return announcements(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AnnouncementsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$announcementsHash() => r'7fe8be8086250f4303caa579ae12254ee25bc88e';

final class AnnouncementsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Announcement>>, int> {
  AnnouncementsFamily._()
    : super(
        retry: null,
        name: r'announcementsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AnnouncementsProvider call(int teamId) =>
      AnnouncementsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'announcementsProvider';
}

/// Whether something was announced since I last looked. Personal only.

@ProviderFor(hasNewAnnouncements)
final hasNewAnnouncementsProvider = HasNewAnnouncementsFamily._();

/// Whether something was announced since I last looked. Personal only.

final class HasNewAnnouncementsProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether something was announced since I last looked. Personal only.
  HasNewAnnouncementsProvider._({
    required HasNewAnnouncementsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'hasNewAnnouncementsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hasNewAnnouncementsHash();

  @override
  String toString() {
    return r'hasNewAnnouncementsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as int;
    return hasNewAnnouncements(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HasNewAnnouncementsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hasNewAnnouncementsHash() =>
    r'b57dda51463cc6b4e4f3005bfda4906f406a88c1';

/// Whether something was announced since I last looked. Personal only.

final class HasNewAnnouncementsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, int> {
  HasNewAnnouncementsFamily._()
    : super(
        retry: null,
        name: r'hasNewAnnouncementsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether something was announced since I last looked. Personal only.

  HasNewAnnouncementsProvider call(int teamId) =>
      HasNewAnnouncementsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'hasNewAnnouncementsProvider';
}
