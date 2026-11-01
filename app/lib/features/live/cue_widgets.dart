import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../teams/models.dart';
import 'live_session.dart';

/// Pick a cue and who it is for. Returns null if cancelled.
Future<({String text, int? partId})?> showCueSheet(BuildContext context, List<Part> parts) {
  final l10n = AppLocalizations.of(context);
  final presets = [
    l10n.cueAgain,
    l10n.cueChorus,
    l10n.cueBridge,
    l10n.cueEnding,
    l10n.cueKeyUp,
    l10n.cueSofter,
    l10n.cueFaster,
    l10n.cueSlower,
    l10n.cueNextSong,
  ];
  int? partId;
  final custom = TextEditingController();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.cueTo, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: Text(l10n.cueEveryone),
                  selected: partId == null,
                  onSelected: (_) => setState(() => partId = null),
                ),
                for (final p in parts)
                  ChoiceChip(
                    label: Text(p.name),
                    selected: partId == p.id,
                    onSelected: (_) => setState(() => partId = p.id),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.4,
              children: [
                for (final text in presets)
                  FilledButton.tonal(
                    onPressed: () => Navigator.pop(context, (text: text, partId: partId)),
                    child: Text(text, textAlign: TextAlign.center),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: custom,
              maxLength: 40,
              decoration: InputDecoration(labelText: l10n.cueCustom, counterText: ''),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) Navigator.pop(context, (text: v.trim(), partId: partId));
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// The latest cue, big and amber, for a few seconds. Readable from across
/// a dark stage; a phone also vibrates.
class CueBanner extends StatefulWidget {
  const CueBanner({super.key, required this.cue, required this.serial, required this.partName});
  final LiveCue? cue;

  /// Changes with every new cue, even when its text repeats.
  final int serial;
  final String? Function(int? partId) partName;

  @override
  State<CueBanner> createState() => _CueBannerState();
}

class _CueBannerState extends State<CueBanner> {
  static const _shown = Duration(seconds: 4);
  bool _visible = false;
  Timer? _timer;

  @override
  void didUpdateWidget(CueBanner old) {
    super.didUpdateWidget(old);
    if (widget.serial != old.serial && widget.cue != null) {
      HapticFeedback.heavyImpact();
      _timer?.cancel();
      setState(() => _visible = true);
      _timer = Timer(_shown, () {
        if (mounted) setState(() => _visible = false);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cue = widget.cue;
    final theme = Theme.of(context);
    final target = widget.partName(cue?.partId);
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        child: cue == null
            ? const SizedBox.shrink()
            // A live region of its own: screen readers announce each cue.
            : Semantics(
                container: true,
                liveRegion: true,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  decoration: BoxDecoration(color: AppColors.stageAmber, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cue.text,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(color: Colors.black, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [cue.from, ?target].join('  →  '),
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
