import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/music_widgets.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../songs/models.dart';
import '../songs/song_artwork.dart';
import 'models.dart';

enum SetlistItemAction { viewSheet, songDetails, edit }

/// Everyone opens the same reading view. References belong to the arrangement
/// selected for this service; artwork from another arrangement is not a link.
Future<SetlistItemAction?> showSetlistItemDetails(
  BuildContext context, {
  required SetlistItem item,
  required bool canEdit,
}) => showModalBottomSheet<SetlistItemAction>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 720),
  builder: (_) => _ItemDetails(item: item, canEdit: canEdit),
);

class _ItemDetails extends StatelessWidget {
  const _ItemDetails({required this.item, required this.canEdit});
  final SetlistItem item;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final links = item.version?.links ?? const <SongLink>[];
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.song.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: AppType.setlistFamily,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(tooltip: l10n.close, onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            Text(
              '${l10n.selectedVersion}: ${item.version?.name ?? l10n.unnamedVersion}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (item.effectiveKey != null || item.effectiveBpm != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (item.effectiveKey != null) KeyBadge(item.effectiveKey, emphasized: true),
                  if (item.effectiveBpm case final bpm?) Text('$bpm BPM', style: theme.textTheme.titleSmall),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text(l10n.referenceLinks, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (links.isEmpty)
              Text(
                l10n.noVersionLinks,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            else
              for (final link in links) _ReferenceLink(link: link),
            if (item.songForm case final form?) ...[
              const SizedBox(height: 20),
              Text(l10n.songForm, style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              SelectableText(form, style: theme.textTheme.bodyLarge),
            ],
            if (item.notes case final notes?) ...[
              const SizedBox(height: 20),
              Text(l10n.notes, style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              SelectableText(notes, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, SetlistItemAction.viewSheet),
                  icon: const Icon(Icons.library_music_outlined, size: 20),
                  label: Text(l10n.viewSheet),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, SetlistItemAction.songDetails),
                  icon: const Icon(Icons.info_outline, size: 20),
                  label: Text(l10n.fullSongDetails),
                ),
                if (canEdit)
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context, SetlistItemAction.edit),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: Text(l10n.editSetlistItem),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceLink extends StatelessWidget {
  const _ReferenceLink({required this.link});
  final SongLink link;

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri.tryParse(link.url);
    if (uri == null || !const {'http', 'https'}.contains(uri.scheme) || uri.host.isEmpty) {
      showMessage(context, l10n.linkOpenFailed);
      return;
    }
    try {
      // Launch directly from the tap so Safari retains user activation.
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
      if (!opened && context.mounted) showMessage(context, l10n.linkOpenFailed);
    } catch (_) {
      if (context.mounted) showMessage(context, l10n.linkOpenFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final thumbnail = linkThumbnail(link.url);
    final uri = Uri.tryParse(link.url);
    final host = uri?.host ?? link.url;
    Widget tile(VoidCallback? onTap) => ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      onTap: onTap,
      leading: thumbnail == null ? const Icon(Icons.link) : SongArtwork(url: thumbnail, width: 80, height: 45),
      title: Text(link.label ?? (thumbnail == null ? host : l10n.watchOnYouTube)),
      subtitle: Text(host, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.open_in_new, size: 20),
    );
    if (kIsWeb && uri != null && const {'http', 'https'}.contains(uri.scheme) && uri.host.isNotEmpty) {
      // The browser link owns href AND target, including keyboard/VoiceOver
      // activation. A plain semantic href would also navigate the service tab.
      return Link(uri: uri, target: LinkTarget.blank, builder: (_, followLink) => tile(followLink));
    }
    return Semantics(link: true, child: tile(() => _open(context)));
  }
}
