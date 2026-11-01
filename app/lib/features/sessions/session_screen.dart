import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/music_widgets.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../notifications/notification_bell.dart';
import '../rotation/rehearsals.dart';
import '../songs/songs_providers.dart';
import '../teams/teams_providers.dart';
import 'models.dart';
import 'session_editor.dart';
import 'sessions_providers.dart';
import 'setlist_item_editor.dart';
import 'song_picker.dart';

/// One service: when and where, and its setlist (콘티).
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, required this.teamId, required this.sessionId});
  final int teamId;
  final int sessionId;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  /// Order shown while a reorder is being saved.
  List<SetlistItem>? _pendingOrder;
  bool _publishing = false;

  void _refresh() {
    ref
      ..invalidate(sessionProvider(widget.sessionId))
      ..invalidate(setlistProvider(widget.sessionId))
      ..invalidate(upcomingSessionsProvider(widget.teamId))
      ..invalidate(pastSessionsProvider(widget.teamId))
      ..invalidate(songLibraryProvider(widget.teamId));
  }

  Future<void> _addSong(List<SetlistItem> items) async {
    final entry = await pickSong(context, teamId: widget.teamId, alreadyIn: {for (final i in items) i.songId});
    if (entry == null || !mounted) return;
    final position = items.isEmpty ? 1 : items.map((i) => i.position).reduce((a, b) => a > b ? a : b) + 1;
    final ok = await runGuarded(context, () async {
      // Attach the song's sheet right away: the one in this key, else the
      // first one. Leaders can pick another in the item editor.
      final sheets = await ref.read(songsRepositoryProvider).sheetsFor(entry.song.id);
      final sheet = sheets.where((s) => s.key == entry.displayKey).firstOrNull ?? sheets.firstOrNull;
      await ref.read(sessionsRepositoryProvider).addItem(
            teamId: widget.teamId,
            sessionId: widget.sessionId,
            songId: entry.song.id,
            position: position,
            key: entry.displayKey,
            bpm: entry.song.bpm,
            sheetId: sheet?.id,
          );
    });
    if (ok) ref.invalidate(setlistProvider(widget.sessionId));
  }

  /// [to] is already adjusted for the removed item (onReorderItem).
  Future<void> _reorder(List<SetlistItem> items, int from, int to) async {
    final next = [...items];
    next.insert(to, next.removeAt(from));
    setState(() => _pendingOrder = next);
    await runGuarded(
      context,
      () => ref.read(sessionsRepositoryProvider).reorder(widget.sessionId, [for (final i in next) i.id]),
    );
    ref.invalidate(setlistProvider(widget.sessionId));
    await ref.read(setlistProvider(widget.sessionId).future).catchError((_) => <SetlistItem>[]);
    if (mounted) setState(() => _pendingOrder = null);
  }

  Future<void> _publish(Session session) async {
    final l10n = AppLocalizations.of(context);
    final first = session.setlistStatus == SetlistStatus.draft;
    final ok = await confirm(
      context,
      message: first ? l10n.publishConfirm : l10n.republishConfirm,
      confirmLabel: first ? l10n.publishSetlist : l10n.republishSetlist,
    );
    if (!ok || !mounted) return;
    setState(() => _publishing = true);
    SetlistChanges? changes;
    await runGuarded(context, () async => changes = await ref.read(sessionsRepositoryProvider).publish(widget.sessionId));
    if (!mounted) return;
    setState(() => _publishing = false);
    final result = changes;
    if (result == null) return;
    showMessage(
      context,
      first
          ? l10n.published
          : result.isEmpty
              ? l10n.noChanges
              : '${l10n.published}: ${describeSetlistChanges(l10n, result)}',
    );
    _refresh();
  }

  Future<void> _edit(Session session) async {
    final saved = await showSessionEditor(context, teamId: session.teamId, session: session);
    if (saved != null && mounted) _refresh();
  }

  Future<void> _delete(Session session) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirm(
      context,
      message: l10n.deleteSessionConfirm(session.title),
      confirmLabel: l10n.deleteSession,
      destructive: true,
    );
    if (!ok || !mounted) return;
    if (await runGuarded(context, () => ref.read(sessionsRepositoryProvider).deleteSession(session.id))) {
      _refresh();
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLeader = ref.watch(activeMembershipProvider(widget.teamId))?.role.isLeader ?? false;
    final session = ref.watch(sessionProvider(widget.sessionId));
    final setlist = ref.watch(setlistProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(
        title: Text(session.value?.title ?? ''),
        actions: [
          if (setlist.value?.isNotEmpty ?? false)
            IconButton(
              tooltip: l10n.viewSheets,
              icon: const Icon(Icons.chrome_reader_mode_outlined),
              onPressed: () => context.push('/t/${widget.teamId}/stand/${widget.sessionId}'),
            ),
          NotificationBell(teamId: widget.teamId),
          if (isLeader && session.value != null)
            PopupMenuButton<String>(
              onSelected: (a) => a == 'edit' ? _edit(session.value!) : _delete(session.value!),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.editSession)),
                PopupMenuItem(value: 'delete', child: Text(l10n.deleteSession)),
              ],
            ),
        ],
      ),
      bottomNavigationBar: isLeader && (setlist.value?.isNotEmpty ?? false) && session.value != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: ContentWidth(
                  child: FilledButton.icon(
                    onPressed: _publishing ? null : () => _publish(session.value!),
                    icon: const Icon(Icons.campaign_outlined),
                    label: Text(
                      session.value!.setlistStatus == SetlistStatus.draft ? l10n.publishSetlist : l10n.republishSetlist,
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: AsyncBody(
        value: session,
        onRetry: _refresh,
        data: (s) => AsyncBody(
          value: setlist,
          onRetry: _refresh,
          data: (items) => ContentWidth(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _SessionInfo(session: s)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: _SetlistSheet(
                    session: s,
                    items: _pendingOrder ?? items,
                    isLeader: isLeader,
                    onTapItem: (item) => isLeader
                        ? showSetlistItemEditor(context, item: item)
                        : context.push('/t/${widget.teamId}/stand/${widget.sessionId}?item=${item.id}'),
                    onReorder: (from, to) => _reorder(_pendingOrder ?? items, from, to),
                    onAdd: () => _addSong(items),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: SessionServingSection(
                      teamId: widget.teamId,
                      sessionId: widget.sessionId,
                      sessionStart: s.startsAt,
                      isLeader: isLeader,
                      partNames: {for (final p in ref.watch(teamPartsProvider(widget.teamId)).value ?? const []) p.id: p.name},
                    ),
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

class _SessionInfo extends StatelessWidget {
  const _SessionInfo({required this.session});
  final Session session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formats = DateFormats(context);
    final local = session.startsAt.toLocal();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${formats.dayWithWeekday(local)}  ${formats.time(local)}', style: theme.textTheme.titleMedium),
          if (session.location != null) Text(session.location!, style: theme.textTheme.bodyMedium),
          if (session.theme != null) ...[
            const SizedBox(height: 8),
            Text(session.theme!, style: theme.textTheme.bodyLarge),
          ],
          if (session.notes != null) ...[
            const SizedBox(height: 8),
            Text(session.notes!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

/// The setlist as a printed sheet: serif song names, numbered in order,
/// with the key boxed like a key signature.
class _SetlistSheet extends StatelessWidget {
  const _SetlistSheet({
    required this.session,
    required this.items,
    required this.isLeader,
    required this.onTapItem,
    required this.onReorder,
    required this.onAdd,
  });
  final Session session;
  final List<SetlistItem> items;
  final bool isLeader;
  final void Function(SetlistItem) onTapItem;
  final void Function(int from, int to) onReorder;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final published = session.setlistStatus == SetlistStatus.published;

    final heading = Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            l10n.setlist,
            style: theme.textTheme.headlineSmall?.copyWith(fontFamily: AppType.setlistFamily, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text(
            published ? l10n.setlistPublished : l10n.setlistDraft,
            style: theme.textTheme.labelLarge?.copyWith(color: published ? AppColors.teamInk : AppColors.myPencil),
          ),
        ],
      ),
    );

    Widget row(SetlistItem item, int index) => _SetlistRow(
          key: ValueKey(item.id),
          index: index,
          item: item,
          draggable: isLeader,
          onTap: () => onTapItem(item),
        );

    final empty = items.isEmpty
        ? Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(isLeader ? l10n.setlistEmptyLeader : l10n.setlistEmptyMember, style: theme.textTheme.bodyMedium),
          )
        : const SizedBox.shrink();

    return DecoratedSliver(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(child: heading),
          SliverToBoxAdapter(child: empty),
          if (isLeader)
            SliverReorderableList(
              itemCount: items.length,
              itemBuilder: (context, i) => row(items[i], i),
              onReorderItem: onReorder,
            )
          else
            SliverList.builder(itemCount: items.length, itemBuilder: (context, i) => row(items[i], i)),
          if (isLeader)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: Text(l10n.addSongToSetlist)),
                ),
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
        ],
      ),
    );
  }
}

class _SetlistRow extends StatelessWidget {
  const _SetlistRow({super.key, required this.index, required this.item, required this.draggable, required this.onTap});
  final int index;
  final SetlistItem item;
  final bool draggable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serif = theme.textTheme.titleLarge?.copyWith(fontFamily: AppType.setlistFamily, fontWeight: FontWeight.w700);
    final details = [
      if (item.songForm != null) item.songForm!,
      if (item.notes != null) item.notes!,
    ];
    final content = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 28, child: Text('${index + 1}', style: serif?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.song.title, style: serif),
                  for (final d in details)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(d, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                children: [
                  KeyBadge(item.effectiveKey, emphasized: true),
                  if (item.effectiveBpm case final bpm?)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$bpm BPM',
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
            if (draggable)
              ReorderableDragStartListener(
                index: index,
                child: const Padding(padding: EdgeInsets.only(left: 8, top: 2), child: Icon(Icons.drag_indicator)),
              ),
          ],
        ),
      ),
    );
    return Material(type: MaterialType.transparency, child: content);
  }
}
