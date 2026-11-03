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

/// Cues one tap away while live: the seven most used, to everyone, and
/// "more" for the rest (faster, slower, a custom text, or one part only).
/// Two rows under the pages when the screen is upright; a rail beside them
/// when it lies sideways, in the margin a portrait page leaves. Neither
/// covers music, and anyone can hide it to give the pages the room.
class CueBar extends StatelessWidget {
  const CueBar({super.key, required this.vertical, this.enabled = true, required this.onCue, required this.onMore});
  final bool vertical;
  final bool enabled;
  final ValueChanged<String> onCue;
  final VoidCallback onMore;

  static const _cell = 48.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quick = [
      l10n.cueAgain,
      l10n.cueChorus,
      l10n.cueBridge,
      l10n.cueEnding,
      l10n.cueKeyUp,
      l10n.cueSofter,
      l10n.cueNextSong,
    ];
    final style = OutlinedButton.styleFrom(
      foregroundColor: AppColors.stageAmber,
      side: BorderSide(color: AppColors.stageAmber.withValues(alpha: 0.6)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      minimumSize: const Size(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
    final buttons = <Widget>[
      for (final text in quick)
        OutlinedButton(
          style: style,
          onPressed: enabled ? () => onCue(text) : null,
          child: Text(text, maxLines: 1, softWrap: false, overflow: TextOverflow.fade),
        ),
      Tooltip(
        message: l10n.moreCues,
        child: OutlinedButton(style: style, onPressed: enabled ? onMore : null, child: const Icon(Icons.more_horiz)),
      ),
    ];

    // Rows of [columns] buttons, each the same width.
    Widget grid(int columns) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < buttons.length; row += columns)
          Row(
            children: [
              for (final button in buttons.skip(row).take(columns))
                Expanded(
                  child: Padding(padding: const EdgeInsets.all(3), child: button),
                ),
            ],
          ),
      ],
    );

    if (vertical) {
      return LayoutBuilder(
        builder: (context, box) {
          // Tall enough for one column of eight? Otherwise two per row.
          final columns = box.maxHeight >= buttons.length * _cell ? 1 : 2;
          return SizedBox(
            width: columns == 1 ? 108 : 196,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: grid(columns)),
            ),
          );
        },
      );
    }
    // On a wide upright screen (a tablet) the rows keep phone proportions.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(padding: const EdgeInsets.fromLTRB(5, 4, 5, 0), child: grid(4)),
      ),
    );
  }
}
