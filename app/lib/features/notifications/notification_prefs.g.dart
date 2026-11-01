// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_prefs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationPrefsRepository)
final notificationPrefsRepositoryProvider =
    NotificationPrefsRepositoryProvider._();

final class NotificationPrefsRepositoryProvider
    extends
        $FunctionalProvider<
          NotificationPrefsRepository,
          NotificationPrefsRepository,
          NotificationPrefsRepository
        >
    with $Provider<NotificationPrefsRepository> {
  NotificationPrefsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPrefsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPrefsRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotificationPrefsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationPrefsRepository create(Ref ref) {
    return notificationPrefsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationPrefsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationPrefsRepository>(value),
    );
  }
}

String _$notificationPrefsRepositoryHash() =>
    r'ac3c027a79943a3761702c88a26b2ee16cd25a17';

@ProviderFor(MyNotificationPrefs)
final myNotificationPrefsProvider = MyNotificationPrefsProvider._();

final class MyNotificationPrefsProvider
    extends $AsyncNotifierProvider<MyNotificationPrefs, NotificationPrefs> {
  MyNotificationPrefsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myNotificationPrefsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myNotificationPrefsHash();

  @$internal
  @override
  MyNotificationPrefs create() => MyNotificationPrefs();
}

String _$myNotificationPrefsHash() =>
    r'73d1d2cb65c662fb417a6df877793d332c73c9ae';

abstract class _$MyNotificationPrefs extends $AsyncNotifier<NotificationPrefs> {
  FutureOr<NotificationPrefs> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<NotificationPrefs>, NotificationPrefs>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NotificationPrefs>, NotificationPrefs>,
              AsyncValue<NotificationPrefs>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
