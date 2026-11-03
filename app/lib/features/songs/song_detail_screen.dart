import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:url_launcher/url_launcher.dart';

import '../../core/dates.dart';
import '../../core/music_widgets.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth.dart';
import '../teams/teams_providers.dart';
import 'models.dart';
import 'song_artwork.dart';
import 'sheet_upload_button.dart';
import 'song_form.dart';
import 'songs_providers.dart';

/// A song: what its versions share, each version with its key, tempo,
/// sheets and links, and the services it was played in.
class SongDetailScreen extends ConsumerWidget {
  const SongDetailScreen({super.key, required this.teamId, required this.songId});
  final int teamId;
  final int songId;

  void _refresh(WidgetRef ref) {
    ref
      ..invalidate(songDetailProvider(songId))
      ..invalidate(songVersionsProvider(songId))
      ..invalidate(songLibraryProvider(teamId));
  }

  Future<void> _addVersion(BuildContext context, WidgetRef ref) async {
    final fields = await showVersionForm(context);
    if (fields == null || !context.mounted) return;
    if (await runGuarded(context, () => ref.read(songsRepositoryProvider).addVersion(teamId, songId, fields))) {
      _refresh(ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final detail = ref.watch(songDetailProvider(songId));
    final isLeader = ref.watch(activeMembershipProvider(teamId))?.role.isLeader ?? false;
    final me = ref.watch(currentUserIdProvider);
    final repo = ref.read(songsRepositoryProvider);
    final formats = DateFormats(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(detail.value?.song.title ?? ''),
        actions: [
          if (detail.value case final d?)
            PopupMenuButton<String>(
              onSelected: (action) async {
                if (action == 'edit') {
                  final fields = await showSongForm(context, song: d.song);
                  if (fields == null || !context.mounted) return;
                  if (await runGuarded(context, () => repo.updateSong(songId, fields))) _refresh(ref);
                } else if (action == 'delete') {
                  final ok = await confirm(
                    context,
                    message: l10n.deleteSongConfirm(d.song.title),
                    confirmLabel: l10n.deleteSong,
                    destructive: true,
                  );
                  if (!ok || !context.mounted) return;
                  if (await runGuarded(context, () => repo.deleteSong(d.song))) {
                    ref.invalidate(songLibraryProvider(teamId));
                    if (context.mounted) context.pop();
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.editSong)),
                if (isLeader) PopupMenuItem(value: 'delete', child: Text(l10n.deleteSong)),
              ],
            ),
        ],
      ),
      body: AsyncBody(
        value: detail,
        onRetry: () => _refresh(ref),
        data: (d) => ContentWidth(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 48),
            children: [
              _Header(detail: d),
              SectionHeader(
                l10n.versions,
                trailing: AddButton(label: l10n.addVersion, onPressed: () => _addVersion(context, ref)),
              ),
              for (final v in d.song.versions)
                _VersionCard(
                  teamId: teamId,
                  version: v,
                  played: [
                    for (final h in d.history)
                      if (h.versionId == v.id) h,
                  ],
                  // A song keeps at least one version to play.
                  canDelete: d.song.versions.length > 1 && (isLeader || v.createdBy == me),
                  canDeleteSheet: (sheet) => isLeader || sheet.uploadedBy == me,
                  onChanged: () => _refresh(ref),
                ),
              SectionHeader(l10n.history),
              for (final h in d.history)
                ListTile(
                  dense: true,
                  onTap: () => context.push('/t/$teamId/sessions/${h.sessionId}'),
                  title: Text(h.sessionTitle),
                  subtitle: Text([formats.fullDate(h.startsAt), ?h.versionName].join('  ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (h.bpm case final bpm?)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text('$bpm BPM', style: theme.textTheme.labelSmall),
                        ),
                      KeyBadge(h.key),
                    ],
                  ),
                ),
              if (d.history.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(l10n.neverPlayed, style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail});
  final SongDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final song = detail.song;
    final stats = detail.stats;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (songThumbnail(song) case final url?) ...[
            SongArtwork(url: url, width: 160, height: 90),
            const SizedBox(height: 12),
          ],
          Text(
            stats.timesPlayed == 0
                ? l10n.neverPlayed
                : [
                    l10n.playedTimes(stats.timesPlayed),
                    if (stats.lastPlayedAt != null) l10n.lastPlayed(DateFormats(context).ago(stats.lastPlayedAt!)),
                    if (stats.usualKey != null) l10n.usualKey(stats.usualKey!),
                  ].join(', '),
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (stats.nextPlannedAt != null)
            Text(
              l10n.nextPlanned(DateFormats(context).dayWithWeekday(stats.nextPlannedAt!)),
              style: theme.textTheme.bodySmall,
            ),
          if (song.timeSignature != null || song.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (song.timeSignature case final time?)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(time, style: theme.textTheme.bodyMedium),
                  ),
                for (final t in song.tags) Chip(label: Text(t), visualDensity: VisualDensity.compact),
              ],
            ),
          ],
          if (song.notes != null) ...[const SizedBox(height: 12), Text(song.notes!, style: theme.textTheme.bodyMedium)],
        ],
      ),
    );
  }
}

