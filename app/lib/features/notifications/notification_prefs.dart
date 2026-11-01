import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';
import '../auth/auth.dart';

part 'notification_prefs.g.dart';

/// The push switches people see. Each covers some of the server's
/// notification categories (the templates in supabase/functions/push).
/// Off stops the push only: the notification list and chat unread counts
/// stay as they are.
enum PushGroup {
  setlists(['setlist_published', 'setlist_updated']),
  serving([
    'assignment_requested',
    'assignment_removed',
    'assignment_nudge',
    'assignment_declined',
    'service_reminder',
    'swap_requested',
    'swap_filled',
  ]),
  rehearsals(['rehearsal_scheduled', 'rehearsal_reminder']),
  announcements(['announcement']),
  chat(['chat_message']),
  joining(['member_join_request', 'member_approved']);

  const PushGroup(this.categories);
  final List<String> categories;
}

/// Opt-in to the setlists of every service in my teams, not only the ones
/// I serve at (setlist_recipients in the rotation migration reads it).
const allSetlistsCategory = 'setlist_all';

class NotificationPrefs {
  const NotificationPrefs(this.rows);

  /// category -> push_enabled. A missing row means the default: push on,
  /// and no opt-in to every setlist.
  final Map<String, bool> rows;

  bool push(PushGroup group) => group.categories.every((c) => rows[c] ?? true);
  bool get allSetlists => rows[allSetlistsCategory] ?? false;

  NotificationPrefs updated(Iterable<String> categories, bool on) =>
      NotificationPrefs({...rows, for (final c in categories) c: on});
}

class NotificationPrefsRepository {
  NotificationPrefsRepository(this._db);
  final SupabaseClient _db;

  /// My rows only (row-level security).
  Future<Map<String, bool>> mine() async {
    final rows = await _db.from('notification_prefs').select('category, push_enabled');
    return {for (final r in rows) r['category'] as String: r['push_enabled'] as bool};
  }

  Future<void> set(String userId, Iterable<String> categories, bool on) => _db.from('notification_prefs').upsert([
    for (final c in categories) {'user_id': userId, 'category': c, 'push_enabled': on},
  ], onConflict: 'user_id,category');
}

@Riverpod(keepAlive: true)
NotificationPrefsRepository notificationPrefsRepository(Ref ref) =>
    NotificationPrefsRepository(ref.watch(supabaseProvider));

@riverpod
class MyNotificationPrefs extends _$MyNotificationPrefs {
  @override
  Future<NotificationPrefs> build() async {
    ref.watch(currentUserIdProvider);
    return NotificationPrefs(await ref.watch(notificationPrefsRepositoryProvider).mine());
  }

  Future<void> setPush(PushGroup group, bool on) => _set(group.categories, on);
  Future<void> setAllSetlists(bool on) => _set(const [allSetlistsCategory], on);

  /// The switch moves at once; if saving fails it moves back and the
  /// error reaches the caller.
  Future<void> _set(List<String> categories, bool on) async {
    final userId = ref.read(currentUserIdProvider);
    final before = state.value;
    if (userId == null || before == null) return;
    state = AsyncData(before.updated(categories, on));
    try {
      await ref.read(notificationPrefsRepositoryProvider).set(userId, categories, on);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }
}
