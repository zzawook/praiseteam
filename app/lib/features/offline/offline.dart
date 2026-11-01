import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/offline/offline_store.dart';
import '../../core/providers.dart';
import '../auth/auth.dart';

part 'offline.g.dart';

/// Reads for the signed-in user that keep working offline (see
/// [ReadThrough]). Saved answers belong to the user who fetched them.
@Riverpod(keepAlive: true)
ReadThrough readThrough(Ref ref) =>
    ReadThrough(ref.watch(offlineStoreProvider), ref.watch(reachabilityProvider), ref.watch(currentUserIdProvider));
