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
  }) =>
      InkSettings(
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

  @override
  ConsumerState<AnnotationLayer> createState() => _AnnotationLayerState();
}

class _AnnotationLayerState extends ConsumerState<AnnotationLayer> {
  static const _penWidth = 0.004; // of page width
  static const _highlighterWidth = 0.022;
  static const _eraserRadius = 0.015;

  final _live = <InkPoint>[];
  int? _pointer;

  bool _accepts(PointerEvent e) {
    if (!widget.settings.drawing) return false;
    if (e.kind == PointerDeviceKind.stylus || e.kind == PointerDeviceKind.invertedStylus) return true;
    return !widget.settings.stylusOnly;
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
        controller.setDeleted(s.id, deleted: true);
        widget.onAction(Erased(s.id));
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
              widget.onStylusSeen();
            }
            if (!_accepts(e) || _pointer != null) return;
            _pointer = e.pointer;
            final point = _toPage(e, size);
            // The back end of a stylus erases, whatever tool is selected.
            if (settings.mode == InkMode.eraser || e.kind == PointerDeviceKind.invertedStylus) {
              _erase(point, visible);
            } else {
              setState(() => _live
                ..clear()
                ..add(point));
            }
          },
          onPointerMove: (e) {
            if (e.pointer != _pointer) return;
            final point = _toPage(e, size);
            if (settings.mode == InkMode.eraser || e.kind == PointerDeviceKind.invertedStylus) {
              _erase(point, visible);
            } else {
              setState(() => _live.add(point));
            }
          },
          onPointerUp: (e) {
            if (e.pointer != _pointer) return;
            _pointer = null;
            if (_live.isEmpty) return;
            final highlighter = settings.mode == InkMode.highlighter;
            final stroke = ref.read(sessionInkProvider(widget.sessionId).notifier).add(
                  teamId: widget.teamId,
                  itemId: widget.itemId,
                  sheetId: widget.sheetId,
                  pageIndex: widget.pageIndex,
                  visibility: settings.target,
                  tool: highlighter ? InkTool.highlighter : InkTool.pen,
                  color: highlighter ? AppColors.stageAmber.toARGB32() : settings.color,
                  width: highlighter ? _highlighterWidth : _penWidth,
                  points: List.of(_live),
                );
            widget.onAction(Drew(stroke.id));
            setState(_live.clear);
          },
          onPointerCancel: (e) {
            if (e.pointer != _pointer) return;
            _pointer = null;
            setState(_live.clear);
          },
          child: CustomPaint(
            size: size,
            painter: InkPainter(
              strokes: visible,
              revision: Object.hashAll([for (final s in visible) s.id]),
              live: _live.isEmpty
                  ? null
                  : LiveInk(
                      points: List.of(_live),
                      tool: settings.mode == InkMode.highlighter ? InkTool.highlighter : InkTool.pen,
                      color: settings.mode == InkMode.highlighter ? AppColors.stageAmber.toARGB32() : settings.color,
                      width: settings.mode == InkMode.highlighter ? _highlighterWidth : _penWidth,
                    ),
            ),
          ),
        );
      },
    );
  }
}
