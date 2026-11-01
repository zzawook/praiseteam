// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_providers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    _AppNotification(
      id: (json['id'] as num).toInt(),
      teamId: (json['team_id'] as num?)?.toInt(),
      category: json['category'] as String,
      params:
          json['params'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
    );

Map<String, dynamic> _$AppNotificationToJson(_AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'team_id': instance.teamId,
      'category': instance.category,
      'params': instance.params,
      'created_at': instance.createdAt.toIso8601String(),
      'read_at': instance.readAt?.toIso8601String(),
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationsRepository)
final notificationsRepositoryProvider = NotificationsRepositoryProvider._();

final class NotificationsRepositoryProvider
    extends
        $FunctionalProvider<
          NotificationsRepository,
          NotificationsRepository,
          NotificationsRepository
        >
    with $Provider<NotificationsRepository> {
  NotificationsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotificationsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationsRepository create(Ref ref) {
    return notificationsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationsRepository>(value),
    );
  }
}

String _$notificationsRepositoryHash() =>
    r'901c18edc9ec9fad9e5cd613b0009af7906a9494';

/// The user's recent notifications, kept live.

@ProviderFor(Notifications)
final notificationsProvider = NotificationsProvider._();

/// The user's recent notifications, kept live.
final class NotificationsProvider
    extends $AsyncNotifierProvider<Notifications, List<AppNotification>> {
  /// The user's recent notifications, kept live.
  NotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsHash();

  @$internal
  @override
  Notifications create() => Notifications();
}

String _$notificationsHash() => r'85c8691520f3a1ec1dc280e99ee72d368bfbc213';

/// The user's recent notifications, kept live.

abstract class _$Notifications extends $AsyncNotifier<List<AppNotification>> {
  FutureOr<List<AppNotification>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<AppNotification>>, List<AppNotification>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<AppNotification>>,
                List<AppNotification>
              >,
              AsyncValue<List<AppNotification>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(unreadNotificationCount)
final unreadNotificationCountProvider = UnreadNotificationCountProvider._();

final class UnreadNotificationCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  UnreadNotificationCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadNotificationCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadNotificationCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return unreadNotificationCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$unreadNotificationCountHash() =>
    r'ce8d1ab64b97e6105c13349d1e3c54cacaa4f0ac';
