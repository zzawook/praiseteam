import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell.dart';
import '../../app/theme.dart';
import '../../core/avatars.dart';
import '../../core/dates.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../announcements/announcements.dart';
import '../auth/auth.dart';
import '../chat/chat_providers.dart';
import '../notifications/notification_bell.dart';
import '../rotation/rehearsals.dart';
import '../rotation/rotation_providers.dart';
import '../rotation/rotation_repository.dart';
import '../rotation/rotation_screen.dart' show statusLook;
import '../sessions/models.dart';
import '../sessions/sessions_providers.dart';
import '../settings/settings_providers.dart';
import '../songs/songs_providers.dart';
import '../teams/models.dart';
import '../teams/teams_providers.dart';
import 'home_providers.dart';
import 'next_service_card.dart';

/// What this week asks of me, on one screen: the next service, things to
/// answer, my schedule and team news; leaders also see how the next two
/// services are coming along, who has been serving, and songs to consider.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.teamId});
  final int teamId;

  /// Below this width the cards stack in one column.
  static const twoColumns = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final narrow = MediaQuery.sizeOf(context).width < Breakpoints.rail;
    final isLeader = ref.watch(activeMembershipProvider(teamId))?.role.isLeader ?? false;
    final upcoming = ref.watch(upcomingSessionsProvider(teamId));

    Future<void> refresh() async {
      ref
        ..invalidate(upcomingSessionsProvider(teamId))
        ..invalidate(rotationBoardProvider(teamId))
        ..invalidate(upcomingRehearsalsProvider(teamId))
        ..invalidate(channelsProvider(teamId))
        ..invalidate(announcementsProvider(teamId))
        ..invalidate(hasNewAnnouncementsProvider(teamId))
        ..invalidate(teamMembersProvider(teamId))
        ..invalidate(servingCountsProvider(teamId));
      await ref.read(upcomingSessionsProvider(teamId).future);
    }

    return Scaffold(
      appBar: AppBar(
        title: narrow ? TeamSwitcher(teamId: teamId) : Text(l10n.navHome),
        actions: [
          NotificationBell(teamId: teamId),
          if (narrow) _MeButton(teamId: teamId),
          const SizedBox(width: 8),
        ],
      ),
      body: AsyncBody(
        value: upcoming,
        onRetry: () => ref.invalidate(upcomingSessionsProvider(teamId)),
        data: (sessions) {
          final next = sessions.firstOrNull;
          final hero = next == null
              ? _NoServices(teamId: teamId, isLeader: isLeader)
              : NextServiceCard(teamId: teamId, session: next);
          final todo = _ToDo(teamId: teamId, isLeader: isLeader);
          final readiness = isLeader && sessions.isNotEmpty
              ? _Readiness(teamId: teamId, sessions: sessions.take(2).toList())
              : null;
          final schedule = _MySchedule(teamId: teamId);
          final news = _TeamNews(teamId: teamId);
          final load = isLeader ? _ServingLoad(teamId: teamId) : null;
          final songs = isLeader ? _SongNotes(teamId: teamId) : null;

          return RefreshIndicator(
            onRefresh: refresh,
            child: LayoutBuilder(
              builder: (context, box) {
                if (box.maxWidth < twoColumns) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: _spaced([hero, todo, ?readiness, schedule, news, ?load, ?songs]),
                  );
                }
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: Column(children: _spaced([hero, ?readiness, ?load, ?songs]))),
                          const SizedBox(width: 20),
                          Expanded(flex: 2, child: Column(children: _spaced([todo, schedule, news]))),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  static List<Widget> _spaced(List<Widget> cards) => [
    for (final (i, card) in cards.indexed) ...[if (i > 0) const SizedBox(height: 16), card],
  ];
}

/// My avatar, top right on phones: the way to settings.
class _MeButton extends ConsumerWidget {
  const _MeButton({required this.teamId});
  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(myProfileProvider).value?.displayName ?? '';
    return IconButton(
      tooltip: AppLocalizations.of(context).navSettings,
      onPressed: () => context.go('/t/$teamId/settings'),
      icon: PersonAvatar(name: name, id: ref.watch(currentUserIdProvider) ?? '', radius: 15),
    );
  }
}

/// A card with a title and, optionally, a link at the right.
class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  ?trailing,
                ],
              ),
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _NoServices extends StatelessWidget {
  const _NoServices({required this.teamId, required this.isLeader});
  final int teamId;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Panel(
      title: l10n.nextService,
      trailing: isLeader
          ? AddButton(label: l10n.addSession, onPressed: () => context.go('/t/$teamId/sessions'))
          : null,
      child: _Muted(isLeader ? l10n.noSessionsLeader : l10n.noSessionsMember),
    );
  }
}

