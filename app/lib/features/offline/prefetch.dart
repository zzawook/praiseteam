import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/offline/reachability.dart';
import '../../core/providers.dart';
import '../annotations/annotations_controller.dart';
import '../auth/auth.dart';
import '../sessions/sessions_providers.dart';
import '../songs/songs_providers.dart';
import '../teams/teams_providers.dart';

part 'prefetch.g.dart';

/// How far ahead every service is kept on the device.
const offlineWindow = Duration(days: 7);

/// Keeps what the music stand needs on the device: every service in the
/// next 7 days and every upcoming service I serve at, with its setlist,
/// sheets (the PDFs too) and notes. Runs after sign-in and again each time
/// the connection comes back. The value is how many services are ready.
@Riverpod(keepAlive: true)
Future<int> offlinePrefetch(Ref ref) async {
  ref.watch(onlineStatusProvider.select((s) => s.epoch));
  final me = ref.watch(currentUserIdProvider);
  if (me == null) return 0;
  final memberships = await ref.watch(myMembershipsProvider.future);
  final sessions = ref.read(sessionsRepositoryProvider);
  final songs = ref.read(songsRepositoryProvider);
  final notes = ref.read(annotationsRepositoryProvider);
  final soon = DateTime.now().add(offlineWindow);

  var ready = 0;
  for (final membership in memberships.where((m) => m.isActive)) {
    final serving = await _servingAt(ref, me, membership.teamId);
    final upcoming = await sessions.upcoming(membership.teamId);
    for (final session in upcoming.where((s) => s.startsAt.isBefore(soon) || serving.contains(s.id))) {
      try {
        await sessions.session(session.id);
        final items = await sessions.setlist(session.id);
        final sheets = await songs.sheetsByIds([for (final i in items) ?i.sheetId]);
        for (final sheet in sheets) {
          await songs.downloadSheet(sheet.storagePath);
        }
        await notes.forSession(session.id);
        ready++;
      } catch (e) {
        if (isOfflineError(e)) rethrow; // the rest cannot be fetched either
        debugPrint('offline: could not keep session ${session.id}: $e');
      }
    }
  }
  return ready;
}

/// Upcoming services I have been asked to serve at (sent, not declined).
Future<Set<int>> _servingAt(Ref ref, String me, int teamId) async {
  try {
    final rows = await ref
        .read(supabaseProvider)
        .from('assignments')
        .select('session_id')
        .eq('team_id', teamId)
        .eq('user_id', me)
        .inFilter('status', ['pending', 'accepted']);
    return {for (final r in rows) r['session_id'] as int};
  } catch (e) {
    if (isOfflineError(e)) return const {};
    rethrow;
  }
}
