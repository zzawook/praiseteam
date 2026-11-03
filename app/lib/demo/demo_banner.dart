import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/router.dart';
import '../core/env.dart';
import '../l10n/app_localizations.dart';

final resetDemoProvider = Provider<Future<void> Function()>(
  (ref) => throw UnimplementedError('Demo only'),
);

class DemoBanner extends ConsumerStatefulWidget {
  const DemoBanner({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<DemoBanner> createState() => _DemoBannerState();
}

class _DemoBannerState extends ConsumerState<DemoBanner> {
  bool _resetting = false;
  @override
  Widget build(BuildContext context) {
    if (!Env.demo) return widget.child;
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    // This banner lives above the Router's Navigator. Its tooltip therefore
    // needs its own Overlay, including in debug and native sample builds.
    return Overlay.wrap(
      child: Column(
        // Paint after the Router's route semantics so the demo controls remain
        // accessible while keeping them visually above the page.
        verticalDirection: VerticalDirection.up,
        children: [
          Expanded(child: widget.child),
          Material(
            color: colors.secondaryContainer,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.science_outlined,
                      size: 18,
                      color: colors.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.demoBanner,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colors.onSecondaryContainer),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.demoVideo,
                      onPressed: () => launchUrl(
                        Uri.base.resolve('/watch.html'),
                        webOnlyWindowName: '_blank',
                      ),
                      icon: const Icon(Icons.play_circle_outline, size: 21),
                    ),
                    TextButton.icon(
                      onPressed: _resetting
                          ? null
                          : () async {
                              final reset = ref.read(resetDemoProvider);
                              setState(() => _resetting = true);
                              await reset();
                              if (mounted) {
                                ref.read(routerProvider).go('/t/1/home');
                                setState(() => _resetting = false);
                              }
                            },
                      icon: const Icon(Icons.restart_alt, size: 18),
                      label: Text(l10n.demoReset),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
