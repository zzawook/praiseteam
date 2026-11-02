import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/music_widgets.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'songs_providers.dart';
import 'song_artwork.dart';

/// Most played songs in a period, and songs not played for a while.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key, required this.teamId});
  final int teamId;

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  StatsPeriod _period = StatsPeriod.months3;
  static const _staleMonths = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final top = ref.watch(topSongsProvider(widget.teamId, _period));
    final library = ref.watch(songLibraryProvider(widget.teamId)).value ?? const [];
    final thumbnails = {for (final e in library) e.song.id: songThumbnail(e.song)};
    final cutoff = DateTime.now().subtract(const Duration(days: 30 * _staleMonths));
    final stale = library.where((e) => e.stats.lastPlayedAt != null && e.stats.lastPlayedAt!.isBefore(cutoff)).toList()
      ..sort((a, b) => a.stats.lastPlayedAt!.compareTo(b.stats.lastPlayedAt!));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.stats)),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 48),
          children: [
            SectionHeader(l10n.topSongs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedButton<StatsPeriod>(
                segments: [
                  ButtonSegment(value: StatsPeriod.months3, label: Text(l10n.period3m)),
                  ButtonSegment(value: StatsPeriod.months6, label: Text(l10n.period6m)),
                  ButtonSegment(value: StatsPeriod.year1, label: Text(l10n.period1y)),
                  ButtonSegment(value: StatsPeriod.all, label: Text(l10n.periodAll)),
                ],
                selected: {_period},
                onSelectionChanged: (s) => setState(() => _period = s.first),
              ),
            ),
            const SizedBox(height: 8),
            AsyncBody(
              value: top,
              onRetry: () => ref.invalidate(topSongsProvider(widget.teamId, _period)),
              data: (songs) {
                if (songs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(l10n.neverPlayed, style: theme.textTheme.bodyMedium),
                  );
                }
                final max = songs.first.times;
                return Column(
                  children: [
                    for (final s in songs)
                      ListTile(
                        leading: SongArtwork(url: thumbnails[s.songId]),
                        onTap: () => context.push('/t/${widget.teamId}/songs/${s.songId}'),
                        title: Text(s.title),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: s.times / max,
                              minHeight: 4,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                        trailing: Text(l10n.timesShort(s.times), style: theme.textTheme.titleMedium),
                      ),
                  ],
                );
              },
            ),
            SectionHeader(l10n.notPlayedSince(_staleMonths)),
            for (final e in stale)
              ListTile(
                leading: SongArtwork(url: songThumbnail(e.song)),
                onTap: () => context.push('/t/${widget.teamId}/songs/${e.song.id}'),
                title: Text(e.song.title),
                subtitle: Text(l10n.lastPlayed(DateFormats(context).ago(e.stats.lastPlayedAt!))),
                trailing: KeyBadge(e.displayKey),
              ),
          ],
        ),
      ),
    );
  }
}
