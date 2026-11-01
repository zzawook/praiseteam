import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/offline/reachability.dart';
import '../../core/providers.dart';
import '../auth/auth.dart';
import 'annotations_controller.dart';
import 'ink.dart';

part 'stroke_outbox.g.dart';

/// A note change waiting for the server.
sealed class StrokeOp {
  const StrokeOp(this.sessionId);
  final int sessionId;

  static const _stroke = 'stroke', _erase = 'erase';

  String get kind => switch (this) {
    SaveStroke() => _stroke,
    EraseStroke() => _erase,
  };

  Map<String, Object?> toJson() => switch (this) {
    SaveStroke(:final stroke) => stroke.toRow(),
    EraseStroke(:final strokeId, :final at) => {'id': strokeId, 'deleted_at': at?.toUtc().toIso8601String()},
  };

  static StrokeOp? decode(int sessionId, String kind, String payload) {
    final json = jsonDecode(payload) as Map<String, dynamic>;
    return switch (kind) {
      _stroke => SaveStroke(InkStroke.fromRow(json)),
      _erase => EraseStroke(
        sessionId,
        json['id'] as String,
        json['deleted_at'] == null ? null : DateTime.parse(json['deleted_at'] as String),
      ),
      _ => null,
    };
  }

  /// Applies this change to a session's strokes, as the server will.
  void applyTo(Map<String, InkStroke> strokes) {
    switch (this) {
      case SaveStroke(:final stroke):
        // The server's copy wins if it has the stroke already (a leader may
        // have erased it meanwhile).
        strokes.putIfAbsent(stroke.id, () => stroke);
      case EraseStroke(:final strokeId, :final at):
        final stroke = strokes[strokeId];
        if (stroke != null) strokes[strokeId] = stroke.withDeletedAt(at);
    }
  }
}

class SaveStroke extends StrokeOp {
  SaveStroke(this.stroke) : super(stroke.sessionId);
  final InkStroke stroke;
}

class EraseStroke extends StrokeOp {
  const EraseStroke(super.sessionId, this.strokeId, this.at);
  final String strokeId;
  final DateTime? at;
}

class _Queued {
  _Queued(this.op, this.seq);
  final StrokeOp op;

  /// Row in the device's outbox; null if it could not be stored there.
  final int? seq;
}

/// Note changes that have not reached the server yet, oldest first.
///
/// Kept on the device, so notes drawn without a connection survive a
/// restart and go up once the server is reachable. Strokes are immutable
/// with ids made on the device, so sending one twice changes nothing. A
/// change the server refuses (for example, its author left the team) can
/// never succeed and is dropped; a change that fails for want of a
/// connection waits for the connection to come back.
///
/// The state is the number of changes waiting.
@Riverpod(keepAlive: true)
class StrokeOutbox extends _$StrokeOutbox {
  final _queue = <_Queued>[];
  Future<void>? _loading;
  bool _draining = false;
  Timer? _retry;

  @override
  int build() {
    final owner = ref.watch(currentUserIdProvider);
    ref.listen(onlineStatusProvider.select((s) => s.epoch), (_, _) => _drain());
    ref.onDispose(() => _retry?.cancel());
    _queue.clear();
    _loading = owner == null ? null : _load(owner);
    return 0;
  }

  Future<void> _load(String owner) async {
    final stored = await ref.read(offlineStoreProvider).pending(owner);
    for (final row in stored) {
      final op = StrokeOp.decode(row.sessionId, row.kind, row.payload);
      if (op != null) _queue.add(_Queued(op, row.seq));
    }
    state = _queue.length;
    unawaited(_drain());
  }

  /// Changes for [sessionId] still on their way, oldest first.
  Future<List<StrokeOp>> pendingFor(int sessionId) async {
    await _loading;
    return [
      for (final q in _queue)
        if (q.op.sessionId == sessionId) q.op,
    ];
  }

  Future<void> add(StrokeOp op) async {
    await _loading;
    final owner = ref.read(currentUserIdProvider);
    if (owner == null) return;
    int? seq;
    try {
      seq = await ref.read(offlineStoreProvider).enqueue(owner, op.sessionId, op.kind, op.toJson());
    } catch (e) {
      // No local storage (e.g. a browser that blocks it): still send it.
      debugPrint('outbox: kept in memory only: $e');
    }
    _queue.add(_Queued(op, seq));
    state = _queue.length;
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    _retry?.cancel();
    final repo = ref.read(annotationsRepositoryProvider);
    final store = ref.read(offlineStoreProvider);
    try {
      while (_queue.isNotEmpty) {
        final next = _queue.first;
        try {
          await switch (next.op) {
            SaveStroke(:final stroke) => repo.save(stroke),
            EraseStroke(:final strokeId, :final at) => repo.setDeleted(strokeId, at),
          };
        } catch (e) {
          if (!refusedForGood(e)) {
            // No connection, an expired sign-in being renewed, a server
            // hiccup: try again when the server is back, or in a while.
            _retry = Timer(const Duration(seconds: 30), _drain);
            return;
          }
          debugPrint('outbox: server refused a note change, dropped: $e');
        }
        _queue.removeAt(0);
        if (next.seq != null) await store.done(next.seq!);
        state = _queue.length;
      }
    } finally {
      _draining = false;
    }
  }
}

/// Whether the server turned a change down for good: its rules refused it
/// (42501) or what it points at is gone (23503). Sign-in problems (PGRST3xx,
/// fixed by the token refresh), server errors (5xx), timeouts (408) and rate
/// limits (429) are worth retrying, and so is anything that is not a
/// database answer at all.
@visibleForTesting
bool refusedForGood(Object error) {
  if (error is! PostgrestException || isOfflineError(error)) return false;
  final code = error.code ?? '';
  return !code.startsWith('PGRST3') && !RegExp(r'^(5\d\d|408|429)$').hasMatch(code);
}
