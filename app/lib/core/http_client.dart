import 'dart:convert';

import 'package:http/http.dart' as http;

/// HTTP client for Supabase that repeats a request once when PostgREST
/// rejects a just-issued token as "JWT issued at future" (PGRST303).
///
/// PostgREST validates `iat` against an internally cached clock, so a
/// token used within the same second it was issued (right after sign-in)
/// can be refused even though the server's own Date header matches the
/// token's `iat` (measured in the E2E run). The request was rejected
/// before it executed, so sending it again after the clock has ticked is
/// safe for every method. Nothing else is retried.
class ClockSkewRetryClient extends http.BaseClient {
  ClockSkewRetryClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;
  static const _wait = Duration(milliseconds: 1100);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Only plain requests can be replayed (their body is in memory).
    final replay = request is http.Request ? _copy(request) : null;
    final response = await _inner.send(request);
    if (response.statusCode != 401 || replay == null) return response;

    final bytes = await response.stream.toBytes();
    if (!utf8.decode(bytes, allowMalformed: true).contains('PGRST303')) {
      return http.StreamedResponse(
        Stream.value(bytes),
        response.statusCode,
        contentLength: bytes.length,
        request: response.request,
        headers: response.headers,
        reasonPhrase: response.reasonPhrase,
      );
    }
    await Future<void>.delayed(_wait);
    return _inner.send(replay);
  }

  static http.Request _copy(http.Request original) => http.Request(original.method, original.url)
    ..headers.addAll(original.headers)
    ..followRedirects = original.followRedirects
    ..maxRedirects = original.maxRedirects
    ..persistentConnection = original.persistentConnection
    ..bodyBytes = original.bodyBytes;

  @override
  void close() => _inner.close();
}
