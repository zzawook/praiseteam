import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';
import '../auth/auth.dart';

part 'notifications_providers.freezed.dart';
part 'notifications_providers.g.dart';

@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required int id,
    int? teamId,
    required String category,
    @Default(<String, dynamic>{}) Map<String, dynamic> params,
    required DateTime createdAt,
    DateTime? readAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);
}

class NotificationsRepository {
  NotificationsRepository(this._db);
  final SupabaseClient _db;

  Future<List<AppNotification>> recent() async {
    final rows = await _db
        .from('notifications')
        .select('id, team_id, category, params, created_at, read_at')
        .eq('listed', true) // chat notifications are push-only
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(AppNotification.fromJson).toList();
  }

  Future<void> markAllRead() => _db
      .from('notifications')
      .update({'read_at': DateTime.now().toUtc().toIso8601String()})
      .eq('listed', true)
      .isFilter('read_at', null);

  /// Calls [onChange] when a notification for [userId] arrives.
  RealtimeChannel watch(String userId, void Function() onChange) => _db
      .channel('notifications:$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
        callback: (_) => onChange(),
      )
      .subscribe();
}

@Riverpod(keepAlive: true)
NotificationsRepository notificationsRepository(Ref ref) =>
    NotificationsRepository(ref.watch(supabaseProvider));

/// The user's recent notifications, kept live.
@Riverpod(keepAlive: true)
class Notifications extends _$Notifications {
  @override
  Future<List<AppNotification>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const [];
    final repo = ref.watch(notificationsRepositoryProvider);
    final channel = repo.watch(userId, () async => state = AsyncData(await repo.recent()));
    ref.onDispose(channel.unsubscribe);
    return repo.recent();
  }

  Future<void> markAllRead() async {
    final current = state.value ?? const [];
    if (current.every((n) => n.readAt != null)) return;
    await ref.read(notificationsRepositoryProvider).markAllRead();
    final now = DateTime.now();
    state = AsyncData([for (final n in current) n.readAt == null ? n.copyWith(readAt: now) : n]);
  }
}

@riverpod
int unreadNotificationCount(Ref ref) =>
    (ref.watch(notificationsProvider).value ?? const []).where((n) => n.readAt == null).length;
