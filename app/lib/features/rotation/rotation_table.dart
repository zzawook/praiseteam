import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth.dart';
import '../sessions/models.dart';
import '../teams/models.dart';
import 'rotation_repository.dart';
import 'rotation_screen.dart' show showServingSheet, statusLook;

/// The rotation as one table, the way teams keep it in a spreadsheet:
/// services across, parts down, who serves in each cell. Part names stay
/// in place while the services scroll sideways. A cell opens that part of
/// the service, to fill it or to answer.
class RotationTable extends ConsumerWidget {
  const RotationTable({
    super.key,
    required this.teamId,
    required this.board,
    required this.parts,
    required this.isLeader,
  });
  final int teamId;
  final RotationBoard board;
  final List<Part> parts;
  final bool isLeader;

  static const _headerHeight = 76.0;
  static const _lineHeight = 28.0;
  static const _padding = 12.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) =>
        _table(context, ref, constraints.maxWidth),
  );

  Widget _table(BuildContext context, WidgetRef ref, double width) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final formats = DateFormats(context);
    final me = ref.watch(currentUserIdProvider);
    final sessions = board.sessions;
    final labelWidth = width < 600 ? 100.0 : 132.0;
    // Fill the available space on a wide screen; on phones retain readable
    // columns and scroll only the services, keeping the part names in place.
    final columnWidth = math.max(
      width < 600 ? 160.0 : 184.0,
      (width - labelWidth) / math.max(1, sessions.length),
    );
    final rule = BorderSide(
      color: theme.colorScheme.outlineVariant,
      width: 0.5,
    );
    final groupRule = BorderSide(color: theme.colorScheme.outline, width: 1);
    final muted = theme.colorScheme.onSurfaceVariant;

    int needed(Session s, Part p) => board.slots[(s.id, p.id)] ?? 0;
    int open(Session s, Part p) => math.max(
      0,
      needed(s, p) -
          board
              .of(s.id, p.id)
              .where((a) => a.status != AssignmentStatus.declined)
              .length,
    );
    // Parts some service on the board needs or has someone in, in team order.
    final shown = [
      for (final p in parts)
        if (sessions.any(
          (s) => needed(s, p) > 0 || board.of(s.id, p.id).isNotEmpty,
        ))
          p,
    ];
    if (shown.isEmpty) return const SizedBox.shrink();

    // Each row is as tall as its fullest cell, so both sides line up.
    double heightOf(Part p) =>
        2 * _padding +
        groupRule.width +
        rule.width +
        _lineHeight *
            [
              1,
              for (final s in sessions)
                board.of(s.id, p.id).length + (open(s, p) > 0 ? 1 : 0),
            ].reduce(math.max);
    // A thicker line where the next kind of part starts (singers, band, tech).
    bool startsGroup(int i) => i > 0 && shown[i].kind != shown[i - 1].kind;

    Widget name(Assignment a) {
      final (color, _) = statusLook(context, a.status);
      final draft = a.status == AssignmentStatus.draft;
      return Row(
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              a.userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: draft ? muted : null,
                fontWeight: a.userId == me ? FontWeight.w800 : null,
                decoration: a.status == AssignmentStatus.declined
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
        ],
      );
    }

    final labels = Column(
      children: [
        Container(
          height: _headerHeight,
          width: labelWidth,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(bottom: groupRule, right: groupRule),
          ),
        ),
        for (final (i, p) in shown.indexed)
          Container(
            height: heightOf(p),
            width: labelWidth,
            padding: const EdgeInsets.fromLTRB(16, _padding, 8, _padding),
            alignment: Alignment.topLeft,
            decoration: BoxDecoration(
              border: Border(
                top: startsGroup(i) ? groupRule : BorderSide.none,
                bottom: rule,
                right: groupRule,
              ),
            ),
            child: SizedBox(
              height: _lineHeight,
              child: Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge,
              ),
            ),
          ),
      ],
    );

    final grid = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final s in sessions)
              InkWell(
                onTap: () => context.push('/t/$teamId/sessions/${s.id}'),
                child: Container(
                  width: columnWidth,
                  height: _headerHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    border: Border(bottom: groupRule, right: rule),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formats.dayWithWeekday(s.startsAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        s.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        for (final (i, p) in shown.indexed)
          Row(
            children: [
              for (final s in sessions)
                InkWell(
                  onTap: () => showServingSheet(
                    context,
                    teamId: teamId,
                    session: s,
                    part: p,
                    isLeader: isLeader,
                  ),
                  child: Container(
                    width: columnWidth,
                    height: heightOf(p),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: _padding,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: startsGroup(i) ? groupRule : BorderSide.none,
                        bottom: rule,
                        right: rule,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final a in board.of(s.id, p.id))
                          SizedBox(height: _lineHeight, child: name(a)),
                        if (open(s, p) case final n when n > 0)
                          SizedBox(
                            height: _lineHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                l10n.openPlaces(n),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: muted,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        labels,
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: grid,
          ),
        ),
      ],
    );
  }
}
