import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'offline/local_db.dart';
import 'offline/offline_store.dart';
import 'offline/reachability.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
SupabaseClient supabase(Ref ref) => Supabase.instance.client;

/// Overridden in main() with the instance loaded before runApp.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('sharedPreferencesProvider must be overridden');

/// Overridden in main() with the instance that watches the HTTP client.
@Riverpod(keepAlive: true)
Reachability reachability(Ref ref) => throw UnimplementedError('reachabilityProvider must be overridden');

/// Whether the backend is reachable, and how many times it came back.
/// Screens that show saved data watch [epoch] to refresh on reconnect.
@Riverpod(keepAlive: true)
class OnlineStatus extends _$OnlineStatus {
  @override
  ({bool online, int epoch}) build() {
    final reachability = ref.watch(reachabilityProvider);
    void sync() => state = (online: reachability.online, epoch: reachability.epoch);
    reachability.addListener(sync);
    ref.onDispose(() => reachability.removeListener(sync));
    return (online: reachability.online, epoch: reachability.epoch);
  }
}

@Riverpod(keepAlive: true)
LocalDb localDb(Ref ref) {
  final db = LocalDb();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
OfflineStore offlineStore(Ref ref) => OfflineStore(ref.watch(localDbProvider));
