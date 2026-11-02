import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/offline/offline_store.dart';
import 'demo_seed.dart';
import 'demo_store.dart';

/// Production has no route to this client. Every request terminates locally,
/// including Auth, Storage and Realtime. No real key or account is involved.
class DemoClient extends SupabaseClient {
  DemoClient(this.store, OfflineStore offline)
    : super(
        'https://demo.praiseteam.invalid',
        'demo-public-key',
        httpClient: DemoHttpClient(store, offline),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

  final DemoStore store;
  final _channels = <DemoChannel>[];

  Future<void> start() async => auth.setSession('browser-demo-session');

  @override
  RealtimeChannel channel(
    String name, {
    RealtimeChannelConfig opts = const RealtimeChannelConfig(),
  }) {
    final channel = DemoChannel(name, realtime, store);
    _channels.add(channel);
    return channel;
  }

  @override
  List<RealtimeChannel> getChannels() =>
      List.unmodifiable(_channels.where((c) => c.active));

  @override
  Future<String> removeChannel(RealtimeChannel channel) async {
    _channels.remove(channel);
    return channel.unsubscribe();
  }

  @override
  Future<List<String>> removeAllChannels() async {
    final channels = _channels.toList();
    _channels.clear();
    return Future.wait(channels.map((c) => c.unsubscribe()));
  }

  @override
  Future<void> dispose() async {
    await removeAllChannels();
    await store.changes.close();
    await super.dispose();
  }
}

class DemoHttpClient extends http.BaseClient {
  DemoHttpClient(this.store, this.offline);
  final DemoStore store;
  final OfflineStore offline;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.host != 'demo.praiseteam.invalid') {
      throw http.ClientException(
        'Demo request cannot leave the browser',
        request.url,
      );
    }
    final headers = {
      for (final e in request.headers.entries) e.key.toLowerCase(): e.value,
    };
    final raw = request is http.MultipartRequest && request.files.isNotEmpty
        ? await request.files.first.finalize().toBytes()
        : await request.finalize().toBytes();
    final path = request.url.pathSegments;
    http.StreamedResponse result(
      Object? value, {
      int status = 200,
      int? count,
    }) => http.StreamedResponse(
      Stream.value(
        request.method == 'HEAD' ? <int>[] : utf8.encode(jsonEncode(value)),
      ),
      status,
      headers: {
        'content-type': 'application/json',
        if (count != null)
          'content-range': '0-${count == 0 ? 0 : count - 1}/$count',
      },
      request: request,
    );
    try {
      if (path.firstOrNull == 'auth') {
        if (path.last == 'logout') return result(null, status: 204);
        if (path.last == 'user') return result(_user());
        return result(_session());
      }
      if (path.firstOrNull == 'storage') {
        final bucket = path.indexOf('sheets');
        if (bucket < 0) {
          return result({'message': 'Unknown demo bucket'}, status: 404);
        }
        final filePath = path.skip(bucket + 1).join('/');
        if (request.method == 'GET') {
          var bytes = await offline.file(filePath);
          if (bytes == null &&
              RegExp(r'^\d+/demo-chart-[123]\.pdf$').hasMatch(filePath)) {
            bytes = (await rootBundle.load(
              'assets/demo/${filePath.split('/').last}',
            )).buffer.asUint8List();
          }
          if (bytes == null) {
            return result({'message': 'File not found'}, status: 404);
          }
          return http.StreamedResponse(
            Stream.value(bytes),
            200,
            headers: {'content-type': 'application/pdf'},
            request: request,
          );
        }
        if (request.method == 'DELETE') return result([]);
        await offline.saveFile(filePath, Uint8List.fromList(raw));
        return result({'Key': 'sheets/$filePath', 'Id': filePath}, status: 200);
      }
      if (path.length < 3 || path[0] != 'rest' || path[1] != 'v1') {
        return result({'message': 'Unknown demo endpoint'}, status: 404);
      }
      final body = raw.isEmpty ? null : jsonDecode(utf8.decode(raw));
      if (path[2] == 'rpc') {
        final value = store.rpc(path[3], body is Map ? DemoRow.from(body) : {});
        return result(value, status: value == null ? 204 : 200);
      }
      final table = path[2], query = request.url.queryParameters;
      List<DemoRow> rows;
      switch (request.method) {
        case 'GET' || 'HEAD':
          rows = store.read(
            table,
            query,
            allQuery: request.url.queryParametersAll,
          );
        case 'POST':
          final values = body is List ? body : [body];
          rows = [
            for (final value in values)
              store.hydrate(
                table,
                store.insert(
                  table,
                  DemoRow.from(value as Map),
                  conflict: query['on_conflict'],
                  ignoreDuplicates:
                      headers['prefer']?.contains('ignore-duplicates') ?? false,
                ),
              ),
          ];
        case 'PATCH':
          final targets = store
              .rows(table)
              .where((r) => DemoStore.matches(store.hydrate(table, r), query))
              .toList();
          for (final r in targets) {
            store.update(table, r, DemoRow.from(body as Map));
          }
          rows = [for (final r in targets) store.hydrate(table, r)];
        case 'DELETE':
          final targets = store
              .rows(table)
              .where((r) => DemoStore.matches(store.hydrate(table, r), query))
              .toList();
          for (final r in targets) {
            store.delete(table, r);
          }
          rows = [];
        default:
          return result({'message': 'Unsupported demo method'}, status: 405);
      }
      if (headers['accept']?.contains('vnd.pgrst.object') ?? false) {
        if (rows.length != 1) {
          return result({
            'code': 'PGRST116',
            'message': 'Expected a single row',
            'details': 'The result contains ${rows.length} rows',
            'hint': null,
          }, status: 406);
        }
        return result(rows.single);
      }
      return result(
        rows,
        count: rows.length,
        status: request.method == 'POST' ? 201 : 200,
      );
    } on DemoFailure catch (e) {
      return result({
        'code': e.code,
        'message': e.message,
        'details': null,
        'hint': null,
      }, status: e.status);
    }
  }

  Map<String, dynamic> _user() => {
    'id': store.userId,
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'demo@example.invalid',
    'created_at': store.timestamp,
    'email_confirmed_at': store.timestamp,
    'app_metadata': {
      'provider': 'email',
      'providers': ['email'],
    },
    'user_metadata': {
      'full_name': store.row('profiles', store.userId)?['display_name'] ?? '데모',
    },
  };

  Map<String, dynamic> _session() {
    final expires =
        DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + 86400;
    String encode(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    // This deliberately invalid signature is only a client-side demo token.
    final jwt =
        '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode({'sub': store.userId, 'role': 'authenticated', 'exp': expires})}.browser_demo_not_a_real_signature';
    return {
      'access_token': jwt,
      'refresh_token': 'browser-demo-session',
      'token_type': 'bearer',
      'expires_in': 86400,
      'expires_at': expires,
      'user': _user(),
    };
  }
}