/// One version: whose it is, its key and tempo, how often it was played,
/// and its sheets and links with the ways to add more.
class _VersionCard extends ConsumerWidget {
  const _VersionCard({
    required this.teamId,
    required this.version,
    required this.played,
    required this.canDelete,
    required this.canDeleteSheet,
    required this.onChanged,
  });
  final int teamId;
  final SongVersion version;

  /// The announced services that played this version, newest first.
  final List<SongHistoryEntry> played;
  final bool canDelete;
  final bool Function(Sheet sheet) canDeleteSheet;
  final VoidCallback onChanged;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final fields = await showVersionForm(context, version: version);
    if (fields == null || !context.mounted) return;
    if (await runGuarded(context, () => ref.read(songsRepositoryProvider).updateVersion(version.id, fields))) {
      onChanged();
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String title) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirm(
      context,
      message: l10n.deleteVersionConfirm(title),
      confirmLabel: l10n.deleteVersion,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(songsRepositoryProvider).deleteVersion(version);
      onChanged();
    } on PostgrestException catch (e) {
      if (!context.mounted) return;
      // Still played by some setlist (the database refuses to delete it).
      e.code == '23503' ? showMessage(context, l10n.versionInUse) : showError(context, e);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _addLink(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final url = TextEditingController();
    final label = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addLink),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: url,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: l10n.linkUrl),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: label,
              decoration: InputDecoration(labelText: l10n.linkLabel),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    var text = url.text.trim();
    if (!text.startsWith(RegExp('https?://'))) text = 'https://$text';
    final done = await runGuarded(
      context,
      () => ref
          .read(songsRepositoryProvider)
          .addLink(teamId, version.id, url: text, label: label.text, sortOrder: version.links.length),
    );
    if (done) onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final title = version.name ?? l10n.unnamedVersion;
    final now = DateTime.now();
    final past = played.where((h) => !h.startsAt.isAfter(now)).toList();
    final usage = past.isEmpty
        ? l10n.neverPlayed
        : '${l10n.playedTimes(past.length)}, ${l10n.lastPlayed(DateFormats(context).ago(past.first.startsAt))}';

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        usage,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                KeyBadge(version.defaultKey, emphasized: true),
                if (version.bpm case final bpm?)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text('$bpm BPM', style: theme.textTheme.labelLarge),
                  ),
                PopupMenuButton<String>(
                  onSelected: (action) => action == 'edit' ? _edit(context, ref) : _delete(context, ref, title),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(l10n.editVersion)),
                    if (canDelete) PopupMenuItem(value: 'delete', child: Text(l10n.deleteVersion)),
                  ],
                ),
              ],
            ),
          ),
          for (final sheet in version.sheets)
            _SheetRow(teamId: teamId, sheet: sheet, canDelete: canDeleteSheet(sheet), onChanged: onChanged),
          for (final link in version.links)
            _LinkRow(
              link: link,
              onDelete: () async {
                if (await runGuarded(context, () => ref.read(songsRepositoryProvider).deleteLink(link.id))) onChanged();
              },
            ),
          if (version.sheets.isEmpty && version.links.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(l10n.uploadSheetHint, style: theme.textTheme.bodySmall),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Wrap(
              spacing: 4,
              children: [
                SheetUploadButton(teamId: teamId, version: version, onChanged: onChanged),
                TextButton.icon(
                  icon: const Icon(Icons.add_link),
                  label: Text(l10n.addLink),
                  onPressed: () => _addLink(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetRow extends ConsumerWidget {
  const _SheetRow({required this.teamId, required this.sheet, required this.canDelete, required this.onChanged});
  final int teamId;
  final Sheet sheet;
  final bool canDelete;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text(sheet.label ?? l10n.sheet),
      subtitle: Text(l10n.pages(sheet.pageCount)),
      onTap: () => context.push('/t/$teamId/sheets/${sheet.id}', extra: sheet),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KeyBadge(sheet.key),
          if (canDelete)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await confirm(
                  context,
                  message: '${sheet.label ?? l10n.sheet} — ${l10n.delete}?',
                  confirmLabel: l10n.delete,
                  destructive: true,
                );
                if (!ok || !context.mounted) return;
                if (await runGuarded(context, () => ref.read(songsRepositoryProvider).deleteSheet(sheet))) onChanged();
              },
            ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.link, required this.onDelete});
  final SongLink link;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final thumbnail = linkThumbnail(link.url);
    final host = Uri.tryParse(link.url)?.host ?? link.url;
    return ListTile(
      onTap: () => launchUrl(Uri.parse(link.url), mode: LaunchMode.externalApplication),
      leading: thumbnail == null ? const Icon(Icons.link) : SongArtwork(url: thumbnail),
      title: Text(link.label ?? host),
      subtitle: link.label == null ? null : Text(host),
      trailing: IconButton(tooltip: l10n.delete, icon: const Icon(Icons.close), onPressed: onDelete),
    );
  }
}