// ---------------------------------------------------------------------------
// To do: everything that waits for my answer, answerable in place.

class _ToDo extends ConsumerWidget {
  const _ToDo({required this.teamId, required this.isLeader});
  final int teamId;
  final bool isLeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final formats = DateFormats(context);
    final me = ref.watch(currentUserIdProvider);
    final board = ref.watch(rotationBoardProvider(teamId)).value;
    final rehearsals = ref.watch(upcomingRehearsalsProvider(teamId)).value ?? const <Rehearsal>[];
    final members = ref.watch(teamMembersProvider(teamId)).value ?? const <Member>[];
    final parts = {for (final p in ref.watch(teamPartsProvider(teamId)).value ?? const <Part>[]) p.id: p.name};
    final hasNews = ref.watch(hasNewAnnouncementsProvider(teamId)).value ?? false;
    final rotation = ref.read(rotationRepositoryProvider);
    final rehearsalRepo = ref.read(rehearsalsRepositoryProvider);
    final palette = AppPalette.of(context);
    void refreshBoard() => ref.invalidate(rotationBoardProvider(teamId));

    final sessions = {for (final s in board?.sessions ?? const <Session>[]) s.id: s};
    final assignments = board?.assignments ?? const <Assignment>[];
    final myParts = members.where((m) => m.userId == me).firstOrNull?.partIds.toSet() ?? const <int>{};
    final serving = {
      for (final a in assignments)
        if (a.userId == me && (a.status == AssignmentStatus.pending || a.status == AssignmentStatus.accepted)) a.sessionId,
    };
    String when(DateTime t) => '${formats.dayWithWeekday(t)}  ${formats.time(t)}';

