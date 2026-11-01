import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/dates.dart';
import '../../core/music.dart';
import '../../core/music_widgets.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth.dart';
import '../teams/teams_providers.dart';
import 'models.dart';
import 'sheet_upload.dart';
import 'song_form.dart';
import 'songs_providers.dart';

class SongDetailScreen extends ConsumerWidget {
  const SongDetailScreen({super.key, required this.teamId, required this.songId});
  final int teamId;
  final int songId;

  void _refresh(WidgetRef ref) {
    ref
      ..invalidate(songDetailProvider(songId))
      ..invalidate(songSheetsProvider(songId))
      ..invalidate(songLibraryProvider(teamId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(songDetailProvider(songId));
    final isLeader = ref.watch(activeMembershipProvider(teamId))?.role.isLeader ?? false;
    final repo = ref.read(songsRepositoryProvider);

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
                  if (await runGuarded(context, () => repo.deleteSong(songId))) {
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
                l10n.sheets,
                trailing: TextButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: Text(l10n.uploadSheet),
                  onPressed: () => _upload(context, ref, d.song),
                ),
              ),
              for (final sheet in d.sheets) ...[
                _SheetRow(teamId: teamId, sheet: sheet, canDelete: isLeader || sheet.uploadedBy == ref.read(currentUserIdProvider), onChanged: () => _refresh(ref)),
                const Divider(indent: 20),
              ],
              if (d.sheets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(l10n.uploadSheetHint, style: Theme.of(context).textTheme.bodySmall),
                ),
              SectionHeader(
                l10n.originalLinks,
                trailing: TextButton.icon(
                  icon: const Icon(Icons.add_link),
                  label: Text(l10n.addLink),
                  onPressed: () => _addLink(context, ref, d.links.length),
                ),
              ),
              for (final link in d.links) ...[
                _LinkRow(link: link, onDelete: () async {
                  if (await runGuarded(context, () => repo.deleteLink(link.id))) _refresh(ref);
                }),
                const Divider(indent: 20),
              ],
              SectionHeader(l10n.history),
              for (final h in d.history)
                ListTile(
                  dense: true,
                  onTap: () => context.push('/t/$teamId/sessions/${h.sessionId}'),
                  title: Text(h.sessionTitle),
                  subtitle: Text(DateFormats(context).fullDate(h.startsAt)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (h.bpm case final bpm?)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text('$bpm BPM', style: Theme.of(context).textTheme.labelSmall),
                        ),
                      KeyBadge(h.key),
                    ],
                  ),
                ),
              if (d.history.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(l10n.neverPlayed, style: Theme.of(context).textTheme.bodySmall),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addLink(BuildContext context, WidgetRef ref, int count) async {
    final l10n = AppLocalizations.of(context);
    final url = TextEditingController();
    final label = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addLink),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: url, autofocus: true, keyboardType: TextInputType.url, decoration: InputDecoration(labelText: l10n.linkUrl)),
            const SizedBox(height: 12),
            TextField(controller: label, decoration: InputDecoration(labelText: l10n.linkLabel)),
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
      () => ref.read(songsRepositoryProvider).addLink(teamId, songId, url: text, label: label.text, sortOrder: count),
    );
    if (done) _refresh(ref);
  }

  Future<void> _upload(BuildContext context, WidgetRef ref, Song song) async {
    final l10n = AppLocalizations.of(context);
    PreparedSheet? prepared;
    final picked = await runGuarded(context, () async => prepared = await pickSheet());
    final sheet = prepared;
    if (!picked || sheet == null || !context.mounted) return;
    if (sheet.pageSizes.isEmpty) {
      showMessage(context, l10n.uploadSheetHint);
      return;
    }

    String? key = song.defaultKey;
    final label = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.uploadSheet),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.pages(sheet.pageSizes.length)),
              const SizedBox(height: 12),
              KeyField(value: key, onChanged: (k) => setState(() => key = k)),
              const SizedBox(height: 12),
              TextField(controller: label, decoration: InputDecoration(labelText: l10n.sheetLabel)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.uploadSheet)),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    showMessage(context, l10n.uploading);
    final done = await runGuarded(
      context,
      () => ref.read(songsRepositoryProvider).uploadSheet(
            teamId: teamId,
            songId: songId,
            pdf: sheet.pdf,
            pageSizes: sheet.pageSizes,
            key: key,
            label: label.text,
          ),
    );
    if (context.mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (done) _refresh(ref);
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
    final facts = [
      if (song.bpm != null) '${song.bpm} BPM',
      ?song.timeSignature,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (song.artist != null)
            Text(song.artist!, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Row(
            children: [
              KeyBadge(song.defaultKey, emphasized: true),
              if (song.defaultKey != null && facts.isNotEmpty) const SizedBox(width: 12),
              Text(facts.join('   '), style: theme.textTheme.bodyMedium),
            ],
          ),
          if (song.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final t in song.tags) Chip(label: Text(t), visualDensity: VisualDensity.compact)]),
          ],
          if (song.notes != null) ...[
            const SizedBox(height: 12),
            Text(song.notes!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          Text(
            stats.timesPlayed == 0
                ? l10n.neverPlayed
                : [
                    l10n.playedTimes(stats.timesPlayed),
                    if (stats.lastPlayedAt != null) l10n.lastPlayed(timeAgo(l10n, stats.lastPlayedAt!)),
                    if (stats.usualKey != null) l10n.usualKey(stats.usualKey!),
                  ].join(', '),
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (stats.nextPlannedAt != null)
            Text(l10n.nextPlanned(DateFormats(context).dayWithWeekday(stats.nextPlannedAt!)), style: theme.textTheme.bodySmall),
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
                final ok = await confirm(context, message: '${sheet.label ?? l10n.sheet} — ${l10n.delete}?', confirmLabel: l10n.delete, destructive: true);
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
    final id = youtubeId(link.url);
    final host = Uri.tryParse(link.url)?.host ?? link.url;
    return ListTile(
      onTap: () => launchUrl(Uri.parse(link.url), mode: LaunchMode.externalApplication),
      leading: id == null
          ? const Icon(Icons.link)
          : ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                'https://i.ytimg.com/vi/$id/default.jpg',
                width: 56,
                height: 42,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, _, _) => const Icon(Icons.smart_display_outlined),
              ),
            ),
      title: Text(link.label ?? host),
      subtitle: link.label == null ? null : Text(host),
      trailing: IconButton(tooltip: l10n.delete, icon: const Icon(Icons.close), onPressed: onDelete),
    );
  }
}
