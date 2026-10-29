import 'package:flutter_test/flutter_test.dart';
import 'package:octop_auto_flutter/config/defaults.dart';
import 'package:octop_auto_flutter/services/base_url.dart';

void main() {
  test('default base url is the hp02 tailscale address', () {
    expect(normalizeBaseUrl(kDefaultBaseUrl), kDefaultBaseUrl);
  });

  test('strips trailing slash and adds http when scheme is missing', () {
    expect(
      normalizeBaseUrl('  100.101.163.69:8088/  '),
      'http://100.101.163.69:8088',
    );
    expect(
      normalizeBaseUrl('https://example.com/'),
      'https://example.com',
    );
  });

  test('rejects empty, unsupported schemes, and missing hosts', () {
    expect(normalizeBaseUrl(''), isNull);
    expect(normalizeBaseUrl('   '), isNull);
    expect(normalizeBaseUrl('ftp://100.101.163.69'), isNull);
    expect(normalizeBaseUrl('http://'), isNull);
    expect(normalizeBaseUrl('http://user:pass@host'), isNull);
  });

  test('chat websocket upgrades http to ws and keeps the port', () {
    final uri = chatWebSocketUri(
      'http://100.101.163.69:8088',
      'main',
      'token-value',
    );
    expect(uri.scheme, 'ws');
    expect(uri.host, '100.101.163.69');
    expect(uri.port, 8088);
    expect(uri.path, '/api/agents/main/chat/ws');
    expect(uri.queryParameters['token'], 'token-value');
  });

  test('https becomes wss', () {
    final uri = chatWebSocketUri('https://octop.example', 'a b', 't');
    expect(uri.scheme, 'wss');
    expect(uri.path, '/api/agents/a%20b/chat/ws');
  });
}
