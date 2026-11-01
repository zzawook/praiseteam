import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'errors.dart';

/// Keeps reading width comfortable on tablets and laptops.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 720});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        // Take the child's height, not all available height: this widget is
        // also used inside bottom bars, where expanding hides the body.
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

/// Loading / error-with-retry / data for an [AsyncValue].
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.data, this.onRetry});
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (value) {
      AsyncValue(:final value?, hasValue: true) => data(value),
      AsyncValue(:final error?) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppError.from(error).message(l10n), textAlign: TextAlign.center),
                if (onRetry != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
                ],
              ],
            ),
          ),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

void showError(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(AppError.from(error).message(l10n))));
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirm(
  BuildContext context, {
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: theme.colorScheme.error)
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Runs [action], reporting failures as a snackbar. Returns whether it worked.
Future<bool> runGuarded(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } catch (e) {
    if (context.mounted) showError(context, e);
    return false;
  }
}
