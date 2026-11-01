// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supabase)
final supabaseProvider = SupabaseProvider._();

final class SupabaseProvider
    extends $FunctionalProvider<SupabaseClient, SupabaseClient, SupabaseClient>
    with $Provider<SupabaseClient> {
  SupabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseHash();

  @$internal
  @override
  $ProviderElement<SupabaseClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseClient create(Ref ref) {
    return supabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseClient>(value),
    );
  }
}

String _$supabaseHash() => r'7750c766113ae9b14a18705c73c53e2e92e2ddbd';

/// Overridden in main() with the instance loaded before runApp.

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// Overridden in main() with the instance loaded before runApp.

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferences,
          SharedPreferences,
          SharedPreferences
        >
    with $Provider<SharedPreferences> {
  /// Overridden in main() with the instance loaded before runApp.
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferences create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferences>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'70ef90bd70df9f89260fca9b542d9f8d25d8e3cb';

/// Overridden in main() with the instance that watches the HTTP client.

@ProviderFor(reachability)
final reachabilityProvider = ReachabilityProvider._();

/// Overridden in main() with the instance that watches the HTTP client.

final class ReachabilityProvider
    extends $FunctionalProvider<Reachability, Reachability, Reachability>
    with $Provider<Reachability> {
  /// Overridden in main() with the instance that watches the HTTP client.
  ReachabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reachabilityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reachabilityHash();

  @$internal
  @override
  $ProviderElement<Reachability> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Reachability create(Ref ref) {
    return reachability(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Reachability value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Reachability>(value),
    );
  }
}

String _$reachabilityHash() => r'9735e66cf8fbd565422962aeb86c23a47ebd2ca1';

/// Whether the backend is reachable, and how many times it came back.
/// Screens that show saved data watch [epoch] to refresh on reconnect.

@ProviderFor(OnlineStatus)
final onlineStatusProvider = OnlineStatusProvider._();

/// Whether the backend is reachable, and how many times it came back.
/// Screens that show saved data watch [epoch] to refresh on reconnect.
final class OnlineStatusProvider
    extends $NotifierProvider<OnlineStatus, ({int epoch, bool online})> {
  /// Whether the backend is reachable, and how many times it came back.
  /// Screens that show saved data watch [epoch] to refresh on reconnect.
  OnlineStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onlineStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onlineStatusHash();

  @$internal
  @override
  OnlineStatus create() => OnlineStatus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({int epoch, bool online}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<({int epoch, bool online})>(value),
    );
  }
}

String _$onlineStatusHash() => r'3e7897a1e400fbb9f3782ef7bb85625164b5e0fa';

/// Whether the backend is reachable, and how many times it came back.
/// Screens that show saved data watch [epoch] to refresh on reconnect.

abstract class _$OnlineStatus extends $Notifier<({int epoch, bool online})> {
  ({int epoch, bool online}) build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<({int epoch, bool online}), ({int epoch, bool online})>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({int epoch, bool online}),
                ({int epoch, bool online})
              >,
              ({int epoch, bool online}),
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(localDb)
final localDbProvider = LocalDbProvider._();

final class LocalDbProvider
    extends $FunctionalProvider<LocalDb, LocalDb, LocalDb>
    with $Provider<LocalDb> {
  LocalDbProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localDbProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localDbHash();

  @$internal
  @override
  $ProviderElement<LocalDb> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalDb create(Ref ref) {
    return localDb(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalDb value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalDb>(value),
    );
  }
}

String _$localDbHash() => r'a9bb32e1f89a7c1111c0fe9efa09605c911fbfea';

@ProviderFor(offlineStore)
final offlineStoreProvider = OfflineStoreProvider._();

final class OfflineStoreProvider
    extends $FunctionalProvider<OfflineStore, OfflineStore, OfflineStore>
    with $Provider<OfflineStore> {
  OfflineStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offlineStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offlineStoreHash();

  @$internal
  @override
  $ProviderElement<OfflineStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OfflineStore create(Ref ref) {
    return offlineStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OfflineStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OfflineStore>(value),
    );
  }
}

String _$offlineStoreHash() => r'3a3e1a372e696ef4860f3a0b98be5d6b54f37c86';