    final rows = <Widget>[
      // serving requests waiting for my answer
      for (final a in assignments)
        if (a.userId == me && a.status == AssignmentStatus.pending && sessions[a.sessionId] != null)
          _TodoRow(
            icon: Icons.mail_outline,
            color: palette.pending,
            title: l10n.notifAssignmentRequested(sessions[a.sessionId]!.title, parts[a.partId] ?? ''),
            subtitle: when(sessions[a.sessionId]!.startsAt),
            actions: [
              TextButton(
                onPressed: () async {
                  if (await runGuarded(context, () => rotation.respond(a.id, accept: false))) refreshBoard();
                },
                child: Text(l10n.decline),
              ),
              FilledButton(
                onPressed: () async {
                  if (await runGuarded(context, () => rotation.respond(a.id, accept: true))) refreshBoard();
                },
                child: Text(l10n.accept),
              ),
            ],
          ),
      // stand-ins wanted in my parts
      for (final MapEntry(key: assignmentId, value: swap) in (board?.swaps ?? const <int, SwapRequest>{}).entries)
        if (assignments.where((a) => a.id == assignmentId).firstOrNull case final a?
            when a.userId != me && myParts.contains(a.partId) && sessions[a.sessionId] != null)
          _TodoRow(
            icon: Icons.swap_horiz,
            color: palette.pending,
            title: l10n.notifSwapRequested(a.userName, sessions[a.sessionId]!.title, parts[a.partId] ?? ''),
            subtitle: when(sessions[a.sessionId]!.startsAt),
            actions: [
              FilledButton(
                onPressed: () async {
                  if (await runGuarded(context, () => rotation.acceptSwap(swap.id))) refreshBoard();
                },
                child: Text(l10n.takeSwap),
              ),
            ],
          ),
      // rehearsals I haven't answered (mine: my services', or the team's)
      for (final r in rehearsals)
        if (r.startsAt.isBefore(DateTime.now().add(rsvpWindow)) &&
            (r.sessionId == null || serving.contains(r.sessionId)) &&
            r.responses[me]?.rsvp == null)
          _TodoRow(
            icon: Icons.groups_outlined,
            color: palette.pending,
            title: l10n.rehearsalRsvpTodo(
              r.sessionId == null ? l10n.teamRehearsal : (sessions[r.sessionId]?.title ?? l10n.teamRehearsal),
            ),
            subtitle: [when(r.startsAt), ?r.location].join('  '),
            actions: [
              for (final (value, label) in [
                (Rsvp.notGoing, l10n.rsvpNotGoing),
                (Rsvp.late, l10n.rsvpLate),
                (Rsvp.going, l10n.rsvpGoing),
              ])
                TextButton(
                  onPressed: () async {
                    if (await runGuarded(context, () => rehearsalRepo.rsvp(r.id, value))) {
                      ref.invalidate(upcomingRehearsalsProvider(teamId));
                    }
                  },
                  child: Text(label),
                ),
            ],
          ),
      if (hasNews)
        _TodoRow(
          icon: Icons.campaign_outlined,
          color: Theme.of(context).colorScheme.primary,
          title: l10n.newAnnouncementTodo,
          onTap: () => context.push('/t/$teamId/announcements'),
        ),
      if (isLeader)
        if (members.where((m) => m.status == MemberStatus.pending).length case final waiting when waiting > 0)
          _TodoRow(
            icon: Icons.person_add_alt_1_outlined,
            color: Theme.of(context).colorScheme.primary,
            title: l10n.joinRequestsCount(waiting),
            onTap: () => context.go('/t/$teamId/team'),
          ),
    ];

    return _Panel(
      title: l10n.todo,
      child: rows.isEmpty
          ? _Muted(l10n.nothingToDo)
          : Column(
              children: [
                for (final (i, row) in rows.indexed) ...[if (i > 0) const Divider(height: 12), row],
              ],
            ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.15),
                foregroundColor: color,
                child: Icon(icon, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              if (onTap != null) Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
          if (actions.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(spacing: 4, children: actions),
            ),
        ],
      ),
    );
    return onTap == null ? body : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: body);
  }
}

// ---------------------------------------------------------------------------
// Getting ready (leaders): the next two services at a glance.

class _Readiness extends ConsumerWidget {
  const _Readiness({required this.teamId, required this.sessions});
  final int teamId;
  final List<Session> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final formats = DateFormats(context);
    final palette = AppPalette.of(context);
    final board = ref.watch(rotationBoardProvider(teamId)).value;
    final rehearsals = ref.watch(upcomingRehearsalsProvider(teamId)).value ?? const <Rehearsal>[];
    final muted = theme.colorScheme.onSurfaceVariant;

