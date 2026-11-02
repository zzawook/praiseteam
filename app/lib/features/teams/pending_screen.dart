import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../offline/offline_widgets.dart';
import '../settings/account_deletion.dart';
import 'models.dart';
import 'teams_providers.dart';

/// Waiting for a leader to approve the join request.
class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pending = (ref.watch(myMembershipsProvider).value ?? const [])
        .where((m) => m.status == MemberStatus.pending)
        .toList();

    return Scaffold(
      appBar: AppBar(
        actions: [TextButton(onPressed: () => signOutHere(context, ref), child: Text(l10n.signOut))],
      ),
      body: SafeArea(
        child: ContentWidth(
          maxWidth: 440,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.pendingTitle, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                for (final m in pending) ...[
                  Text(l10n.pendingBody(m.team.name), style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () async {
                        await runGuarded(context, () => ref.read(teamsRepositoryProvider).leave(m.teamId));
                        ref.invalidate(myMembershipsProvider);
                      },
                      child: Text(l10n.cancelRequest),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
                FilledButton(onPressed: () => ref.invalidate(myMembershipsProvider), child: Text(l10n.checkAgain)),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: () => context.go('/welcome'), child: Text(l10n.joinAnotherTeam)),
                const SizedBox(height: 24),
                const DeleteAccountTile(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
