import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import 'sheet_transform.dart';

typedef SheetViewportBuilder = Widget Function(ValueListenable<bool> inkBlocked, double renderScale);

/// One transform for the PDF and ink. Raw pointer ownership distinguishes
/// handwriting from two-finger navigation without competing scale/drag arenas.
/// The enclosing PageView is programmatic; unzoomed swipes are forwarded here.
class SheetViewport extends StatefulWidget {
  const SheetViewport({
    super.key,
    required this.builder,
    required this.onTurn,
    required this.drawing,
    required this.stylusOnly,
    this.aspectRatio,
    this.zoomEnabled = true,
  });

  final SheetViewportBuilder builder;
  final ValueChanged<int> onTurn;
  final bool drawing;
  final bool stylusOnly;
  final double? aspectRatio;
  final bool zoomEnabled;

  @override
  State<SheetViewport> createState() => _SheetViewportState();
}

class _SheetViewportState extends State<SheetViewport> {
  static const _zoomSteps = [1.0, 1.5, 2.0, 3.0, 4.0];
  final _inkBlocked = ValueNotifier(false);
  final _pointers = <int, Offset>{};
  final _kinds = <int, PointerDeviceKind>{};
  SheetTransform _transform = const SheetTransform();
  SheetTransform _startTransform = const SheetTransform();
  Size _size = Size.zero;
  Rect _page = Rect.zero;
  Offset? _singleStart;
  Offset? _previous;
  Offset _startFocal = Offset.zero;
  double _startDistance = 1;
  double _renderScale = 1;
  bool _navigation = false;
  bool _ignoreTouches = false;
  bool _trackpad = false;
  bool _trackpadScaled = false;
  Offset _trackpadPan = Offset.zero;

  bool _stylus(PointerDeviceKind kind) => kind == PointerDeviceKind.stylus || kind == PointerDeviceKind.invertedStylus;
  bool get _penDown => widget.drawing && _kinds.values.any(_stylus);
  bool get _singleNavigates => !widget.drawing || widget.stylusOnly;
  List<Offset> get _touches => [
    for (final e in _pointers.entries)
      if (_kinds[e.key] == PointerDeviceKind.touch) e.value,
  ];

  @override
  void dispose() {
    _inkBlocked.dispose();
    super.dispose();
  }

  void _beginNavigation() {
    _navigation = true;
    _inkBlocked.value = true; // synchronously cancel provisional ink/erasures
  }

  void _settle() {
    // Ask for sharper pixels once a gesture ends, retaining the old PDF image
    // while pdfrx renders. Pan/ink frames never trigger a new PDF rasterization.
    if (_renderScale < _transform.scale) setState(() => _renderScale = _transform.scale);
  }

  void _changeZoom(double scale, {Offset? focal}) {
    if (!widget.zoomEnabled || _penDown || _size.isEmpty) return;
    _beginNavigation();
    setState(() => _transform = _transform.zoomAt(scale, focal ?? _size.center(Offset.zero), _size, _page));
    _settle();
    if (_pointers.isEmpty && !_trackpad) {
      _navigation = false;
      _inkBlocked.value = false;
    }
  }

