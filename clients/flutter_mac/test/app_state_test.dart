import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:octop_auto_flutter/config/defaults.dart';
import 'package:octop_auto_flutter/services/api_client.dart';
import 'package:octop_auto_flutter/services/chat_frames.dart';
import 'package:octop_auto_flutter/services/credential_store.dart';
import 'package:octop_auto_flutter/services/project_repository.dart';
import 'package:octop_auto_flutter/state/app_state.dart';

void main() {
  test('token frames append text and done finishes the turn', () {
    const start = ChatTurnState();
    final afterToken = start.apply({'type': 'token', 'content': '你'});
    final afterMore = afterToken.apply({'type': 'token', 'content': '好'});
    final started = afterMore.apply({
      'type': 'turn.started',
      'thread_id': 'thr_1',
    });
    final done = started.apply({'type': 'done'});

    expect(done.assistantText, '你好');
    expect(done.done, isTrue);
    expect(done.threadId, 'thr_1');
    expect(done.error, isNull);
  });

  test('error frames stay readable', () {
    final state = const ChatTurnState().apply({
      'type': 'error',
      'message': '模型失败',
    });
    expect(state.error, '模型失败');
  });

  test('login stores the token and never the password', () async {
    const password = 's3cret-value';
    final store = MemoryCredentialStore();
    final transport = _ScriptedTransport({
      '/api/auth/login': const ApiResponse(
        200,
        '{"access_token":"jwt-1","user":{"id":1,"username":"admin","role":"admin","locale":"zh"}}',
      ),
      '/api/agents': const ApiResponse(
        200,
        '[{"agent_id":"main","name":"小通","state":"running"}]',
      ),
      '/api/agents/main/threads': const ApiResponse(200, '[]'),
    });
    final state = AppState(store: store, transport: transport);
    await state.load();
    await state.confirmBaseUrl(kDefaultBaseUrl);

    final ok = await state.login('admin', password);

    expect(ok, isTrue);
    expect(state.isAuthenticated, isTrue);
    expect(store.values['octop.access_token'], 'jwt-1');
    expect(store.values.values.join('\n').contains(password), isFalse);
    expect(state.selectedAgent?.name, '小通');
    final login = transport.calls
        .firstWhere((call) => call.uri.path == '/api/auth/login');
    expect(jsonDecode(login.body!)['password'], password);
  });

  test('project space is local and survives a reload', () async {
    final store = MemoryCredentialStore();
    final repo = ProjectRepository(store);
    final created = await repo.create('论文');
    expect(created.projects.single.name, '论文');
    expect(created.activeId, created.projects.single.id);

    final reloaded = await repo.load();
    expect(reloaded.projects.single.name, '论文');
    final collapsed = await repo.setCollapsed(true);
    expect(collapsed.collapsed, isTrue);
    final removed = await repo.delete(created.projects.single.id);
    expect(removed.projects, isEmpty);
    expect(removed.activeId, isNull);
  });
}

class _ScriptedTransport implements HttpTransport {
  _ScriptedTransport(this.routes);

  final Map<String, ApiResponse> routes;
  final calls = <_Call>[];

  @override
  Future<ApiResponse> send(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    calls.add(_Call(method, uri, body));
    return routes[uri.path] ?? const ApiResponse(404, '{"message":"missing"}');
  }
}

class _Call {
  _Call(this.method, this.uri, this.body);

  final String method;
  final Uri uri;
  final String? body;
}
