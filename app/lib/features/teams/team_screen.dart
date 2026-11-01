import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shell.dart';
import '../../core/widgets.dart';
import '../../core/avatars.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth.dart';
import 'models.dart';
import 'parts.dart';
import 'teams_providers.dart';

String roleLabel(AppLocalizations l10n, TeamRole role) => switch (role) {
      TeamRole.owner => l10n.roleOwner,
      TeamRole.leader => l10n.roleLeader,
      TeamRole.member => l10n.roleMember,
    };

/// Roster, join requests and the invite code.
class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key, required this.teamId});
  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentUserIdProvider);
    final membership = ref.watch(activeMembershipProvider(teamId));
    final members = ref.watch(teamMembersProvider(teamId));
    final parts = ref.watch(teamPartsProvider(teamId)).value ?? const <Part>[];
    final isLeader = membership?.role.isLeader ?? false;
    final narrow = MediaQuery.sizeOf(context).width < Breakpoints.rail;

    Future<void> refresh() async {
      ref
        ..invalidate(teamMembersProvider(teamId))
        ..invalidate(teamPartsProvider(teamId));
      await ref.read(teamMembersProvider(teamId).future);
    }

    return Scaffold(
      appBar: AppBar(
        // Wide layouts already show the team in the side rail.
        title: narrow ? TeamSwitcher(teamId: teamId) : Text(l10n.navTeam),
        actions: [
          if (isLeader)
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => PartsScreen(teamId: teamId)),
              ),
              child: Text(l10n.manageParts),
            ),
        ],
      ),
      body: AsyncBody(
        value: members,
        onRetry: refresh,
        data: (members) {
          final pending = members.where((m) => m.status == MemberStatus.pending).toList();
          final active = members.where((m) => m.status == MemberStatus.active).toList();
          final mine = active.where((m) => m.userId == me).firstOrNull;
          // In the team's part order, whatever order the rows came back in.
          List<String> partNamesOf(Member m) => [for (final p in parts) if (m.partIds.contains(p.id)) p.name];

          return RefreshIndicator(
            onRefresh: refresh,
            child: ContentWidth(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  if (mine != null && mine.partIds.isEmpty)
                    _MyPartsPrompt(
                      onTap: () => showPartsPicker(context, teamId: teamId, userId: mine.userId, selected: const []),
                    ),
                  if (isLeader && membership != null) _InviteCode(teamId: teamId, code: membership.team.inviteCode),
                  if (isLeader && pending.isNotEmpty) ...[
                    SectionHeader(l10n.joinRequests),
                    for (final m in pending) _PendingRow(teamId: teamId, member: m),
                  ],
                  SectionHeader(l10n.membersCount(active.length)),
                  for (final m in active) ...[
                    _MemberRow(
                      member: m,
                      isMe: m.userId == me,
                      partNames: partNamesOf(m),
                      onTap: () => _openMember(context, ref, m, membership),
                    ),
                    const Divider(indent: 72),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openMember(BuildContext context, WidgetRef ref, Member member, Membership? mine) {
    if (mine == null) return;
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(teamsRepositoryProvider);
    final isMe = member.userId == ref.read(currentUserIdProvider);
    final canEditParts = isMe || mine.role.isLeader;
    final canChangeRole = mine.role == TeamRole.owner;
    final canRemove = !isMe && mine.role.isLeader && (member.role != TeamRole.owner || mine.role == TeamRole.owner);
    if (!canEditParts && !canChangeRole && !canRemove) return;

    void refresh() {
      ref
        ..invalidate(teamMembersProvider(teamId))
        ..invalidate(myMembershipsProvider);
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(member.profile.displayName, style: Theme.of(sheet).textTheme.titleLarge)),
            if (canEditParts)
              ListTile(
                leading: const Icon(Icons.piano_outlined),
                title: Text(l10n.editParts),
                onTap: () {
                  Navigator.pop(sheet);
                  showPartsPicker(
                    context,
                    teamId: teamId,
                    userId: member.userId,
                    selected: member.partIds,
                    title: isMe ? null : member.profile.displayName,
                  );
                },
              ),
            if (canChangeRole)
              RadioGroup<TeamRole>(
                groupValue: member.role,
                onChanged: (role) async {
                  Navigator.pop(sheet);
                  if (role == null || role == member.role) return;
                  if (await runGuarded(context, () => repo.setRole(teamId, member.userId, role))) refresh();
                },
                child: Column(
                  children: [
                    for (final role in TeamRole.values)
                      RadioListTile<TeamRole>(value: role, title: Text(roleLabel(l10n, role))),
                  ],
                ),
              ),
            if (canRemove)
              ListTile(
                leading: Icon(Icons.person_remove_outlined, color: Theme.of(sheet).colorScheme.error),
                title: Text(l10n.removeFromTeam, style: TextStyle(color: Theme.of(sheet).colorScheme.error)),
                onTap: () async {
                  Navigator.pop(sheet);
                  final ok = await confirm(
                    context,
                    message: l10n.removeConfirm(member.profile.displayName),
                    confirmLabel: l10n.removeFromTeam,
                    destructive: true,
                  );
                  if (ok && context.mounted && await runGuarded(context, () => repo.remove(teamId, member.userId))) {
                    refresh();
                  }
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MyPartsPrompt extends StatelessWidget {
  const _MyPartsPrompt({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Expanded(child: Text(l10n.partsPickerHint, style: theme.textTheme.bodyMedium)),
              const SizedBox(width: 12),
              FilledButton(onPressed: onTap, child: Text(l10n.editParts)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteCode extends ConsumerWidget {
  const _InviteCode({required this.teamId, required this.code});
  final int teamId;
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.inviteTitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              SelectableText(
                code,
                style: theme.textTheme.headlineSmall?.copyWith(
                  letterSpacing: 6,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: l10n.copy,
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (context.mounted) showMessage(context, l10n.copied);
                },
              ),
              IconButton(
                tooltip: l10n.newInviteCode,
                icon: const Icon(Icons.autorenew),
                onPressed: () async {
                  final ok = await confirm(context, message: l10n.newInviteCodeConfirm, confirmLabel: l10n.newInviteCode);
                  if (!ok || !context.mounted) return;
                  if (await runGuarded(context, () => ref.read(teamsRepositoryProvider).rotateInviteCode(teamId))) {
                    ref.invalidate(myMembershipsProvider);
                  }
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text(l10n.inviteHint, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _PendingRow extends ConsumerWidget {
  const _PendingRow({required this.teamId, required this.member});
  final int teamId;
  final Member member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(teamsRepositoryProvider);
    void refresh() => ref.invalidate(teamMembersProvider(teamId));
    return ListTile(
      leading: PersonAvatar(name: member.profile.displayName, id: member.userId),
      title: Text(member.profile.displayName),
      trailing: Wrap(
        spacing: 8,
        children: [
          TextButton(
            onPressed: () async {
              if (await runGuarded(context, () => repo.reject(teamId, member.userId))) refresh();
            },
            child: Text(l10n.reject),
          ),
          FilledButton(
            onPressed: () async {
              if (await runGuarded(context, () => repo.approve(teamId, member.userId))) refresh();
            },
            child: Text(l10n.approve),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.isMe, required this.partNames, required this.onTap});
  final Member member;
  final bool isMe;
  final List<String> partNames;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = isMe ? '${member.profile.displayName} (${l10n.you})' : member.profile.displayName;
    return ListTile(
      onTap: onTap,
      leading: PersonAvatar(name: member.profile.displayName, id: member.userId),
      title: Text(name),
      subtitle: Text(
        partNames.isEmpty ? l10n.noPartsYet : partNames.join(', '),
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: member.role == TeamRole.member
          ? null
          : Text(roleLabel(l10n, member.role), style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary)),
    );
  }
}
