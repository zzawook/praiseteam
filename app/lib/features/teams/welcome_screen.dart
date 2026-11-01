import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'teams_providers.dart';

/// Join with an invite code (the common case) or create a new team.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit(Future<int> Function() action) async {
    setState(() => _busy = true);
    var teamId = -1;
    final ok = await runGuarded(context, () async => teamId = await action());
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    ref.invalidate(myMembershipsProvider);
    await ref.read(myMembershipsProvider.future);
    if (mounted) context.go('/t/$teamId/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repo = ref.read(teamsRepositoryProvider);
    final hasTeams = (ref.watch(myMembershipsProvider).value ?? const []).isNotEmpty;

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: hasTeams),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: ContentWidth(
            maxWidth: 440,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.welcomeTitle, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(l10n.welcomeBody, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 32),
                Text(l10n.joinWithCode, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 8,
                  style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 4),
                  decoration: InputDecoration(labelText: l10n.inviteCode, hintText: l10n.inviteCodeHint, counterText: ''),
                  onSubmitted: (_) => _submit(() => repo.joinTeam(_code.text)),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : () => _submit(() => repo.joinTeam(_code.text)),
                  child: Text(l10n.join),
                ),
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 24),
                Text(l10n.createTeam, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  maxLength: 60,
                  decoration: InputDecoration(labelText: l10n.teamName, hintText: l10n.teamNameHint, counterText: ''),
                  onSubmitted: (_) => _submit(() => repo.createTeam(_name.text)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy ? null : () => _submit(() => repo.createTeam(_name.text)),
                  child: Text(l10n.create),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
