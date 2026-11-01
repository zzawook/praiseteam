import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../offline/offline.dart';
import 'models.dart';
import 'sessions_repository.dart';

part 'sessions_providers.g.dart';

@Riverpod(keepAlive: true)
SessionsRepository sessionsRepository(Ref ref) =>
    SessionsRepository(ref.watch(supabaseProvider), ref.watch(readThroughProvider));

@riverpod
Future<List<Session>> upcomingSessions(Ref ref, int teamId) {
  ref.watch(onlineStatusProvider.select((s) => s.epoch)); // refresh on reconnect
  return ref.watch(sessionsRepositoryProvider).upcoming(teamId);
}

@riverpod
Future<List<Session>> pastSessions(Ref ref, int teamId) =>
    ref.watch(sessionsRepositoryProvider).past(teamId);

@riverpod
Future<Session> session(Ref ref, int sessionId) {
  ref.watch(onlineStatusProvider.select((s) => s.epoch));
  return ref.watch(sessionsRepositoryProvider).session(sessionId);
}

@riverpod
Future<List<SessionTemplate>> sessionTemplates(Ref ref, int teamId) =>
    ref.watch(sessionsRepositoryProvider).templates(teamId);

@riverpod
Future<List<SetlistItem>> setlist(Ref ref, int sessionId) {
  ref.watch(onlineStatusProvider.select((s) => s.epoch));
  return ref.watch(sessionsRepositoryProvider).setlist(sessionId);
}

/// "추가: A, B / 버전: C(마커스→어노인팅) / 키: C(G→A) / 템포: D(68→72) / 순서 변경"
String describeSetlistChanges(AppLocalizations l10n, SetlistChanges changes) => [
      if (changes.added.isNotEmpty) l10n.changeAdded(changes.added.join(', ')),
      if (changes.removed.isNotEmpty) l10n.changeRemoved(changes.removed.join(', ')),
      if (changes.versionChanged.isNotEmpty)
        l10n.changeVersion(changes.versionChanged.map((v) => '${v.title}(${v.from ?? '?'}→${v.to ?? '?'})').join(', ')),
      if (changes.keyChanged.isNotEmpty)
        l10n.changeKey(changes.keyChanged.map((k) => '${k.title}(${k.from ?? '?'}→${k.to ?? '?'})').join(', ')),
      if (changes.tempoChanged.isNotEmpty)
        l10n.changeTempo(changes.tempoChanged.map((t) => '${t.title}(${t.from ?? '?'}→${t.to ?? '?'})').join(', ')),
      if (changes.reordered) l10n.changeOrder,
    ].join(' / ');
