import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth.dart';
import '../rotation/rehearsals.dart';
import '../rotation/rotation_providers.dart';
import '../rotation/rotation_repository.dart';
import '../sessions/models.dart';
import '../sessions/sessions_providers.dart';
import '../songs/song_artwork.dart';
import '../teams/models.dart';
import '../teams/teams_providers.dart';

/// The next service, in team ink: when it is, what I play, the setlist and
/// its rehearsal, and the way to the stand. The one bold card on the home
/// screen.
class NextServiceCard extends ConsumerWidget {
  const NextServiceCard({super.key, required this.teamId, required this.session});
  final int teamId;
  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final formats = DateFormats(context);
    final local = formats.clock.local(session.startsAt);
    final items = ref.watch(setlistProvider(session.id)).value ?? const <SetlistItem>[];
    final rehearsal = ref
        .watch(sessionRehearsalsProvider(session.id))
        .value
        ?.where((r) => r.startsAt.isAfter(DateTime.now()))
        .firstOrNull;
    final me = ref.watch(currentUserIdProvider);
    final parts = {for (final p in ref.watch(teamPartsProvider(teamId)).value ?? const <Part>[]) p.id: p.name};
    final mine = [
      for (final a in ref.watch(rotationBoardProvider(teamId)).value?.assignments ?? const <Assignment>[])
        if (a.sessionId == session.id &&
            a.userId == me &&
            (a.status == AssignmentStatus.pending || a.status == AssignmentStatus.accepted))
          a,
    ];
    final days = formats.clock.daysUntil(session.startsAt);
    final when = days <= 0
        ? l10n.today
        : days == 1
        ? l10n.tomorrow
        : l10n.inDays(days);
    final fg = palette.onHero;
    final soft = fg.withValues(alpha: 0.75);
    final serif = theme.textTheme.titleMedium?.copyWith(fontFamily: AppType.setlistFamily, fontWeight: FontWeight.w700);

    return Card(
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
                    child: Text('${l10n.nextService}  $when', style: theme.textTheme.labelLarge?.copyWith(color: soft)),
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
              if (rehearsal != null)
                Text(
                  l10n.rehearsalAt(
                    [
                      formats.dayWithWeekday(rehearsal.startsAt),
                      formats.time(rehearsal.startsAt),
                      ?rehearsal.location,
                    ].join('  '),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(color: soft),
                ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                Text(l10n.setlistComing, style: theme.textTheme.bodyMedium?.copyWith(color: soft))
              else ...[
                for (final (i, item) in items.take(4).indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text('${i + 1}', style: serif?.copyWith(color: soft)),
                        ),
                        SongArtwork(url: setlistThumbnail(item), width: 80, height: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.song.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: serif?.copyWith(color: fg),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                    padding: const EdgeInsets.only(left: 116, top: 2),
                    child: Text(
                      l10n.moreSongs(items.length - 4),
                      style: theme.textTheme.bodySmall?.copyWith(color: soft),
                    ),
                  ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: fg,
                    foregroundColor: palette.hero,
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: () => context.push('/t/$teamId/stand/${session.id}'),
                  icon: const Icon(Icons.library_music_outlined, size: 20),
                  label: Text(l10n.viewSheets),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
