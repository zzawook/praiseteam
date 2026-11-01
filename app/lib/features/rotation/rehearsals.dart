import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;

import '../../core/dates.dart';
import '../../core/offline/offline_store.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth.dart';
import '../offline/offline.dart';
import 'rotation_providers.dart';
import 'rotation_repository.dart';
import 'rotation_screen.dart' show statusLook;

part 'rehearsals.g.dart';

enum Rsvp {
  going,
  late,
  notGoing;

  /// Database value (public.rehearsal_responses.rsvp).
  String get db => this == notGoing ? 'not_going' : name;
  static Rsvp fromDb(String value) => value == 'not_going' ? notGoing : Rsvp.values.byName(value);
}

enum Attendance { present, late, absent }

class Rehearsal {
  const Rehearsal({required this.id, required this.startsAt, this.location, this.responses = const {}});
  final int id;
  final DateTime startsAt;
  final String? location;

  /// user id -> (rsvp, attendance); members only get their own row (RLS).
  final Map<String, ({Rsvp? rsvp, Attendance? attendance})> responses;
}

class RehearsalsRepository {
  RehearsalsRepository(this._db, this._offline);
  final SupabaseClient _db;
  final ReadThrough _offline;

  /// Kept on the device with the rest of the session (readable offline).
  Future<List<Rehearsal>> forSession(int sessionId) async {
    final rows = await _offline.list(
      'rehearsals:$sessionId',
      () => _db
          .from('rehearsals')
          .select('id, starts_at, location, rehearsal_responses(user_id, rsvp, attendance)')
          .eq('session_id', sessionId)
          .order('starts_at', ascending: true),
    );
    return [
      for (final r in rows)
        Rehearsal(
          id: r['id'] as int,
          startsAt: DateTime.parse(r['starts_at'] as String),
          location: r['location'] as String?,
          responses: {
            for (final x in (r['rehearsal_responses'] as List).cast<Map<String, dynamic>>())
              x['user_id'] as String: (
                rsvp: x['rsvp'] == null ? null : Rsvp.fromDb(x['rsvp'] as String),
                attendance: x['attendance'] == null ? null : Attendance.values.byName(x['attendance'] as String),
              ),
          },
        ),
    ];
  }

  Future<void> add(int teamId, int sessionId, DateTime startsAt, String? location) => _db.from('rehearsals').insert({
        'team_id': teamId,
        'session_id': sessionId,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'location': ?(location == null || location.trim().isEmpty ? null : location.trim()),
      });

  Future<void> rsvp(int rehearsalId, Rsvp value) =>
      _db.rpc('set_rsvp', params: {'p_rehearsal_id': rehearsalId, 'p_rsvp': value.db});

  Future<void> attendance(int rehearsalId, String userId, Attendance? value) => _db.rpc(
        'record_attendance',
        params: {'p_rehearsal_id': rehearsalId, 'p_user_id': userId, 'p_attendance': value?.name},
      );
}

@Riverpod(keepAlive: true)
RehearsalsRepository rehearsalsRepository(Ref ref) =>
    RehearsalsRepository(ref.watch(supabaseProvider), ref.watch(readThroughProvider));

@riverpod
Future<List<Rehearsal>> sessionRehearsals(Ref ref, int sessionId) {
  ref.watch(onlineStatusProvider.select((s) => s.epoch)); // refresh on reconnect
  return ref.watch(rehearsalsRepositoryProvider).forSession(sessionId);
}

