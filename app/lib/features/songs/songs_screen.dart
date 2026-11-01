import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell.dart';
import '../../core/dates.dart';
import '../../core/music_widgets.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../notifications/notification_bell.dart';
import 'models.dart';
import 'song_form.dart';
import 'songs_providers.dart';

enum SongSort { title, recent, most, longAgo }

/// "총 12회, 마지막 3주 전" / "아직 안 했어요"
String statsLine(AppLocalizations l10n, SongStats stats) {
  final last = stats.lastPlayedAt;
  if (stats.timesPlayed == 0 || last == null) return l10n.neverPlayed;
  return '${l10n.playedTimes(stats.timesPlayed)}, ${l10n.lastPlayed(timeAgo(l10n, last))}';
}

class SongsScreen extends ConsumerStatefulWidget {
  const SongsScreen({super.key, required this.teamId});
  final int teamId;

  @override
  ConsumerState<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends ConsumerState<SongsScreen> {
  String _query = '';
  SongSort _sort = SongSort.title;

  List<SongEntry> _arrange(List<SongEntry> songs) {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? [...songs]
        : songs
            .where((e) =>
                e.song.title.toLowerCase().contains(q) ||
                (e.song.artist ?? '').toLowerCase().contains(q) ||
                e.song.tags.any((t) => t.toLowerCase().contains(q)))
            .toList();
    final never = DateTime(1900);
    switch (_sort) {
      case SongSort.title:
        break; // already by title from the server
      case SongSort.recent:
        filtered.sort((a, b) => (b.stats.lastPlayedAt ?? never).compareTo(a.stats.lastPlayedAt ?? never));
      case SongSort.most:
        filtered.sort((a, b) => b.stats.timesPlayed.compareTo(a.stats.timesPlayed));
      case SongSort.longAgo:
        // Played before, longest ago first; never-played songs last.
        filtered.sort((a, b) {
          final x = a.stats.lastPlayedAt, y = b.stats.lastPlayedAt;
          if (x == null && y == null) return 0;
          if (x == null) return 1;
          if (y == null) return -1;
          return x.compareTo(y);
        });
    }
    return filtered;
  }

  Future<void> _addSong() async {
    final fields = await showSongForm(context);
    if (fields == null || !mounted) return;
    var id = -1;
    final ok = await runGuarded(
      context,
      () async => id = await ref.read(songsRepositoryProvider).addSong(widget.teamId, fields),
    );
    if (!ok || !mounted) return;
    ref.invalidate(songLibraryProvider(widget.teamId));
    context.push('/t/${widget.teamId}/songs/$id');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final narrow = MediaQuery.sizeOf(context).width < Breakpoints.rail;
    final library = ref.watch(songLibraryProvider(widget.teamId));

    return Scaffold(
      appBar: AppBar(
        title: narrow ? TeamSwitcher(teamId: widget.teamId) : Text(l10n.navSongs),
        actions: [
          IconButton(
            tooltip: l10n.stats,
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => context.push('/t/${widget.teamId}/songs/stats'),
          ),
          NotificationBell(teamId: widget.teamId),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSong,
        icon: const Icon(Icons.add),
        label: Text(l10n.addSong),
      ),
      body: AsyncBody(
        value: library,
        onRetry: () => ref.invalidate(songLibraryProvider(widget.teamId)),
        data: (songs) {
          final shown = _arrange(songs);
          return ContentWidth(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: l10n.searchSongs,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final (sort, label) in [
                          (SongSort.title, l10n.sortTitle),
                          (SongSort.recent, l10n.sortRecent),
                          (SongSort.most, l10n.sortMost),
                          (SongSort.longAgo, l10n.sortLongAgo),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: _sort == sort,
                            onSelected: (_) => setState(() => _sort = sort),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverList.separated(
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const Divider(indent: 20),
                  itemBuilder: (context, i) {
                    final e = shown[i];
                    return ListTile(
                      onTap: () => context.push('/t/${widget.teamId}/songs/${e.song.id}'),
                      title: Text(e.song.title),
                      subtitle: Text(
                        [if (e.song.artist != null) e.song.artist!, statsLine(l10n, e.stats)].join('\n'),
                      ),
                      isThreeLine: e.song.artist != null,
                      trailing: KeyBadge(e.displayKey),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          );
        },
      ),
    );
  }
}
