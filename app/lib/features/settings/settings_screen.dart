import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/env.dart';
import '../../core/errors.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers.dart';
import '../auth/auth.dart';
import '../notifications/notification_prefs.dart';
import '../notifications/push.dart';
import '../offline/offline_widgets.dart';
import '../teams/teams_providers.dart';
import 'settings_providers.dart';
import 'account_deletion.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.teamId});
  final int teamId;

  Future<String?> _askText(BuildContext context, {required String label, required String initial, int maxLength = 40}) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: maxLength,
          decoration: InputDecoration(labelText: label),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l10n.save)),
        ],
      ),
    );
  }

  Future<void> _calendar(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final db = ref.read(supabaseProvider);
    String? token;
    final ok = await runGuarded(context, () async {
      final row = await db.from('calendar_feeds').select('token').maybeSingle();
      token = row?['token'] as String? ?? await db.rpc('rotate_calendar_token') as String;
    });
    if (!ok || token == null || !context.mounted) return;
    String urlFor(String t) => '${Env.supabaseUrl}/functions/v1/calendar/$t.ics';
    var url = urlFor(token!);
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.calendarSubscribe),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(url, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Text(l10n.googleCalendarHint, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final ok = await confirm(context, message: l10n.newCalendarUrlHint, confirmLabel: l10n.newCalendarUrl);
                if (!ok) return;
                final fresh = await db.rpc('rotate_calendar_token') as String;
                setState(() => url = urlFor(fresh));
              },
              child: Text(l10n.newCalendarUrl),
            ),
            TextButton(
              onPressed: () => launchUrl(Uri.parse(url.replaceFirst(RegExp('^https?'), 'webcal'))),
              child: Text(l10n.openInCalendar),
            ),
            FilledButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: url));
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(l10n.copy),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(myProfileProvider).value;
    final membership = ref.watch(activeMembershipProvider(teamId));
    final chosenLocale = ref.watch(appLocaleProvider);
    final userId = ref.watch(currentUserIdProvider);
    final teams = ref.read(teamsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            SectionHeader(l10n.profile),
            ListTile(
              title: Text(l10n.displayName),
              subtitle: Text(profile?.displayName ?? ''),
              trailing: const Icon(Icons.edit_outlined),
              onTap: userId == null
                  ? null
                  : () async {
                      final name = await _askText(
                        context,
                        label: l10n.displayName,
                        initial: profile?.displayName ?? '',
                      );
                      if (name == null || name.trim().isEmpty || !context.mounted) return;
                      if (await runGuarded(
                        context,
                        () => ref.read(profileRepositoryProvider).update(userId, displayName: name),
                      )) {
                        ref
                          ..invalidate(myProfileProvider)
                          ..invalidate(teamMembersProvider(teamId));
                      }
                    },
            ),
            const Divider(indent: 20),
            ListTile(
              title: Text(l10n.language),
              trailing: DropdownButton<String>(
                value: chosenLocale?.languageCode ?? 'system',
                underline: const SizedBox.shrink(),
                onChanged: (code) =>
                    ref.read(appLocaleProvider.notifier).choose(code == null || code == 'system' ? null : Locale(code)),
                items: [
                  DropdownMenuItem(value: 'system', child: Text(l10n.languageSystem)),
                  const DropdownMenuItem(value: 'ko', child: Text('한국어')),
                  const DropdownMenuItem(value: 'en', child: Text('English')),
                ],
              ),
            ),
            const Divider(indent: 20),
            if (!Env.demo)
              ListTile(
                title: Text(l10n.calendarSubscribe),
                subtitle: Text(l10n.calendarHint),
                trailing: const Icon(Icons.event_available_outlined),
                onTap: () => _calendar(context, ref),
              ),
            const _NotificationSettings(),
            if (membership != null)
              ListTile(leading: const Icon(Icons.public), title: Text(l10n.inTeamTimezone(membership.team.timezone))),
            if (membership != null && membership.role.isLeader) ...[
              SectionHeader(l10n.teamSettings),
              ListTile(
                title: Text(l10n.teamName),
                subtitle: Text(membership.team.name),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () async {
                  final name = await _askText(
                    context,
                    label: l10n.teamName,
                    initial: membership.team.name,
                    maxLength: 60,
                  );
                  if (name == null || name.trim().isEmpty || !context.mounted) return;
                  if (await runGuarded(context, () => teams.updateTeam(teamId, name: name.trim()))) {
                    ref.invalidate(myMembershipsProvider);
                  }
                },
              ),
              const Divider(indent: 20),
              SwitchListTile(
                title: Text(l10n.requireApproval),
                value: membership.team.joinRequiresApproval,
                onChanged: (on) async {
                  if (await runGuarded(context, () => teams.updateTeam(teamId, joinRequiresApproval: on))) {
                    ref.invalidate(myMembershipsProvider);
                  }
                },
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            if (membership != null)
              ListTile(
                title: Text(l10n.leaveTeam),
                onTap: () async {
                  final ok = await confirm(
                    context,
                    message: l10n.leaveTeamConfirm(membership.team.name),
                    confirmLabel: l10n.leaveTeam,
                    destructive: true,
                  );
                  if (!ok || !context.mounted) return;
                  if (await runGuarded(context, () => teams.leave(teamId))) {
                    ref.invalidate(myMembershipsProvider);
                    if (context.mounted) context.go('/');
                  }
                },
              ),
            ListTile(
              title: Text(l10n.privacyPolicy),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => launchUrl(Env.privacyPolicy),
            ),
            const Divider(indent: 20),
            if (!Env.demo) ListTile(title: Text(l10n.signOut), onTap: () => signOutHere(context, ref)),
            const DeleteAccountTile(),
          ],
        ),
      ),
    );
  }
}

