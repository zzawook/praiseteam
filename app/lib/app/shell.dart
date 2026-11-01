import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/teams/teams_providers.dart';
import '../l10n/app_localizations.dart';

/// Breakpoints: phones get a bottom bar; tablets and laptops a side rail.
abstract final class Breakpoints {
  static const rail = 600.0;
  static const extendedRail = 1000.0;
}

class _Destination {
  const _Destination(this.path, this.icon, this.selectedIcon, this.label);
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations) label;
}

final _destinations = [
  _Destination('sessions', Icons.event_note_outlined, Icons.event_note, (l) => l.navSessions),
  _Destination('songs', Icons.library_music_outlined, Icons.library_music, (l) => l.navSongs),
  _Destination('team', Icons.groups_outlined, Icons.groups, (l) => l.navTeam),
  _Destination('settings', Icons.settings_outlined, Icons.settings, (l) => l.navSettings),
];

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.teamId, required this.location, required this.child});
  final int teamId;
  final String location;
  final Widget child;

  /// /t/{teamId}/{section}/... -> index of {section}
  int get _index {
    final segments = location.split('/');
    final section = segments.length > 3 ? segments[3] : '';
    final i = _destinations.indexWhere((d) => d.path == section);
    return i < 0 ? 0 : i;
  }

  void _go(BuildContext context, int index) =>
      context.go('/t/$teamId/${_destinations[index].path}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    Widget icon(_Destination d, {required bool selected}) => Icon(selected ? d.selectedIcon : d.icon);

    if (width < Breakpoints.rail) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => _go(context, i),
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: icon(d, selected: false),
                selectedIcon: icon(d, selected: true),
                label: d.label(l10n),
              ),
          ],
        ),
      );
    }

    final extended = width >= Breakpoints.extendedRail;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            selectedIndex: _index,
            onDestinationSelected: (i) => _go(context, i),
            labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TeamSwitcher(teamId: teamId, compact: !extended),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: icon(d, selected: false),
                  selectedIcon: icon(d, selected: true),
                  label: Text(d.label(l10n)),
                ),
            ],
          ),
          const VerticalDivider(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Shows the current team; opens a menu to switch or add a team.
class TeamSwitcher extends ConsumerWidget {
  const TeamSwitcher({super.key, required this.teamId, this.compact = false});
  final int teamId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final memberships = ref.watch(myMembershipsProvider).value ?? const [];
    final active = memberships.where((m) => m.isActive).toList();
    final current = active.where((m) => m.teamId == teamId).firstOrNull;
    final name = current?.team.name ?? '';

    return PopupMenuButton<int>(
      tooltip: l10n.switchTeam,
      onSelected: (id) => id < 0 ? context.go('/welcome') : context.go('/t/$id/sessions'),
      itemBuilder: (_) => [
        for (final m in active)
          CheckedPopupMenuItem(value: m.teamId, checked: m.teamId == teamId, child: Text(m.team.name)),
        const PopupMenuDivider(),
        PopupMenuItem(value: -1, child: Text(l10n.addTeam)),
      ],
      child: compact
          ? CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: Text(name.isEmpty ? '?' : name.characters.first),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.unfold_more, size: 18),
                ],
              ),
            ),
    );
  }
}
