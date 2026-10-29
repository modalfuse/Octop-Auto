import 'package:flutter_test/flutter_test.dart';
import 'package:octop_auto_flutter/services/api_client.dart';
import 'package:octop_auto_flutter/services/auth_gate.dart';
import 'package:octop_auto_flutter/services/base_url.dart';

void main() {
  test('health and login are public; agents require a token', () {
    expect(isPublicApiPath('/api/health'), isTrue);
    expect(isPublicApiPath('/api/auth/login'), isTrue);
    expect(isPublicApiPath('/api/setup/status'), isTrue);
    expect(isPublicApiPath('/api/agents'), isFalse);
    expect(isPublicApiPath('/api/auth/me'), isFalse);

    expect(() => ensureAuthenticated('/api/health', null), returnsNormally);
    expect(
      () => ensureAuthenticated('/api/agents', null),
      throwsA(isA<UnauthenticatedException>()),
    );
    expect(
      () => ensureAuthenticated('/api/agents', '   '),
      throwsA(isA<UnauthenticatedException>()),
    );
    expect(() => ensureAuthenticated('/api/agents', 'jwt'), returnsNormally);
  });

  test('unauthenticated agent list never hits the network', () async {
    final transport = _RecordingTransport();
    final client = ApiClient(
      baseUrl: 'http://100.101.163.69:8088',
      transport: transport,
    );

    expect(client.listAgents(), throwsA(isA<UnauthenticatedException>()));
    expect(transport.calls, isEmpty);
  });

  test('authenticated calls send the bearer token and not a password',
      () async {
    final transport = _RecordingTransport(
      const ApiResponse(
          200, '[{"agent_id":"main","name":"小通","state":"running"}]'),
    );
    final client = ApiClient(
      baseUrl: 'http://100.101.163.69:8088/',
      transport: transport,
      token: 'jwt-1',
    );

    final agents = await client.listAgents();
    expect(agents.single.agentId, 'main');
    expect(transport.calls.single.headers['Authorization'], 'Bearer jwt-1');
    expect(transport.calls.single.uri,
        apiUri('http://100.101.163.69:8088', '/api/agents'));
    expect(transport.calls.single.body, isNull);
  });
}

class _RecordingTransport implements HttpTransport {
  _RecordingTransport([this.response = const ApiResponse(200, '{}')]);

  final ApiResponse response;
  final calls = <_Call>[];

  @override
  Future<ApiResponse> send(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    calls.add(_Call(method, uri, headers ?? const {}, body));
    return response;
  }
}

class _Call {
  _Call(this.method, this.uri, this.headers, this.body);

  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final String? body;
}
