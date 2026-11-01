import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../auth/auth.dart';
import '../offline/offline.dart';
import 'annotations_repository.dart';
import 'ink.dart';
import 'stroke_outbox.dart';

part 'annotations_controller.g.dart';

@Riverpod(keepAlive: true)
AnnotationsRepository annotationsRepository(Ref ref) =>
    AnnotationsRepository(ref.watch(supabaseProvider), ref.watch(readThroughProvider));

/// Strokes of one session, by id, kept in sync with the server.
///
/// Local changes apply at once and go to the [StrokeOutbox], which keeps
/// them on the device until the server has them. What the screen shows is
/// the server's strokes (or the saved copy, offline) with the waiting
/// changes applied on top, so notes drawn offline stay visible after a
/// restart.
@riverpod
class SessionInk extends _$SessionInk {
  Timer? _saveSoon;

  @override
  Future<Map<String, InkStroke>> build(int sessionId) async {
    final repo = ref.watch(annotationsRepositoryProvider);
    final channel = repo.watch(sessionId, _merge);
    // Back online: catch up on what others drew meanwhile.
    ref.listen(onlineStatusProvider.select((s) => s.epoch), (_, _) => _refresh());
    ref.onDispose(() {
      channel.unsubscribe();
      _saveSoon?.cancel();
    });
    return _load();
  }

  Future<Map<String, InkStroke>> _load() async {
    final strokes = await ref.read(annotationsRepositoryProvider).forSession(sessionId);
    final shown = {for (final s in strokes) s.id: s};
    for (final op in await ref.read(strokeOutboxProvider.notifier).pendingFor(sessionId)) {
      op.applyTo(shown);
    }
    return shown;
  }

  Future<void> _refresh() async {
    try {
      final fresh = await _load();
      state = AsyncData({...?state.value, ...fresh});
    } catch (_) {
      // Still unreachable: keep what is shown.
    }
  }

  String? get _me => ref.read(currentUserIdProvider);

  void _merge(InkStroke stroke) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData({...current, stroke.id: stroke});
    _saveLater();
  }

  /// Keeps the device's copy current with strokes that arrive live, so
  /// they are there after a restart without a connection.
  void _saveLater() {
    _saveSoon?.cancel();
    _saveSoon = Timer(const Duration(seconds: 2), () {
      final strokes = state.value;
      final owner = _me;
      if (strokes == null || owner == null) return;
      ref.read(offlineStoreProvider).saveSnapshot(
        owner,
        AnnotationsRepository.offlineKey(sessionId),
        [for (final s in strokes.values) s.toRow()],
      );
    });
  }

  InkStroke add({
    required int teamId,
    required int itemId,
    required int sheetId,
    required int pageIndex,
    required InkVisibility visibility,
    required InkTool tool,
    required int color,
    required double width,
    required List<InkPoint> points,
  }) {
    final stroke = InkStroke(
      id: const Uuid().v7(),
      teamId: teamId,
      sessionId: sessionId,
      itemId: itemId,
      sheetId: sheetId,
      pageIndex: pageIndex,
      ownerId: _me ?? '',
      visibility: visibility,
      tool: tool,
      color: color,
      width: width,
      points: simplify(points),
    );
    _merge(stroke);
    ref.read(strokeOutboxProvider.notifier).add(SaveStroke(stroke));
    return stroke;
  }

  void setDeleted(String strokeId, {required bool deleted}) {
    final stroke = state.value?[strokeId];
    if (stroke == null) return;
    final at = deleted ? DateTime.now() : null;
    _merge(stroke.withDeletedAt(at));
    ref.read(strokeOutboxProvider.notifier).add(EraseStroke(sessionId, strokeId, at));
  }

  /// Whether the current user may erase [stroke] (mirrors the RLS policy).
  bool canErase(InkStroke stroke, {required bool isLeader}) =>
      stroke.ownerId == _me || (stroke.visibility == InkVisibility.team && isLeader);

  Future<int> copyPrevious(int itemId) async {
    final count = await ref.read(annotationsRepositoryProvider).copyPrevious(itemId);
    if (count > 0) state = AsyncData(await _load());
    return count;
  }
}
