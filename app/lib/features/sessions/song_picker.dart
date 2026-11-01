import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/music_widgets.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../songs/models.dart';
import '../songs/song_form.dart';
import '../songs/songs_providers.dart';
import '../songs/songs_screen.dart' show statsLine;

/// Pick a song for the setlist, with how often and how recently the team
/// sang it, or add a new one on the spot.
Future<SongEntry?> pickSong(BuildContext context, {required int teamId, Set<int> alreadyIn = const {}}) =>
    showModalBottomSheet<SongEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, controller) => _SongPicker(teamId: teamId, alreadyIn: alreadyIn, controller: controller),
      ),
    );

class _SongPicker extends ConsumerStatefulWidget {
  const _SongPicker({required this.teamId, required this.alreadyIn, required this.controller});
  final int teamId;
  final Set<int> alreadyIn;
  final ScrollController controller;

  @override
  ConsumerState<_SongPicker> createState() => _SongPickerState();
}

class _SongPickerState extends ConsumerState<_SongPicker> {
  String _query = '';

  Future<void> _createAndPick() async {
    final fields = await showSongForm(context);
    if (fields == null || !mounted) return;
    final repo = ref.read(songsRepositoryProvider);
    var id = -1;
    if (!await runGuarded(context, () async => id = await repo.addSong(widget.teamId, fields))) return;
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
                  .where((e) =>
                      _query.isEmpty ||
                      e.song.title.toLowerCase().contains(_query) ||
                      (e.song.artist ?? '').toLowerCase().contains(_query))
                  .toList();
              return ListView(
                controller: widget.controller,
                children: [
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: Text(l10n.addSong),
                    onTap: _createAndPick,
                  ),
                  const Divider(),
                  for (final e in shown)
                    ListTile(
                      enabled: !widget.alreadyIn.contains(e.song.id),
                      onTap: () => Navigator.pop(context, e),
                      title: Text(e.song.title),
                      subtitle: Text(statsLine(l10n, e.stats)),
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