  void _down(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse && event.buttons != kPrimaryMouseButton) return;
    _pointers[event.pointer] = event.localPosition;
    _kinds[event.pointer] = event.kind;
    if (_stylus(event.kind) && widget.drawing) {
      // A pen owns the page until it and any resting fingers have lifted.
      _ignoreTouches = true;
      _navigation = false;
      _inkBlocked.value = false;
      return;
    }
    if (_ignoreTouches || _penDown) return;
    final touches = _touches;
    if (touches.length >= 2) {
      _beginNavigation();
      _startTransform = _transform;
      _startFocal = (touches[0] + touches[1]) / 2;
      _startDistance = math.max(1, (touches[0] - touches[1]).distance);
      return;
    }
    if (_pointers.length == 1) {
      _singleStart = _previous = event.localPosition;
      if (_transform.zoomed && _singleNavigates) _beginNavigation();
    }
  }

  void _move(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.localPosition;
    if (_ignoreTouches || _penDown) return;
    final touches = _touches;
    if (touches.length >= 2 && widget.zoomEnabled) {
      final focal = (touches[0] + touches[1]) / 2;
      final scale = _startTransform.scale * (touches[0] - touches[1]).distance / _startDistance;
      setState(() => _transform = _startTransform.pinch(scale, _startFocal, focal, _size, _page));
    } else if (_pointers.length == 1 && _singleNavigates && _transform.zoomed && _previous != null) {
      setState(() => _transform = _transform.pan(event.localPosition - _previous!, _size, _page));
    }
    _previous = event.localPosition;
  }

  void _up(PointerEvent event, {bool cancelled = false}) {
    final wasSingle = _pointers.length == 1;
    _pointers.remove(event.pointer);
    _kinds.remove(event.pointer);
    if (!cancelled && wasSingle && !_navigation && !_ignoreTouches && _singleNavigates && !_transform.zoomed) {
      final delta = event.localPosition - (_singleStart ?? event.localPosition);
      if (delta.dx.abs() >= 60 && delta.dx.abs() > delta.dy.abs() * 1.4) {
        widget.onTurn(delta.dx < 0 ? 1 : -1);
      } else if (delta.distance < 12 && !widget.drawing) {
        final x = event.localPosition.dx / _size.width;
        if (x > 0.66) widget.onTurn(1);
        if (x < 0.33) widget.onTurn(-1);
      }
    }
    if (_pointers.isEmpty && !_trackpad) {
      _settle();
      _navigation = false;
      _ignoreTouches = false;
      _singleStart = _previous = null;
      _inkBlocked.value = false;
    } else {
      // Lifting one finger from a pinch must not start a stroke or turn a page.
      _previous = _pointers.values.firstOrNull;
      final touches = _touches;
      if (touches.length >= 2) {
        _startTransform = _transform;
        _startFocal = (touches[0] + touches[1]) / 2;
        _startDistance = math.max(1, (touches[0] - touches[1]).distance);
      }
    }
  }

  void _scroll(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !widget.zoomEnabled || _penDown) return;
    final zoom = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    if (!zoom && !_transform.zoomed) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      if (zoom) {
        _changeZoom(_transform.scale * math.exp(-event.scrollDelta.dy / 250), focal: event.localPosition);
      } else {
        _beginNavigation();
        setState(() => _transform = _transform.pan(-event.scrollDelta, _size, _page));
        if (_pointers.isEmpty) {
          _navigation = false;
          _inkBlocked.value = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_size != constraints.biggest) {
          final nextSize = constraints.biggest;
          final nextPage = fittedSheetRect(nextSize, widget.aspectRatio);
          _transform = _transform.reframe(_size, _page, nextSize, nextPage);
          _size = nextSize;
          _page = nextPage;
          // Rotation/layout changes invalidate a pointer's cached hit-test transform.
          if (_pointers.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _beginNavigation();
            });
          }
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _down,
              onPointerMove: _move,
              onPointerUp: _up,
              onPointerCancel: (event) => _up(event, cancelled: true),
              onPointerSignal: _scroll,
              onPointerPanZoomStart: (event) {
                if (!widget.zoomEnabled || _penDown) return;
                _trackpad = true;
                _trackpadScaled = false;
                _trackpadPan = Offset.zero;
                _beginNavigation();
                _startTransform = _transform;
                _startFocal = event.localPosition;
              },
              onPointerPanZoomUpdate: (event) {
                if (!_trackpad || _penDown) return;
                _trackpadPan = event.pan;
                _trackpadScaled |= (event.scale - 1).abs() > .01;
                setState(
                  () => _transform = _startTransform.pinch(
                    _startTransform.scale * event.scale,
                    _startFocal,
                    _startFocal + event.pan,
                    _size,
                    _page,
                  ),
                );
              },
              onPointerPanZoomEnd: (_) {
                if (!_trackpad) return;
                _trackpad = false;
                _settle();
                if (!_trackpadScaled &&
                    !_transform.zoomed &&
                    _singleNavigates &&
                    _trackpadPan.dx.abs() >= 60 &&
                    _trackpadPan.dx.abs() > _trackpadPan.dy.abs() * 1.4) {
                  widget.onTurn(_trackpadPan.dx < 0 ? 1 : -1);
                }
                if (_pointers.isEmpty) {
                  _navigation = false;
                  _inkBlocked.value = false;
                }
              },
              child: ClipRect(
                child: Transform(
                  transform: _transform.matrix,
                  child: SizedBox.expand(child: widget.builder(_inkBlocked, _renderScale)),
                ),
              ),
            ),
            if (widget.zoomEnabled)
              Positioned(
                right: 8,
                top: 8,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  child: Material(
                    color: const Color(0xE61D1F23),
                    borderRadius: BorderRadius.circular(24),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.zoomOut,
                          color: Colors.white,
                          disabledColor: Colors.white38,
                          onPressed: _transform.zoomed
                              ? () => _changeZoom(
                                  _zoomSteps.lastWhere((s) => s < _transform.scale - .001, orElse: () => 1),
                                )
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        TextButton(
                          onPressed: () => _changeZoom(1),
                          style: TextButton.styleFrom(foregroundColor: Colors.white),
                          child: Tooltip(message: l10n.fitSheet, child: Text('${(_transform.scale * 100).round()}%')),
                        ),
                        IconButton(
                          tooltip: l10n.zoomIn,
                          color: Colors.white,
                          disabledColor: Colors.white38,
                          onPressed: _transform.scale < SheetTransform.maxScale
                              ? () => _changeZoom(
                                  _zoomSteps.firstWhere((s) => s > _transform.scale + .001, orElse: () => 4),
                                )
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
