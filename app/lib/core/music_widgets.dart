import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'music.dart';

/// A key in a small outlined box, like a key signature marked on a chart.
class KeyBadge extends StatelessWidget {
  const KeyBadge(this.musicalKey, {super.key, this.emphasized = false});
  final String? musicalKey;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final key = musicalKey;
    if (key == null || key.isEmpty) return const SizedBox.shrink();
    final color = emphasized ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    return Container(
      constraints: const BoxConstraints(minWidth: 32),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: emphasized ? 1.5 : 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        key,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Dropdown of valid keys; null means "not set".
class KeyField extends StatelessWidget {
  const KeyField({super.key, required this.value, required this.onChanged, this.label});
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<String?>(
      initialValue: allKeys.contains(value) ? value : null,
      decoration: InputDecoration(labelText: label ?? l10n.key),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('—')),
        for (final k in allKeys) DropdownMenuItem<String?>(value: k, child: Text(k)),
      ],
      onChanged: onChanged,
    );
  }
}
