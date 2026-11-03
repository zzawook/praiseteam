import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import 'annotations_controller.dart';
import 'ink.dart';
import 'ink_painter.dart';

enum InkMode { view, pen, highlighter, eraser }

/// Drawing settings shared by every page of the viewer.
class InkSettings {
  const InkSettings({
    this.mode = InkMode.view,
    this.target = InkVisibility.private,
    this.color = 0xFF1D1F23,
    this.showTeam = true,
    this.showMine = true,
    this.stylusOnly = false,
  });

  final InkMode mode;

  /// Who new strokes are for. Defaults to "only me".
  final InkVisibility target;
  final int color;
  final bool showTeam;
  final bool showMine;

  /// Set once a stylus is seen: from then on only the pen draws and fingers
  /// turn pages, so a resting palm never leaves marks.
  final bool stylusOnly;

  bool get drawing => mode != InkMode.view;

  InkSettings copyWith({
    InkMode? mode,
    InkVisibility? target,
    int? color,
    bool? showTeam,
    bool? showMine,
    bool? stylusOnly,
  }) => InkSettings(
    mode: mode ?? this.mode,
    target: target ?? this.target,
    color: color ?? this.color,
    showTeam: showTeam ?? this.showTeam,
    showMine: showMine ?? this.showMine,
    stylusOnly: stylusOnly ?? this.stylusOnly,
  );
}

/// Undo/redo entry: a stroke that was drawn, or one that was erased.
sealed class InkAction {
  const InkAction(this.strokeId);
  final String strokeId;
}

class Drew extends InkAction {
  const Drew(super.strokeId);
}

class Erased extends InkAction {
  const Erased(super.strokeId);
}

/// Strokes of one sheet page, plus drawing and erasing on it.
class AnnotationLayer extends ConsumerStatefulWidget {
  const AnnotationLayer({
    super.key,
    required this.teamId,
    required this.sessionId,
    required this.itemId,
    required this.sheetId,
    required this.pageIndex,
    required this.settings,
    required this.isLeader,
    required this.myId,
    required this.onAction,
    required this.onStylusSeen,
    this.interactionBlocked,
  });

  final int teamId;
  final int sessionId;
  final int itemId;
  final int sheetId;
  final int pageIndex;
  final InkSettings settings;
  final bool isLeader;
  final String? myId;
  final void Function(InkAction) onAction;
  final VoidCallback onStylusSeen;
  final ValueListenable<bool>? interactionBlocked;

  @override
  ConsumerState<AnnotationLayer> createState() => _AnnotationLayerState();
}

class _AnnotationLayerState extends ConsumerState<AnnotationLayer> {
  static const _penWidth = 0.004; // of page width
  static const _highlighterWidth = 0.022;
  static const _eraserRadius = 0.015;

  final _live = <InkPoint>[];
  final _pendingErases = <String>{};
  int? _pointer;
  bool _sawStylus = false;
  bool _erasing = false;
  InkSettings? _strokeSettings;

  @override
  void initState() {
    super.initState();
    widget.interactionBlocked?.addListener(_navigationChanged);
  }

