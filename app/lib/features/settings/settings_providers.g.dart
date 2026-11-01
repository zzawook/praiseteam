// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The language the app shows; null follows the device.
///
/// Korean unless the person picks another in settings: the team is Korean,
/// but many phones in Singapore are set to English. "Follow the device" is
/// a choice of its own, kept as [_device].

@ProviderFor(AppLocale)
final appLocaleProvider = AppLocaleProvider._();

/// The language the app shows; null follows the device.
///
/// Korean unless the person picks another in settings: the team is Korean,
/// but many phones in Singapore are set to English. "Follow the device" is
/// a choice of its own, kept as [_device].
final class AppLocaleProvider extends $NotifierProvider<AppLocale, Locale?> {
  /// The language the app shows; null follows the device.
  ///
  /// Korean unless the person picks another in settings: the team is Korean,
  /// but many phones in Singapore are set to English. "Follow the device" is
  /// a choice of its own, kept as [_device].
  AppLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLocaleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLocaleHash();

  @$internal
  @override
  AppLocale create() => AppLocale();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale?>(value),
    );
  }
}

String _$appLocaleHash() => r'1e9ee176706bb613b1e513db6f17b0151e28202f';

/// The language the app shows; null follows the device.
///
/// Korean unless the person picks another in settings: the team is Korean,
/// but many phones in Singapore are set to English. "Follow the device" is
/// a choice of its own, kept as [_device].

abstract class _$AppLocale extends $Notifier<Locale?> {
  Locale? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Locale?, Locale?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Locale?, Locale?>,
              Locale?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

final class ProfileRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileRepository,
          ProfileRepository,
          ProfileRepository
        >
    with $Provider<ProfileRepository> {
  ProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileRepository create(Ref ref) {
    return profileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRepository>(value),
    );
  }
}

String _$profileRepositoryHash() => r'4b04cfc997a616c42ca53641b46202ae1dedcbc5';

@ProviderFor(myProfile)
final myProfileProvider = MyProfileProvider._();

final class MyProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<({String displayName, String locale})?>,
          ({String displayName, String locale})?,
          FutureOr<({String displayName, String locale})?>
        >
    with
        $FutureModifier<({String displayName, String locale})?>,
        $FutureProvider<({String displayName, String locale})?> {
  MyProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myProfileHash();

  @$internal
  @override
  $FutureProviderElement<({String displayName, String locale})?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<({String displayName, String locale})?> create(Ref ref) {
    return myProfile(ref);
  }
}

String _$myProfileHash() => r'32464e15cc40321e7dcc91025334e6415fef860d';

/// Push texts are rendered on the server in the profile's language, so keep
/// it equal to the language the app is actually showing.

@ProviderFor(ProfileLocaleSync)
final profileLocaleSyncProvider = ProfileLocaleSyncProvider._();

/// Push texts are rendered on the server in the profile's language, so keep
/// it equal to the language the app is actually showing.
final class ProfileLocaleSyncProvider
    extends $NotifierProvider<ProfileLocaleSync, String?> {
  /// Push texts are rendered on the server in the profile's language, so keep
  /// it equal to the language the app is actually showing.
  ProfileLocaleSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileLocaleSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileLocaleSyncHash();

  @$internal
  @override
  ProfileLocaleSync create() => ProfileLocaleSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$profileLocaleSyncHash() => r'c0912339b7ef80576cbb229922ebbdc61301cf26';

/// Push texts are rendered on the server in the profile's language, so keep
/// it equal to the language the app is actually showing.

abstract class _$ProfileLocaleSync extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
