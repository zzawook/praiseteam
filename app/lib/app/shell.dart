import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/avatars.dart';
import '../features/annotations/stroke_outbox.dart';
import '../features/announcements/announcements.dart';
import '../features/auth/auth.dart';
import '../features/chat/chat_providers.dart';
import '../features/offline/offline_widgets.dart';
import '../features/offline/prefetch.dart';
import '../features/settings/settings_providers.dart';
import '../features/teams/team_screen.dart' show roleLabel;
import '../features/teams/teams_providers.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

/// Breakpoints: phones get a bottom bar, tablets a rail of icons, laptops a
/// sidebar.
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
  _Destination('chat', Icons.forum_outlined, Icons.forum, (l) => l.navChat),
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

  void _go(BuildContext context, int index) => context.go('/t/$teamId/${_destinations[index].path}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final unreadChat = ref.watch(unreadChatCountProvider(teamId));
    final newAnnouncements = ref.watch(hasNewAnnouncementsProvider(teamId)).value ?? false;
    // Keep upcoming services on the device, and send notes drawn offline.
    ref
      ..listen(offlinePrefetchProvider, (_, _) {})
      ..listen(strokeOutboxProvider, (_, _) {});

    Widget icon(_Destination d, {required bool selected}) {
      final base = Icon(selected ? d.selectedIcon : d.icon);
      if (d.path != 'chat') return base;
      if (unreadChat > 0) return Badge.count(count: unreadChat, child: base);
      if (newAnnouncements) return Badge(child: base);
      return base;
    }

    if (width < Breakpoints.rail) {
      return Scaffold(
        body: child,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OfflineBanner(),
            NavigationBar(
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
          ],
        ),
      );
    }

    final content = Expanded(
      child: Column(
        children: [
          Expanded(child: child),
          const OfflineBanner(),
        ],
      ),
    );

    if (width >= Breakpoints.extendedRail) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              teamId: teamId,
              section: _destinations[_index].path,
              onSelect: (path) => context.go('/t/$teamId/$path'),
              unreadChat: unreadChat,
              newAnnouncements: newAnnouncements,
            ),
            content,
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => _go(context, i),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TeamSwitcher(teamId: teamId, compact: true),
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
          content,
        ],
      ),
    );
  }
}

/// Laptop navigation in the manner of chat apps: the team on top, one
/// full-width row per section (the current one filled), and the signed-in
/// person at the bottom, which opens settings.
class _Sidebar extends ConsumerWidget {
  const _Sidebar({
    required this.teamId,
    required this.section,
    required this.onSelect,
    required this.unreadChat,
    required this.newAnnouncements,
  });
  final int teamId;
  final String section;
  final ValueChanged<String> onSelect;
  final int unreadChat;
  final bool newAnnouncements;

  static const width = 264.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: TeamSwitcher(teamId: teamId, wide: true),
            ),
            for (final d in _destinations)
              if (d.path != 'settings')
                _SidebarItem(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: d.label(l10n),
                  selected: d.path == section,
                  count: d.path == 'chat' ? unreadChat : 0,
                  dot: d.path == 'chat' && unreadChat == 0 && newAnnouncements,
                  onTap: () => onSelect(d.path),
                ),
            const Spacer(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: _ProfileCard(teamId: teamId, selected: section == 'settings', onTap: () => onSelect('settings')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.count,
    required this.dot,
    required this.onTap,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final int count;
  final bool dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(
                    selected ? selectedIcon : icon,
                    size: 22,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (count > 0) Badge.count(count: count) else if (dot) const Badge(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Who is signed in, with their role here; opens settings.
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.teamId, required this.selected, required this.onTap});
  final int teamId;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final me = ref.watch(currentUserIdProvider) ?? '';
    final name = ref.watch(myProfileProvider).value?.displayName ?? '';
    final role = ref.watch(activeMembershipProvider(teamId))?.role;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                PersonAvatar(name: name, id: me, radius: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (role != null)
                        Text(
                          roleLabel(l10n, role),
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.settings : Icons.settings_outlined,
                  size: 20,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  semanticLabel: l10n.navSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the current team; opens a menu to switch or add a team.
class TeamSwitcher extends ConsumerWidget {
  const TeamSwitcher({super.key, required this.teamId, this.compact = false, this.wide = false});
  final int teamId;

  /// Just the team's initial (the narrow rail).
  final bool compact;

  /// A full-width row with the team's mark (the laptop sidebar).
  final bool wide;

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
      child: wide
          ? Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppPalette.of(context).hero,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      name.isEmpty ? '?' : name.characters.first,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppPalette.of(context).onHero,
                        fontFamily: AppType.setlistFamily,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: AppType.setlistFamily,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.unfold_more, size: 20, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            )
          : compact
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
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: AppType.setlistFamily,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.unfold_more, size: 18),
                ],
              ),
            ),
    );
  }
}
