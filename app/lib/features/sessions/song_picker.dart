import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/music_widgets.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../songs/models.dart';
import '../songs/song_artwork.dart';
import '../songs/song_form.dart' show showNewSongForm;
import '../songs/songs_providers.dart';
import '../songs/songs_screen.dart' show statsLine;

/// Pick a song for the setlist, with how often and how recently the team
/// sang it, or add a new one on the spot.
Future<SongEntry?> pickSong(BuildContext context, {required int teamId}) => showModalBottomSheet<SongEntry>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.85,
    maxChildSize: 0.95,
    builder: (context, controller) => _SongPicker(teamId: teamId, controller: controller),
  ),
);

class _SongPicker extends ConsumerStatefulWidget {
  const _SongPicker({required this.teamId, required this.controller});
  final int teamId;
  final ScrollController controller;

  @override
  ConsumerState<_SongPicker> createState() => _SongPickerState();
}

class _SongPickerState extends ConsumerState<_SongPicker> {
  String _query = '';

  Future<void> _createAndPick() async {
    final draft = await showNewSongForm(context);
    if (draft == null || !mounted) return;
    final repo = ref.read(songsRepositoryProvider);
    var id = -1;
    if (!await runGuarded(context, () async => id = await repo.addSong(widget.teamId, draft.song, draft.version))) {
      return;
    }
    ref.invalidate(songLibraryProvider(widget.teamId));
    final library = await ref.read(songLibraryProvider(widget.teamId).future);
    if (!mounted) return;
    Navigator.pop(context, library.firstWhere((e) => e.song.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final library = ref.watch(songLibraryProvider(widget.teamId));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.searchSongs, prefixIcon: const Icon(Icons.search)),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: AsyncBody(
            value: library,
            onRetry: () => ref.invalidate(songLibraryProvider(widget.teamId)),
            data: (songs) {
              final shown = songs
                  .where(
                    (e) =>
                        _query.isEmpty ||
                        e.song.title.toLowerCase().contains(_query) ||
                        (e.versionNames ?? '').toLowerCase().contains(_query),
                  )
                  .toList();
              return ListView(
                controller: widget.controller,
                children: [
                  ListTile(leading: const Icon(Icons.add), title: Text(l10n.addSong), onTap: _createAndPick),
                  const Divider(),
                  for (final e in shown)
                    ListTile(
                      onTap: () => Navigator.pop(context, e),
                      leading: SongArtwork(url: songThumbnail(e.song)),
                      title: Text(e.song.title),
                      subtitle: Text([?e.versionNames, statsLine(context, e.stats)].join('\n')),
                      isThreeLine: e.versionNames != null,
                      trailing: KeyBadge(e.displayKey),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Which version of [entry] a service plays: asked only when the song has
/// more than one, offering first the version played last. Null when
/// cancelled.
Future<SongVersion?> pickVersion(BuildContext context, SongEntry entry) async {
  final versions = entry.song.versions;
  if (versions.length <= 1) return versions.firstOrNull;
  final preferred = entry.preferredVersion;
  final ordered = [?preferred, ...versions.where((v) => v.id != preferred?.id)];
  return showModalBottomSheet<SongVersion>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final theme = Theme.of(context);
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(entry.song.title, style: theme.textTheme.titleMedium),
            ),
            for (final v in ordered)
              ListTile(
                leading: SongArtwork(url: linksThumbnail(v.links)),
                title: Text(v.name ?? l10n.unnamedVersion),
                subtitle: v.id == entry.stats.lastVersionId ? Text(l10n.playedLast) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (v.bpm case final bpm?)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text('$bpm BPM', style: theme.textTheme.labelMedium),
                      ),
                    KeyBadge(v.defaultKey),
                  ],
                ),
                onTap: () => Navigator.pop(context, v),
              ),
          ],
        ),
      );
    },
  );
}
