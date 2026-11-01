import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:praiseteam/core/http_client.dart';

void main() {
  const futureJwt = '{"code":"PGRST303","message":"JWT issued at future"}';

  test('repeats once, with the same body, after "JWT issued at future"', () async {
    final seen = <String>[];
    final client = ClockSkewRetryClient(MockClient((request) async {
      seen.add(request.body);
      return seen.length == 1 ? http.Response(futureJwt, 401) : http.Response('[]', 200);
    }));
    final response = await client.post(Uri.parse('http://x/rest/v1/rpc/create_team'), body: '{"p_name":"T"}');
    expect(response.statusCode, 200);
    expect(seen, ['{"p_name":"T"}', '{"p_name":"T"}']);
  });

  test('other 401s are returned untouched, without a retry', () async {
    var calls = 0;
    final client = ClockSkewRetryClient(MockClient((request) async {
      calls++;
      return http.Response('{"code":"PGRST301","message":"JWT expired"}', 401);
    }));
    final response = await client.get(Uri.parse('http://x/rest/v1/teams'));
    expect(calls, 1);
    expect(response.statusCode, 401);
    expect(jsonDecode(response.body)['code'], 'PGRST301');
  });

  test('gives up after one retry', () async {
    var calls = 0;
    final client = ClockSkewRetryClient(MockClient((request) async {
      calls++;
      return http.Response(futureJwt, 401);
    }));
    final response = await client.get(Uri.parse('http://x/rest/v1/teams'));
    expect(calls, 2);
    expect(response.statusCode, 401);
  });
}
