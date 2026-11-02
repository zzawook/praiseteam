import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../core/env.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth.dart';
import '../notifications/push.dart';

/// Available even before joining a team or while waiting for approval.
class DeleteAccountTile extends StatelessWidget {
  const DeleteAccountTile({super.key});

  @override
  Widget build(BuildContext context) => Env.demo
      ? const SizedBox.shrink()
      : ListTile(
          leading: Icon(Icons.person_remove_outlined, color: Theme.of(context).colorScheme.error),
          title: Text(
            AppLocalizations.of(context).deleteAccount,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          onTap: () => showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const _DeleteAccountDialog(),
          ),
        );
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  late Future<Map<String, dynamic>> _info;
  bool _confirmed = false;
  bool _busy = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _info = _load();
  }

  Future<Map<String, dynamic>> _load() async =>
      Map<String, dynamic>.from(await ref.read(supabaseProvider).rpc('account_deletion_info') as Map);

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authRepositoryProvider);
    final offline = ref.read(offlineStoreProvider);
    final push = ref.read(pushRegistrationProvider.notifier);
    try {
      await auth.deleteAccount();
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error;
        });
      }
      return;
    }
    // The account is gone. Cleanup errors must not leave its local session
    // signed in or invite someone to repeat an already completed deletion.
    try {
      await push.disable();
    } catch (_) {}
    await offline.clear();
    if (mounted) Navigator.pop(context);
    try {
      await auth.clearDeletedSession();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_busy,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _info,
        builder: (context, snapshot) {
          final blocked = (snapshot.data?['blocked_teams'] as List? ?? const []).cast<String>();
          final removed = (snapshot.data?['deleted_teams'] as List? ?? const []).cast<String>();
          final error = _error ?? snapshot.error;
          return AlertDialog(
            title: Text(l10n.deleteAccount),
            scrollable: true,
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!snapshot.hasData && !snapshot.hasError)
                    const Center(child: CircularProgressIndicator())
                  else if (blocked.isNotEmpty) ...[
                    Text(l10n.accountNeedsOwner),
                    const SizedBox(height: 12),
                    Text(blocked.join('\n')),
                  ] else if (snapshot.hasData) ...[
                    Text(l10n.deleteAccountWarning),
                    if (removed.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(l10n.deleteSoloTeams(removed.join(', '))),
                    ],
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(l10n.deleteAccountUnderstand),
                      value: _confirmed,
                      onChanged: _busy ? null : (value) => setState(() => _confirmed = value ?? false),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(AppError.from(error).message(l10n), style: TextStyle(color: colors.error)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(l10n.cancel)),
              if (snapshot.hasError)
                TextButton(onPressed: () => setState(() => _info = _load()), child: Text(l10n.retry)),
              if (snapshot.hasData && blocked.isEmpty)
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
                  onPressed: !_confirmed || _busy ? null : _delete,
                  child: _busy
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: colors.onError),
                        )
                      : Text(l10n.deleteAccount),
                ),
            ],
          );
        },
      ),
    );
  }
}