    return _Panel(
      title: l10n.readiness,
      trailing: TextButton(onPressed: () => context.push('/t/$teamId/rotation'), child: Text(l10n.rotation)),
      child: Column(
        children: [
          for (final (i, s) in sessions.indexed) ...[
            if (i > 0) const Divider(height: 20),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.push('/t/$teamId/sessions/${s.id}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            s.title,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: AppType.setlistFamily,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${formats.dayWithWeekday(s.startsAt)}  ${formats.time(s.startsAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        // setlist
                        if (s.setlistStatus == SetlistStatus.published)
                          _Tag(l10n.setlistPublishedCount(s.songCount), palette.accepted, Icons.check)
                        else if (s.songCount > 0)
                          _Tag(l10n.setlistDraftCount(s.songCount), palette.pending, Icons.edit_outlined)
                        else
                          _Tag(l10n.setlistNone, palette.declined, Icons.priority_high),
                        // places
                        if (board != null) ...() {
                          final r = Readiness.of(s, board);
                          return [
                            if (r.needed == 0)
                              _Tag(l10n.placesUnset, muted, Icons.help_outline)
                            else
                              _Tag(
                                l10n.placesFilled(r.accepted, r.needed),
                                r.complete ? palette.accepted : palette.pending,
                                r.complete ? Icons.check : Icons.groups_outlined,
                              ),
                            if (r.waiting > 0) _Tag(l10n.waitingCount(r.waiting), palette.pending, Icons.schedule),
                            if (r.declined > 0) _Tag(l10n.declinedCount(r.declined), palette.declined, Icons.close),
                            if (r.unsent > 0) _Tag(l10n.unsentCount(r.unsent), palette.draft, Icons.edit_outlined),
                          ];
                        }(),
                        // rehearsal
                        if (rehearsals.where((r) => r.sessionId == s.id).firstOrNull case final rehearsal?) ...() {
                          final tally = RsvpTally.of(rehearsal, [
                            for (final a in board?.assignments ?? const <Assignment>[])
                              if (a.sessionId == s.id &&
                                  (a.status == AssignmentStatus.pending || a.status == AssignmentStatus.accepted))
                                a.userId,
                          ]);
                          return [
                            _Tag(l10n.rehearsalComing(tally.coming, tally.total), palette.accepted, Icons.groups_outlined),
                            if (tally.noAnswer > 0) _Tag(l10n.noAnswerCount(tally.noAnswer), palette.pending, Icons.schedule),
                          ];
                        }()
                        else
                          _Tag(l10n.noRehearsal, muted, Icons.remove),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A small colored fact: "배정 4/6", "응답 대기 1".
class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color, this.icon);
  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// My schedule: the next four weeks, services and their rehearsals.

class _MySchedule extends ConsumerWidget {
  const _MySchedule({required this.teamId});
  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final formats = DateFormats(context);
    final me = ref.watch(currentUserIdProvider);
    final board = ref.watch(rotationBoardProvider(teamId)).value;
    final rehearsals = ref.watch(upcomingRehearsalsProvider(teamId)).value ?? const <Rehearsal>[];
    final parts = {for (final p in ref.watch(teamPartsProvider(teamId)).value ?? const <Part>[]) p.id: p.name};
    final sessions = {for (final s in board?.sessions ?? const <Session>[]) s.id: s};
    final until = DateTime.now().add(scheduleWindow);

    final mine = [
      for (final a in board?.assignments ?? const <Assignment>[])
        if (a.userId == me &&
            (a.status == AssignmentStatus.pending || a.status == AssignmentStatus.accepted) &&
            (sessions[a.sessionId]?.startsAt.isBefore(until) ?? false))
          a,
    ];
    final myServices = {for (final a in mine) a.sessionId};
    final entries =
        <({DateTime at, String title, String detail, Color color, IconData icon, String path})>[
          for (final a in mine)
            (
              at: sessions[a.sessionId]!.startsAt,
              title: sessions[a.sessionId]!.title,
              detail: parts[a.partId] ?? '',
              color: statusLook(context, a.status).$1,
              icon: statusLook(context, a.status).$2,
              path: '/t/$teamId/sessions/${a.sessionId}',
            ),
          for (final r in rehearsals)
            if (r.sessionId == null || myServices.contains(r.sessionId))
              (
                at: r.startsAt,
                title: r.sessionId == null ? l10n.teamRehearsal : (sessions[r.sessionId]?.title ?? l10n.teamRehearsal),
                detail: [l10n.rehearsals, ?r.location].join('  '),
                color: theme.colorScheme.onSurfaceVariant,
                icon: Icons.groups_outlined,
                path: r.sessionId == null ? '/t/$teamId/sessions' : '/t/$teamId/sessions/${r.sessionId}',
              ),
        ]..sort((a, b) => a.at.compareTo(b.at));

    return _Panel(
      title: l10n.mySchedule,
      child: entries.isEmpty
          ? _Muted(l10n.noScheduleSoon)
          : Column(
              children: [
                for (final e in entries)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.push(e.path),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 104,
                            child: Text(
                              formats.dayWithWeekday(e.at),
                              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Icon(e.icon, size: 16, color: e.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${e.title}  ${e.detail}',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Text(formats.time(e.at), style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Team news: pinned announcements and chats with unread messages.

class _TeamNews extends ConsumerWidget {
  const _TeamNews({required this.teamId});
  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pinned = [
      for (final a in ref.watch(announcementsProvider(teamId)).value ?? const [])
        if (a.pinned) a,
    ].take(2).toList();
    final unread = [
      for (final c in ref.watch(channelsProvider(teamId)).value ?? const [])
        if (c.unread > 0 && !c.archived) c,
    ].take(3).toList();

    Widget row({required IconData icon, required String title, String? subtitle, int count = 0, required VoidCallback onTap}) =>
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                      if (subtitle != null && subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                if (count > 0) Badge.count(count: count, backgroundColor: theme.colorScheme.primary),
              ],
            ),
          ),
        );

    return _Panel(
      title: l10n.teamNews,
      child: pinned.isEmpty && unread.isEmpty
          ? _Muted(l10n.noNews)
          : Column(
              children: [
                for (final a in pinned)
                  row(
                    icon: Icons.push_pin_outlined,
                    title: a.title,
                    subtitle: a.body,
                    onTap: () => context.push('/t/$teamId/announcements'),
                  ),
                for (final c in unread)
                  row(
                    icon: Icons.forum_outlined,
                    title: c.name,
                    subtitle: c.lastIsPoll ? l10n.pollPreview(c.lastBody ?? '') : c.lastBody,
                    count: c.unread,
                    onTap: () => context.push('/t/$teamId/chat/${c.id}'),
                  ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Who's been serving (leaders): times asked in the last 8 weeks, by name.
// Ordered by name, not count: it's for spreading the load, not ranking.

class _ServingLoad extends ConsumerWidget {
  const _ServingLoad({required this.teamId});
  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final counts = ref.watch(servingCountsProvider(teamId)).value ?? const <String, int>{};
    final members = [
      for (final m in ref.watch(teamMembersProvider(teamId)).value ?? const <Member>[])
        if (m.status == MemberStatus.active) m,
    ]..sort((a, b) => a.profile.displayName.compareTo(b.profile.displayName));
    final most = counts.values.fold(1, (a, b) => a > b ? a : b);

    return _Panel(
      title: l10n.servingLoad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.servingLoadHint,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          for (final m in members)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(m.profile.displayName, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (counts[m.userId] ?? 0) / most,
                        minHeight: 10,
                        color: palette.person(m.userId),
                        backgroundColor: theme.colorScheme.surfaceContainer,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      l10n.timesShort(counts[m.userId] ?? 0),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Songs to consider when planning (leaders).

class _SongNotes extends ConsumerWidget {
  const _SongNotes({required this.teamId});
  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final top = (ref.watch(topSongsProvider(teamId, StatsPeriod.months3)).value ?? const []).take(3).toList();
    final played = [
      for (final e in ref.watch(songLibraryProvider(teamId)).value ?? const [])
        if (e.stats.lastPlayedAt != null) e,
    ]..sort((a, b) => a.stats.lastPlayedAt!.compareTo(b.stats.lastPlayedAt!));
    final quiet = played.take(3).toList();

    Widget column(String title, List<(String, String)> rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        if (rows.isEmpty) const _Muted('—'),
        for (final (name, note) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontFamily: AppType.setlistFamily, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(note, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
      ],
    );

    return _Panel(
      title: l10n.songNotes,
      trailing: TextButton(onPressed: () => context.push('/t/$teamId/songs/stats'), child: Text(l10n.stats)),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 260,
            child: column(l10n.mostPlayedRecently, [for (final s in top) (s.title, l10n.timesShort(s.times))]),
          ),
          SizedBox(
            width: 260,
            child: column(l10n.notPlayedLately, [
              for (final e in quiet) (e.song.title, timeAgo(l10n, e.stats.lastPlayedAt!)),
            ]),
          ),
        ],
      ),
    );
  }
}
