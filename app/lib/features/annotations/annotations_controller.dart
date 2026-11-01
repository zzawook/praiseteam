import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../auth/auth.dart';
import 'annotations_repository.dart';
import 'ink.dart';

part 'annotations_controller.g.dart';

@Riverpod(keepAlive: true)
AnnotationsRepository annotationsRepository(Ref ref) => AnnotationsRepository(ref.watch(supabaseProvider));

/// Strokes of one session, by id, kept in sync with the server.
///
/// Local changes apply immediately and are sent in the background; failed
/// sends stay queued and are retried, in order, every few seconds. Because
/// strokes are immutable (insert, or set deleted_at) and ids come from the
/// device, a retry can never duplicate or conflict with anything.
@riverpod
class SessionInk extends _$SessionInk {
  final _queue = <Future<void> Function()>[];
  Timer? _retry;

  @override
  Future<Map<String, InkStroke>> build(int sessionId) async {
    final repo = ref.watch(annotationsRepositoryProvider);
    final channel = repo.watch(sessionId, _merge);
    ref.onDispose(() {
      channel.unsubscribe();
      _retry?.cancel();
    });
    final strokes = await repo.forSession(sessionId);
    return {for (final s in strokes) s.id: s};
  }

  String? get _me => ref.read(currentUserIdProvider);

  void _merge(InkStroke stroke) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData({...current, stroke.id: stroke});
  }

  /// Number of local changes not yet confirmed by the server.
  int get pending => _queue.length;

  void _enqueue(Future<void> Function() send) {
    _queue.add(send);
    _drain();
  }

  Future<void> _drain() async {
    _retry?.cancel();
    while (_queue.isNotEmpty) {
      try {
        await _queue.first();
        _queue.removeAt(0);
      } catch (_) {
        _retry = Timer(const Duration(seconds: 5), _drain);
        return;
      }
    }
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
    final repo = ref.read(annotationsRepositoryProvider);
    _enqueue(() => repo.save(stroke));
    return stroke;
  }

  void setDeleted(String strokeId, {required bool deleted}) {
    final stroke = state.value?[strokeId];
    if (stroke == null) return;
    final at = deleted ? DateTime.now() : null;
    _merge(stroke.withDeletedAt(at));
    final repo = ref.read(annotationsRepositoryProvider);
    _enqueue(() => repo.setDeleted(strokeId, at));
  }

  /// Whether the current user may erase [stroke] (mirrors the RLS policy).
  bool canErase(InkStroke stroke, {required bool isLeader}) =>
      stroke.ownerId == _me || (stroke.visibility == InkVisibility.team && isLeader);

  Future<int> copyPrevious(int itemId) async {
    final count = await ref.read(annotationsRepositoryProvider).copyPrevious(itemId);
    if (count > 0) {
      final strokes = await ref.read(annotationsRepositoryProvider).forSession(sessionId);
      state = AsyncData({for (final s in strokes) s.id: s});
    }
    return count;
  }
}
