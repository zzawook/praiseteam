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
import '../rotation/rotation_screen.dart' show statusLabel, statusLook;
import '../teams/models.dart';
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
      body: AsyncBody(
        value: upcoming,
        onRetry: _refresh,
        data: (sessions) => RefreshIndicator(
          onRefresh: _refresh,
          child: ContentWidth(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                if (sessions.isNotEmpty) _NextService(teamId: widget.teamId, session: sessions.first),
                _MyServing(teamId: widget.teamId),
                SectionHeader(
                  l10n.upcomingSessions,
                  trailing: isLeader
                      ? AddButton(label: l10n.addSession, onPressed: () => _add([...?upcoming.value, ...?past?.value]))
                      : null,
                ),
                if (sessions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(isLeader ? l10n.noSessionsLeader : l10n.noSessionsMember),
                  )
                else
                  _SessionList(
                    children: [
                      for (final s in sessions) _SessionRow(teamId: widget.teamId, session: s, isLeader: isLeader),
                    ],
                  ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(l10n.pastSessions),
                  trailing: Icon(_showPast ? Icons.expand_less : Icons.expand_more),
                  onTap: () => setState(() => _showPast = !_showPast),
                ),
                if (past != null)
                  AsyncBody(
                    value: past,
                    onRetry: () => ref.invalidate(pastSessionsProvider(widget.teamId)),
                    data: (items) => _SessionList(
                      children: [
                        for (final s in items)
                          _SessionRow(teamId: widget.teamId, session: s, isLeader: isLeader, muted: true),
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

/// Rows on one sheet of paper, separated by hairlines.
class _SessionList extends StatelessWidget {
  const _SessionList({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Column(
          children: [
            for (final (i, row) in children.indexed) ...[if (i > 0) const Divider(indent: 84), row],
          ],
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
    final thisWeek = !muted && DateUtils.dateOnly(local).difference(DateUtils.dateOnly(DateTime.now())).inDays < 7;

    // Published setlists are shared with the team (ink); drafts are still
    // only the leaders' (members never see them).
    final Widget? status = published
        ? _Pill(text: l10n.songsCount(session.songCount), filled: !muted)
        : isLeader
        ? _Pill(text: l10n.setlistDraft, filled: false)
        : null;

    // A plain row rather than a ListTile: the calendar leaf is taller than
    // a ListTile lets its leading widget be.
    return InkWell(
      onTap: () => context.push('/t/$teamId/sessions/${session.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
        child: Row(
          children: [
            _DateBlock(date: local, highlight: thisWeek),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: AppType.setlistFamily,
                      fontWeight: FontWeight.w700,
                      color: muted ? theme.colorScheme.onSurfaceVariant : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [formats.time(local), ?session.location].join('  '),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            ?status,
          ],
        ),
      ),
    );
  }
}

/// A calendar leaf: month, day, weekday. This week's are tinted.
class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.date, required this.highlight});
  final DateTime date;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formats = DateFormats(context);
    final scheme = theme.colorScheme;
    final fg = highlight ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? scheme.primaryContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formats.monthShort(date), style: theme.textTheme.labelSmall?.copyWith(color: fg, height: 1.1)),
          Text(
            '${date.day}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: highlight ? scheme.onPrimaryContainer : scheme.onSurface,
              fontFamily: AppType.setlistFamily,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          Text(formats.weekdayShort(date), style: theme.textTheme.labelSmall?.copyWith(color: fg, height: 1.1)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.filled});
  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? scheme.primaryContainer : null,
        border: filled ? null : Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: filled ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The next service, in team ink: when it is, what I play, the setlist,
/// and the way to the stand. The one bold card on the home screen.
class _NextService extends ConsumerWidget {
  const _NextService({required this.teamId, required this.session});
  final int teamId;
  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final formats = DateFormats(context);
    final local = session.startsAt.toLocal();
    final items = ref.watch(setlistProvider(session.id)).value ?? const <SetlistItem>[];
    final me = ref.watch(currentUserIdProvider);
    final parts = {for (final p in ref.watch(teamPartsProvider(teamId)).value ?? const <Part>[]) p.id: p.name};
    final mine = [
      for (final a in ref.watch(rotationBoardProvider(teamId)).value?.assignments ?? const <Assignment>[])
        if (a.sessionId == session.id &&
            a.userId == me &&
            (a.status == AssignmentStatus.pending || a.status == AssignmentStatus.accepted))
          a,
    ];
    final days = DateUtils.dateOnly(local).difference(DateUtils.dateOnly(DateTime.now())).inDays;
    final when = days <= 0
        ? l10n.today
        : days == 1
        ? l10n.tomorrow
        : l10n.inDays(days);
    final fg = palette.onHero;
    final soft = fg.withValues(alpha: 0.75);
    final serif = theme.textTheme.titleMedium?.copyWith(fontFamily: AppType.setlistFamily, fontWeight: FontWeight.w700);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Card(
        color: palette.hero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () => context.push('/t/$teamId/sessions/${session.id}'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${l10n.nextService}  $when',
                        style: theme.textTheme.labelLarge?.copyWith(color: soft),
                      ),
                    ),
                    for (final a in mine)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: a.status == AssignmentStatus.accepted ? fg : null,
                          border: Border.all(color: fg),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          parts[a.partId] ?? '',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: a.status == AssignmentStatus.accepted ? palette.hero : fg,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  session.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: fg,
                    fontFamily: AppType.setlistFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [formats.dayWithWeekday(local), formats.time(local), ?session.location].join('  '),
                  style: theme.textTheme.bodyMedium?.copyWith(color: soft),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  Text(l10n.setlistComing, style: theme.textTheme.bodyMedium?.copyWith(color: soft))
                else ...[
                  for (final (i, item) in items.take(4).indexed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text('${i + 1}', style: serif?.copyWith(color: soft)),
                          ),
                          Expanded(
                            child: Text(
                              item.song.title,
                              overflow: TextOverflow.ellipsis,
                              style: serif?.copyWith(color: fg),
                            ),
                          ),
                          if (item.effectiveKey case final key?)
                            Container(
                              constraints: const BoxConstraints(minWidth: 30),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                border: Border.all(color: soft),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                key,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (items.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: 2),
                      child: Text(
                        l10n.moreSongs(items.length - 4),
                        style: theme.textTheme.bodySmall?.copyWith(color: soft),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
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
    final theme = Theme.of(context);
    final me = ref.watch(currentUserIdProvider);
    final board = ref.watch(rotationBoardProvider(teamId)).value;
    if (board == null || me == null) return const SizedBox.shrink();
    final parts = {for (final p in ref.watch(teamPartsProvider(teamId)).value ?? const []) p.id: p.name};
    final sessions = {for (final s in board.sessions) s.id: s};
    final mine =
        board.assignments
            .where(
              (a) => a.userId == me && (a.status == AssignmentStatus.pending || a.status == AssignmentStatus.accepted),
            )
            .toList()
          ..sort((a, b) => sessions[a.sessionId]!.startsAt.compareTo(sessions[b.sessionId]!.startsAt));
    if (mine.isEmpty) return const SizedBox.shrink();
    final formats = DateFormats(context);
    final repo = ref.read(rotationRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.myServing),
        _SessionList(
          children: [
            for (final a in mine)
              ListTile(
                onTap: () => context.push('/t/$teamId/sessions/${a.sessionId}'),
                contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
                leading: Builder(
                  builder: (context) {
                    final (color, icon) = statusLook(context, a.status);
                    return CircleAvatar(
                      radius: 18,
                      backgroundColor: color.withValues(alpha: 0.16),
                      foregroundColor: color,
                      child: Icon(icon, size: 20),
                    );
                  },
                ),
                title: Text(
                  '${sessions[a.sessionId]!.title}  ${parts[a.partId] ?? ''}',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${formats.dayWithWeekday(sessions[a.sessionId]!.startsAt)}  ${formats.time(sessions[a.sessionId]!.startsAt)}',
                ),
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
                    : Text(
                        statusLabel(l10n, a.status),
                        style: theme.textTheme.labelLarge?.copyWith(color: statusLook(context, a.status).$1),
                      ),
              ),
          ],
        ),
      ],
    );
  }
}