/// Only one local participant. Real cross-device sync is shown separately in
/// the product video; the demo must never pretend mock people are connected.
class DemoChannel extends RealtimeChannel {
  DemoChannel(super.topic, super.socket, this.store);
  final DemoStore store;
  bool active = false;
  StreamSubscription<DemoChange>? _subscription;
  final _database =
      <
        ({
          PostgresChangeEvent event,
          String? table,
          PostgresChangeFilter? filter,
          void Function(PostgresChangePayload) callback,
        })
      >[];
  final _presence = <void Function(RealtimePresenceSyncPayload)>[];
  Map<String, dynamic>? _tracked;

  @override
  RealtimeChannel onPostgresChanges({
    required PostgresChangeEvent event,
    String? schema,
    String? table,
    PostgresChangeFilter? filter,
    List<PostgresChangeFilter>? filters,
    List<String>? select,
    required void Function(PostgresChangePayload) callback,
  }) {
    _database.add((
      event: event,
      table: table,
      filter: filter,
      callback: callback,
    ));
    return this;
  }

  @override
  RealtimeChannel onBroadcast({
    required String event,
    required void Function(Map<String, dynamic>) callback,
  }) => this;

  @override
  RealtimeChannel onPresenceSync(
    void Function(RealtimePresenceSyncPayload) callback,
  ) {
    _presence.add(callback);
    return this;
  }

  @override
  RealtimeChannel subscribe([
    void Function(RealtimeSubscribeStatus, Object?)? callback,
    Duration? timeout,
  ]) {
    active = true;
    _subscription = store.changes.stream.listen((change) {
      if (!active) return;
      final event = PostgresChangeEvent.values.firstWhere(
        (e) => e.name == change.kind,
      );
      for (final binding in _database) {
        if (binding.table != change.table ||
            binding.event != PostgresChangeEvent.all &&
                binding.event != event) {
          continue;
        }
        final filter = binding.filter;
        final row = change.row.isEmpty ? change.before : change.row;
        if (filter != null && '${row[filter.column]}' != '${filter.value}') {
          continue;
        }
        binding.callback(
          PostgresChangePayload(
            schema: 'public',
            table: change.table,
            commitTimestamp: DateTime.now(),
            eventType: event,
            newRecord: change.row,
            oldRecord: change.before,
            errors: null,
          ),
        );
      }
    });
    scheduleMicrotask(
      () => active
          ? callback?.call(RealtimeSubscribeStatus.subscribed, null)
          : null,
    );
    return this;
  }

  @override
  List<SinglePresenceState> presenceState() => _tracked == null
      ? []
      : [
          SinglePresenceState(
            key: store.userId,
            presences: [Presence(presenceRef: 'demo', payload: _tracked!)],
          ),
        ];

  @override
  Future<ChannelResponse> track(
    Map<String, dynamic> payload, [
    Map<String, dynamic> opts = const {},
  ]) async {
    _tracked = payload;
    for (final callback in _presence) {
      if (active) {
        callback(const RealtimePresenceSyncPayload(event: PresenceEvent.sync));
      }
    }
    return ChannelResponse.ok;
  }

  @override
  Future<ChannelResponse> sendBroadcastMessage({
    required String event,
    required Map<String, dynamic> payload,
  }) async => ChannelResponse.ok;

  @override
  Future<String> unsubscribe([Duration? timeout]) async {
    active = false;
    _tracked = null;
    await _subscription?.cancel();
    return 'ok';
  }
}
