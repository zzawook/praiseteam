import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;

import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../teams/teams_providers.dart';

part 'announcements.g.dart';

class Announcement {
  const Announcement({
    required this.id,
    required this.kind,
    required this.title,
    required this.pinned,
    required this.updatedAt,
    this.body,
    this.sessionId,
  });

  factory Announcement.fromRow(Map<String, dynamic> r) => Announcement(
        id: r['id'] as int,
        kind: r['kind'] as String,
        title: r['title'] as String,
        body: r['body'] as String?,
        sessionId: r['session_id'] as int?,
        pinned: r['pinned'] as bool,
        updatedAt: DateTime.parse(r['updated_at'] as String),
      );

  final int id;
  final String kind; // general | setlist
  final String title;
  final String? body;
  final int? sessionId;
  final bool pinned;
  final DateTime updatedAt;
}

class AnnouncementsRepository {
  AnnouncementsRepository(this._db);
  final SupabaseClient _db;

  Future<List<Announcement>> list(int teamId) async {
    final rows = await _db
        .from('announcements')
        .select('id, kind, title, body, session_id, pinned, updated_at')
        .eq('team_id', teamId)
        .order('pinned', ascending: false)
        .order('updated_at', ascending: false)
        .limit(100);
    return rows.map(Announcement.fromRow).toList();
  }

  /// When I last opened the announcements of [teamId] (only I can read it).
  Future<DateTime?> seenAt(int teamId) async {
    final row = await _db.from('announcement_seen').select('seen_at').eq('team_id', teamId).maybeSingle();
    return row == null ? null : DateTime.parse(row['seen_at'] as String);
  }

  Future<void> markSeen(int teamId) => _db.rpc('mark_announcements_seen', params: {'p_team_id': teamId});

  Future<void> post(int teamId, {required String title, String? body, bool pinned = false}) =>
      _db.from('announcements').insert({
        'team_id': teamId,
        'kind': 'general',
        'title': title.trim(),
        'body': ?(body == null || body.trim().isEmpty ? null : body.trim()),
        'pinned': pinned,
      });

  Future<void> update(int id, {required String title, String? body, required bool pinned}) => _db
      .from('announcements')
      .update({'title': title.trim(), 'body': body == null || body.trim().isEmpty ? null : body.trim(), 'pinned': pinned})
      .eq('id', id);

  Future<void> delete(int id) => _db.from('announcements').delete().eq('id', id);
}

@Riverpod(keepAlive: true)
AnnouncementsRepository announcementsRepository(Ref ref) => AnnouncementsRepository(ref.watch(supabaseProvider));

@riverpod
Future<List<Announcement>> announcements(Ref ref, int teamId) =>
    ref.watch(announcementsRepositoryProvider).list(teamId);

/// Whether something was announced since I last looked. Personal only.
@riverpod
Future<bool> hasNewAnnouncements(Ref ref, int teamId) async {
  final (items, seen) = await (
    ref.watch(announcementsProvider(teamId).future),
    ref.watch(announcementsRepositoryProvider).seenAt(teamId),
  ).wait;
  return items.any((a) => seen == null || a.updatedAt.isAfter(seen));
}

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key, required this.teamId});
  final int teamId;

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(announcementsRepositoryProvider).markSeen(widget.teamId).catchError((_) {});
      ref.invalidate(hasNewAnnouncementsProvider(widget.teamId));
    });
  }

  Future<void> _edit({Announcement? existing}) async {
    final l10n = AppLocalizations.of(context);
    final title = TextEditingController(text: existing?.title);
    final body = TextEditingController(text: existing?.body);
    var pinned = existing?.pinned ?? false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? l10n.newAnnouncement : l10n.editAnnouncement),
          scrollable: true,
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, maxLength: 120, decoration: InputDecoration(labelText: l10n.announcementTitle, counterText: '')),
                const SizedBox(height: 12),
                TextField(controller: body, maxLines: 6, maxLength: 5000, decoration: InputDecoration(labelText: l10n.announcementBody, counterText: '')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.pinAnnouncement),
                  value: pinned,
                  onChanged: (v) => setState(() => pinned = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, title.text.trim().isNotEmpty), child: Text(l10n.save)),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final repo = ref.read(announcementsRepositoryProvider);
    final done = await runGuarded(
      context,
      () => existing == null
          ? repo.post(widget.teamId, title: title.text, body: body.text, pinned: pinned)
          : repo.update(existing.id, title: title.text, body: body.text, pinned: pinned),
    );
    if (done) ref.invalidate(announcementsProvider(widget.teamId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isLeader = ref.watch(activeMembershipProvider(widget.teamId))?.role.isLeader ?? false;
    final items = ref.watch(announcementsProvider(widget.teamId));
    final formats = DateFormats(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.announcements)),
      floatingActionButton: isLeader
          ? FloatingActionButton.extended(onPressed: _edit, icon: const Icon(Icons.campaign_outlined), label: Text(l10n.newAnnouncement))
          : null,
      body: AsyncBody(
        value: items,
        onRetry: () => ref.invalidate(announcementsProvider(widget.teamId)),
        data: (list) => list.isEmpty
            ? Center(child: Text(l10n.noAnnouncements))
            : ContentWidth(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(indent: 20),
                  itemBuilder: (context, i) {
                    final a = list[i];
                    return ListTile(
                      onTap: a.kind == 'setlist' && a.sessionId != null
                          ? () => context.push('/t/${widget.teamId}/sessions/${a.sessionId}')
                          : (isLeader ? () => _edit(existing: a) : null),
                      leading: a.pinned ? const Icon(Icons.push_pin, color: AppColors.teamInk) : null,
                      title: Text(a.kind == 'setlist' ? l10n.notifSetlistTitle(a.title) : a.title, style: theme.textTheme.titleMedium),
                      subtitle: Text([if (a.body != null) a.body!, formats.dayWithWeekday(a.updatedAt)].join('\n')),
                      isThreeLine: a.body != null,
                      trailing: isLeader && a.kind == 'general'
                          ? IconButton(
                              tooltip: l10n.deleteAnnouncement,
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final ok = await confirm(context, message: '${a.title}: ${l10n.deleteAnnouncement}?', confirmLabel: l10n.delete, destructive: true);
                                if (!ok || !context.mounted) return;
                                if (await runGuarded(context, () => ref.read(announcementsRepositoryProvider).delete(a.id))) {
                                  ref.invalidate(announcementsProvider(widget.teamId));
                                }
                              },
                            )
                          : null,
                    );
                  },
                ),
              ),
      ),
    );
  }
}
