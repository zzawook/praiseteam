import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// True when a request failed because the server could not be reached
/// (no connection, DNS failure, no answer in time). Answers the server did
/// send, such as permission or validation errors, are not offline errors.
bool isOfflineError(Object error) => error is http.ClientException || error is TimeoutException;

/// Whether the backend is reachable, judged by what actually happens to
/// the app's requests rather than by the device's network state: a phone
/// on church wifi without internet counts as offline.
///
/// Any HTTP response means reachable; a request that fails without one
/// means unreachable. While unreachable, [probe] asks the server every few
/// seconds; [epoch] grows each time it comes back, so screens can refresh.
class Reachability extends ChangeNotifier {
  Reachability({this.probeEvery = const Duration(seconds: 10)});

  final Duration probeEvery;

  /// Sends one cheap request; set by [ReachabilityClient].
  Future<void> Function()? probe;

  bool _online = true;
  int _epoch = 0;
  Completer<void> _wentOffline = Completer<void>();
  Timer? _probing;

  bool get online => _online;
  int get epoch => _epoch;

  /// Completes when the server stops being reachable (at once if it
  /// already is not).
  Future<void> get wentOffline => _online ? _wentOffline.future : Future<void>.value();

  void reportResponse() {
    if (_online) return;
    _online = true;
    _epoch++;
    _wentOffline = Completer<void>();
    _probing?.cancel();
    _probing = null;
    notifyListeners();
  }

  void reportFailure() {
    if (!_online) return;
    _online = false;
    _wentOffline.complete();
    _probing = Timer.periodic(probeEvery, (_) => probe?.call().ignore());
    notifyListeners();
  }

  @override
  void dispose() {
    _probing?.cancel();
    super.dispose();
  }
}

/// Reports every request's outcome to [Reachability] and answers its
/// probes. Wraps the client Supabase uses for REST, storage and auth.
class ReachabilityClient extends http.BaseClient {
  ReachabilityClient(this._inner, this._reachability, {required Uri probeUrl}) {
    _reachability.probe = () async {
      final response = await send(http.Request('GET', probeUrl));
      await response.stream.drain<void>();
    };
  }

  final http.Client _inner;
  final Reachability _reachability;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      final response = await _inner.send(request);
      _reachability.reportResponse();
      return response;
    } on http.ClientException {
      _reachability.reportFailure();
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}