class _NotificationSettings extends ConsumerWidget {
  const _NotificationSettings();

  static String _label(AppLocalizations l10n, PushGroup group) => switch (group) {
    PushGroup.setlists => l10n.pushSetlists,
    PushGroup.serving => l10n.pushServing,
    PushGroup.rehearsals => l10n.pushRehearsals,
    PushGroup.announcements => l10n.pushAnnouncements,
    PushGroup.chat => l10n.pushChat,
    PushGroup.joining => l10n.pushJoining,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(myNotificationPrefsProvider);
    final notifier = ref.read(myNotificationPrefsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.notificationsSection),
        AsyncBody(
          value: prefs,
          onRetry: () => ref.invalidate(myNotificationPrefsProvider),
          data: (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DevicePush(),
              SwitchListTile(
                title: Text(l10n.allSetlists),
                subtitle: Text(l10n.allSetlistsHint),
                value: p.allSetlists,
                onChanged: (on) => runGuarded(context, () => notifier.setAllSetlists(on)),
              ),
              SectionHeader(l10n.pushSection),
              for (final group in PushGroup.values)
                SwitchListTile(
                  title: Text(_label(l10n, group)),
                  value: p.push(group),
                  onChanged: (on) => runGuarded(context, () => notifier.setPush(group, on)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(l10n.pushOffHint, style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Whether this phone or browser gets pushes for the signed-in user.
class _DevicePush extends ConsumerWidget {
  const _DevicePush();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(pushRegistrationProvider);
    final push = ref.read(pushRegistrationProvider.notifier);
    if (state case AsyncError(:final error) when !state.isLoading) {
      // Registering failed: off, with the reason, and the switch tries again.
      return SwitchListTile(
        title: Text(l10n.pushThisDevice),
        subtitle: Text(AppError.from(error).message(l10n)),
        value: false,
        onChanged: (_) => runGuarded(context, push.enable),
      );
    }
    return switch (state.value) {
      null || PushState.unsupported => const SizedBox.shrink(),
      PushState.blocked => SwitchListTile(
        title: Text(l10n.pushThisDevice),
        subtitle: Text(l10n.pushBlocked),
        value: false,
        onChanged: null,
      ),
      final s => SwitchListTile(
        title: Text(l10n.pushThisDevice),
        value: s == PushState.on,
        onChanged: state.isLoading ? null : (on) => runGuarded(context, () => on ? push.enable() : push.disable()),
      ),
    };
  }
}