  @override
  void didUpdateWidget(covariant AnnotationLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interactionBlocked != widget.interactionBlocked) {
      oldWidget.interactionBlocked?.removeListener(_navigationChanged);
      widget.interactionBlocked?.addListener(_navigationChanged);
    }
  }

  @override
  void dispose() {
    widget.interactionBlocked?.removeListener(_navigationChanged);
    super.dispose();
  }

  void _cancelStroke() {
    _pointer = null;
    _strokeSettings = null;
    if (_live.isNotEmpty || _pendingErases.isNotEmpty) {
      setState(() {
        _live.clear();
        _pendingErases.clear();
      });
    }
  }

  void _navigationChanged() {
    if (widget.interactionBlocked?.value ?? false) _cancelStroke();
  }

  bool _accepts(PointerEvent e) {
    if (!widget.settings.drawing) return false;
    if (e.kind == PointerDeviceKind.stylus || e.kind == PointerDeviceKind.invertedStylus) return true;
    if (widget.interactionBlocked?.value ?? false) return false;
    if (e.kind == PointerDeviceKind.mouse && e.buttons != kPrimaryMouseButton) return false;
    return !widget.settings.stylusOnly && !_sawStylus;
  }

  InkPoint _toPage(PointerEvent e, Size size) {
    final hasPressure = e.kind == PointerDeviceKind.stylus && e.pressureMax > e.pressureMin;
    final pressure = hasPressure ? ((e.pressure - e.pressureMin) / (e.pressureMax - e.pressureMin)) : 0.5;
    return (
      x: (e.localPosition.dx / size.width).clamp(0.0, 1.0),
      y: (e.localPosition.dy / size.height).clamp(0.0, 1.0),
      p: pressure,
    );
  }

  List<InkStroke> _visible(Map<String, InkStroke> all) => [
    for (final s in all.values)
      if (!s.isDeleted &&
          s.itemId == widget.itemId &&
          s.sheetId == widget.sheetId &&
          s.pageIndex == widget.pageIndex &&
          (s.ownerId == widget.myId ? widget.settings.showMine : widget.settings.showTeam))
        s,
  ]..sort((a, b) => a.id.compareTo(b.id)); // UUIDv7: creation order

  void _erase(InkPoint at, List<InkStroke> visible) {
    final controller = ref.read(sessionInkProvider(widget.sessionId).notifier);
    for (final s in visible) {
      if (controller.canErase(s, isLeader: widget.isLeader) && distanceToStroke(at, s.points) < _eraserRadius) {
        // Preview locally, commit on release. A second finger may turn this
        // gesture into a pinch; in that case nothing must actually be erased.
        if (_pendingErases.add(s.id)) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = ref.watch(sessionInkProvider(widget.sessionId)).value ?? const {};
    final visible = _visible(ink);
    final settings = widget.settings;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Listener(
          behavior: settings.drawing ? HitTestBehavior.opaque : HitTestBehavior.translucent,
          onPointerDown: (e) {
            if (e.kind == PointerDeviceKind.stylus || e.kind == PointerDeviceKind.invertedStylus) {
              // A palm may land before the pen. Replace its provisional mark,
              // rather than letting it keep ownership of the pen's gesture.
              if (_pointer != null && _pointer != e.pointer) _cancelStroke();
              _sawStylus = true;
              widget.onStylusSeen();
            }
            if (!_accepts(e) || _pointer != null) return;
            _pointer = e.pointer;
            _strokeSettings = settings;
            _erasing = settings.mode == InkMode.eraser || e.kind == PointerDeviceKind.invertedStylus;
            final point = _toPage(e, size);
            // The back end of a stylus erases, whatever tool is selected.
            if (_erasing) {
              _erase(point, visible);
            } else {
              setState(
                () => _live
                  ..clear()
                  ..add(point),
              );
            }
          },
          onPointerMove: (e) {
            if (e.pointer != _pointer) return;
            final point = _toPage(e, size);
            if (_erasing) {
              _erase(point, visible);
            } else {
              setState(() => _live.add(point));
            }
          },
          onPointerUp: (e) {
            if (e.pointer != _pointer) return;
            _pointer = null;
            final strokeSettings = _strokeSettings ?? settings;
            _strokeSettings = null;
            if (_erasing) {
              final controller = ref.read(sessionInkProvider(widget.sessionId).notifier);
              for (final id in _pendingErases) {
                controller.setDeleted(id, deleted: true);
                widget.onAction(Erased(id));
              }
              setState(_pendingErases.clear);
              return;
            }
            if (_live.isEmpty) return;
            final highlighter = strokeSettings.mode == InkMode.highlighter;
            final stroke = ref
                .read(sessionInkProvider(widget.sessionId).notifier)
                .add(
                  teamId: widget.teamId,
                  itemId: widget.itemId,
                  sheetId: widget.sheetId,
                  pageIndex: widget.pageIndex,
                  visibility: strokeSettings.target,
                  tool: highlighter ? InkTool.highlighter : InkTool.pen,
                  color: highlighter ? AppColors.stageAmber.toARGB32() : strokeSettings.color,
                  width: highlighter ? _highlighterWidth : _penWidth,
                  points: List.of(_live),
                );
            widget.onAction(Drew(stroke.id));
            setState(_live.clear);
          },
          onPointerCancel: (e) {
            if (e.pointer != _pointer) return;
            _cancelStroke();
          },
          child: CustomPaint(
            size: size,
            painter: InkPainter(
              strokes: [
                for (final s in visible)
                  if (!_pendingErases.contains(s.id)) s,
              ],
              revision: Object.hash(Object.hashAll([for (final s in visible) s.id]), Object.hashAll(_pendingErases)),
              live: _live.isEmpty
                  ? null
                  : LiveInk(
                      points: List.of(_live),
                      tool: (_strokeSettings ?? settings).mode == InkMode.highlighter
                          ? InkTool.highlighter
                          : InkTool.pen,
                      color: (_strokeSettings ?? settings).mode == InkMode.highlighter
                          ? AppColors.stageAmber.toARGB32()
                          : (_strokeSettings ?? settings).color,
                      width: (_strokeSettings ?? settings).mode == InkMode.highlighter ? _highlighterWidth : _penWidth,
                    ),
            ),
          ),
        );
      },
    );
  }
}
