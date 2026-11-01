import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth.dart';
import '../notifications/notification_bell.dart';
import '../rotation/rotation_providers.dart';
import '../rotation/rotation_repository.dart';
import '../rotation/rotation_screen.dart' show statusLabel;
import '../teams/teams_providers.dart';
import 'models.dart';
import 'session_editor.dart';
import 'sessions_providers.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key, required this.teamId});
  final int teamId;

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  bool _showPast = false;

  Future<void> _refresh() async {
    ref
      ..invalidate(upcomingSessionsProvider(widget.teamId))
      ..invalidate(pastSessionsProvider(widget.teamId));
    await ref.read(upcomingSessionsProvider(widget.teamId).future);
  }

  Future<void> _add(List<Session> known) async {
    final titles = <String>{for (final s in known) s.title}.toList();
    final rows = await showSessionEditor(context, recentTitles: titles);
    if (rows == null || !mounted) return;
    var ids = <int>[];
    final ok = await runGuarded(
      context,
      () async => ids = await ref.read(sessionsRepositoryProvider).createSessions(widget.teamId, rows),
    );
    if (!ok || !mounted) return;
    await _refresh();
    if (mounted && ids.length == 1) context.push('/t/${widget.teamId}/sessions/${ids.first}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final narrow = MediaQuery.sizeOf(context).width < Breakpoints.rail;
    final isLeader = ref.watch(activeMembershipProvider(widget.teamId))?.role.isLeader ?? false;
    final upcoming = ref.watch(upcomingSessionsProvider(widget.teamId));
    final past = _showPast ? ref.watch(pastSessionsProvider(widget.teamId)) : null;

    return Scaffold(
      appBar: AppBar(
        title: narrow ? TeamSwitcher(teamId: widget.teamId) : Text(l10n.navSessions),
        actions: [
          TextButton(onPressed: () => context.push('/t/${widget.teamId}/rotation'), child: Text(l10n.rotation)),
          NotificationBell(teamId: widget.teamId),
        ],
      ),
      floatingActionButton: isLeader
          ? FloatingActionButton.extended(
              onPressed: () => _add([...?upcoming.value, ...?past?.value]),
              icon: const Icon(Icons.add),
              label: Text(l10n.addSession),
            )
          : null,
      body: AsyncBody(
        value: upcoming,
        onRetry: _refresh,
        data: (sessions) => RefreshIndicator(
          onRefresh: _refresh,
          child: ContentWidth(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                _MyServing(teamId: widget.teamId),
                SectionHeader(l10n.upcomingSessions),
                if (sessions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(isLeader ? l10n.noSessionsLeader : l10n.noSessionsMember),
                  ),
                for (final s in sessions) ...[
                  _SessionRow(teamId: widget.teamId, session: s, isLeader: isLeader),
                  const Divider(indent: 88),
                ],
                ListTile(
                  title: Text(l10n.pastSessions),
                  trailing: Icon(_showPast ? Icons.expand_less : Icons.expand_more),
                  onTap: () => setState(() => _showPast = !_showPast),
                ),
                if (past != null)
                  AsyncBody(
                    value: past,
                    onRetry: () => ref.invalidate(pastSessionsProvider(widget.teamId)),
                    data: (items) => Column(
                      children: [
                        for (final s in items) ...[
                          _SessionRow(teamId: widget.teamId, session: s, isLeader: isLeader, muted: true),
                          const Divider(indent: 88),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.teamId, required this.session, required this.isLeader, this.muted = false});
  final int teamId;
  final Session session;
  final bool isLeader;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final formats = DateFormats(context);
    final local = session.startsAt.toLocal();
    final published = session.setlistStatus == SetlistStatus.published;

    // Status uses the two inks: published = shared with the team,
    // draft = still only the leaders' (members never see drafts).
    final Widget? status = published
        ? Text(l10n.songsCount(session.songCount), style: theme.textTheme.labelLarge?.copyWith(color: AppColors.teamInk))
        : isLeader
            ? Text(l10n.setlistDraft, style: theme.textTheme.labelLarge?.copyWith(color: AppColors.myPencil))
            : null;

    return ListTile(
      onTap: () => context.push('/t/$teamId/sessions/${session.id}'),
      contentPadding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      leading: SizedBox(
        width: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${local.day}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1,
                color: muted ? theme.colorScheme.onSurfaceVariant : null,
              ),
            ),
            Text(formats.weekdayShort(local), style: theme.textTheme.labelSmall),
          ],
        ),
      ),
      title: Text(session.title, style: muted ? TextStyle(color: theme.colorScheme.onSurfaceVariant) : null),
      subtitle: Text(
        [formats.dayWithWeekday(local), formats.time(local), if (session.location != null) session.location!].join('  '),
      ),
      trailing: status,
    );
  }
}

/// My requests and services in the coming weeks, answerable in place.
class _MyServing extends ConsumerWidget {
  const _MyServing({required this.teamId});
  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentUserIdProvider);
    final board = ref.watch(rotationBoardProvider(teamId)).value;
    if (board == null || me == null) return const SizedBox.shrink();
    final parts = {for (final p in ref.watch(teamPartsProvider(teamId)).value ?? const []) p.id: p.name};
    final sessions = {for (final s in board.sessions) s.id: s};
    final mine = board.assignments
        .where((a) => a.userId == me && (a.status == AssignmentStatus.pending || a.status == AssignmentStatus.accepted))
        .toList()
      ..sort((a, b) => sessions[a.sessionId]!.startsAt.compareTo(sessions[b.sessionId]!.startsAt));
    if (mine.isEmpty) return const SizedBox.shrink();
    final formats = DateFormats(context);
    final repo = ref.read(rotationRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.myServing),
        for (final a in mine)
          ListTile(
            onTap: () => context.push('/t/$teamId/sessions/${a.sessionId}'),
            title: Text('${sessions[a.sessionId]!.title}  ${parts[a.partId] ?? ''}'),
            subtitle: Text('${formats.dayWithWeekday(sessions[a.sessionId]!.startsAt)}  ${formats.time(sessions[a.sessionId]!.startsAt)}'),
            trailing: a.status == AssignmentStatus.pending
                ? Wrap(
                    spacing: 4,
                    children: [
                      TextButton(
                        onPressed: () async {
                          if (await runGuarded(context, () => repo.respond(a.id, accept: false))) {
                            ref.invalidate(rotationBoardProvider(teamId));
                          }
                        },
                        child: Text(l10n.decline),
                      ),
                      FilledButton(
                        onPressed: () async {
                          if (await runGuarded(context, () => repo.respond(a.id, accept: true))) {
                            ref.invalidate(rotationBoardProvider(teamId));
                          }
                        },
                        child: Text(l10n.accept),
                      ),
                    ],
                  )
                : Text(statusLabel(l10n, a.status), style: const TextStyle(color: AppColors.teamInk)),
          ),
      ],
    );
  }
}