/// Who serves in a session and the session's rehearsals, for its page.
class SessionServingSection extends ConsumerWidget {
  const SessionServingSection({
    super.key,
    required this.teamId,
    required this.sessionId,
    required this.sessionStart,
    required this.isLeader,
    required this.partNames,
  });
  final int teamId;
  final int sessionId;
  final DateTime sessionStart;
  final bool isLeader;
  final Map<int, String> partNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final me = ref.watch(currentUserIdProvider);
    final board = ref.watch(rotationBoardProvider(teamId)).value;
    final serving = [
      for (final a in board?.assignments ?? const <Assignment>[])
        if (a.sessionId == sessionId && a.status != AssignmentStatus.declined && (isLeader || a.status != AssignmentStatus.draft)) a,
    ];
    final rehearsals = ref.watch(sessionRehearsalsProvider(sessionId));
    final formats = DateFormats(context);
    final repo = ref.read(rehearsalsRepositoryProvider);
    void refresh() => ref.invalidate(sessionRehearsalsProvider(sessionId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (serving.isNotEmpty) ...[
          SectionHeader(l10n.servingPeople),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in serving)
                  Builder(
                    builder: (context) {
                      final (color, icon) = statusLook(context, a.status);
                      return Chip(
                        avatar: Icon(icon, size: 16, color: color),
                        label: Text('${partNames[a.partId] ?? ''} ${a.userName}'),
                        backgroundColor: a.status == AssignmentStatus.accepted ? color.withValues(alpha: 0.14) : null,
                        side: BorderSide(color: color.withValues(alpha: a.status == AssignmentStatus.accepted ? 0.0 : 0.6)),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
        SectionHeader(
          l10n.rehearsals,
          trailing: isLeader
              ? TextButton.icon(
                  onPressed: () => _add(context, ref),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addRehearsal),
                )
              : null,
        ),
        AsyncBody(
          value: rehearsals,
          onRetry: refresh,
          data: (items) => Column(
            children: [
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(alignment: Alignment.centerLeft, child: Text(l10n.noRehearsals, style: theme.textTheme.bodySmall)),
                ),
              for (final r in items)
                ListTile(
                  title: Text('${formats.dayWithWeekday(r.startsAt)}  ${formats.time(r.startsAt)}'),
                  subtitle: r.location == null ? null : Text(r.location!),
                  onTap: isLeader ? () => _attendance(context, ref, r, serving) : null,
                  trailing: SegmentedButton<Rsvp>(
                    showSelectedIcon: false,
                    emptySelectionAllowed: true,
                    segments: [
                      ButtonSegment(value: Rsvp.going, label: Text(l10n.rsvpGoing)),
                      ButtonSegment(value: Rsvp.late, label: Text(l10n.rsvpLate)),
                      ButtonSegment(value: Rsvp.notGoing, label: Text(l10n.rsvpNotGoing)),
                    ],
                    selected: {?r.responses[me]?.rsvp},
                    onSelectionChanged: (s) async {
                      if (s.isEmpty) return;
                      if (await runGuarded(context, () => repo.rsvp(r.id, s.first))) refresh();
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final before = sessionStart.toLocal().subtract(const Duration(days: 1));
    final date = await showDatePicker(context: context, initialDate: before, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 19, minute: 30));
    if (time == null || !context.mounted) return;
    final place = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(controller: place, decoration: InputDecoration(labelText: l10n.location)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (await runGuarded(context, () => ref.read(rehearsalsRepositoryProvider).add(teamId, sessionId, start, place.text))) {
      ref.invalidate(sessionRehearsalsProvider(sessionId));
    }
  }

  /// Leaders record who came. Attendance stays with the leaders.
  Future<void> _attendance(BuildContext context, WidgetRef ref, Rehearsal r, List<Assignment> serving) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => Consumer(
          builder: (context, ref, _) {
            final l10n = AppLocalizations.of(context);
            final latest = ref.watch(sessionRehearsalsProvider(sessionId)).value?.firstWhere((x) => x.id == r.id, orElse: () => r) ?? r;
            final people = {for (final a in serving) a.userId: a.userName};
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(title: Text(l10n.attendanceCheck, style: Theme.of(context).textTheme.titleLarge)),
                  for (final MapEntry(key: userId, value: name) in people.entries)
                    ListTile(
                      title: Text(name),
                      subtitle: Text(switch (latest.responses[userId]?.rsvp) {
                        Rsvp.going => l10n.rsvpGoing,
                        Rsvp.late => l10n.rsvpLate,
                        Rsvp.notGoing => l10n.rsvpNotGoing,
                        null => '',
                      }),
                      trailing: SegmentedButton<Attendance>(
                        showSelectedIcon: false,
                        emptySelectionAllowed: true,
                        segments: [
                          ButtonSegment(value: Attendance.present, label: Text(l10n.present)),
                          ButtonSegment(value: Attendance.late, label: Text(l10n.rsvpLate)),
                          ButtonSegment(value: Attendance.absent, label: Text(l10n.absent)),
                        ],
                        selected: {?latest.responses[userId]?.attendance},
                        onSelectionChanged: (s) async {
                          final value = s.isEmpty ? null : s.first;
                          if (await runGuarded(context, () => ref.read(rehearsalsRepositoryProvider).attendance(r.id, userId, value))) {
                            ref.invalidate(sessionRehearsalsProvider(sessionId));
                          }
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
}
