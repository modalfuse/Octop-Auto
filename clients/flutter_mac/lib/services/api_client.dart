import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/agent.dart';
import '../models/message.dart';
import '../models/thread_summary.dart';
import '../models/user.dart';
import 'api_exception.dart';
import 'auth_gate.dart';
import 'base_url.dart';

class ApiResponse {
  const ApiResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

abstract class HttpTransport {
  Future<ApiResponse> send(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  });
}

class HttpTransportClient implements HttpTransport {
  HttpTransportClient([http.Client? client])
      : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<ApiResponse> send(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    try {
      final request = http.Request(method, uri);
      if (headers != null) request.headers.addAll(headers);
      if (body != null) request.body = body;
      final streamed =
          await _client.send(request).timeout(const Duration(seconds: 20));
      final text = await streamed.stream.bytesToString();
      return ApiResponse(streamed.statusCode, text);
    } on SocketException {
      throw ApiException.unreachable();
    } on TimeoutException {
      throw ApiException.unreachable();
    } on http.ClientException {
      throw ApiException.unreachable();
    } on HttpException {
      throw ApiException.unreachable();
    }
  }
}

class HealthReport {
  const HealthReport({required this.status, this.version});

  final String status;
  final String? version;
}

class LoginSession {
  const LoginSession({required this.token, required this.user});

  final String token;
  final User user;
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.transport,
    this.token,
  });

  String baseUrl;
  String? token;
  final HttpTransport transport;

  Future<HealthReport> health() async {
    final response = await _request('GET', '/api/health');
    final decoded = _jsonMap(response.body);
    return HealthReport(
      status: decoded['status'] as String? ?? 'ok',
      version: decoded['version'] as String?,
    );
  }

  Future<LoginSession> login({
    required String username,
    required String password,
  }) async {
    final response = await _request(
      'POST',
      '/api/auth/login',
      jsonBody: <String, String>{'username': username, 'password': password},
    );
    final decoded = _jsonMap(response.body);
    final accessToken = decoded['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const ApiException(ApiFailureKind.rejected, '登录响应缺少令牌');
    }
    token = accessToken;
    final rawUser = decoded['user'];
    final user = rawUser is Map
        ? User.fromJson(Map<String, dynamic>.from(rawUser))
        : await me();
    return LoginSession(token: accessToken, user: user);
  }

  Future<User> me() async {
    final response = await _request('GET', '/api/auth/me');
    return User.fromJson(_jsonMap(response.body));
  }

  Future<void> logout() async {
    await _request('POST', '/api/auth/logout');
  }

  Future<List<Agent>> listAgents() async {
    final response = await _request('GET', '/api/agents');
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map) Agent.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  Future<List<ThreadSummary>> listThreads(String agentId) async {
    final response = await _request(
      'GET',
      '/api/agents/${Uri.encodeComponent(agentId)}/threads',
    );
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map)
          ThreadSummary.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  Future<String> createThread(String agentId) async {
    final response = await _request(
      'POST',
      '/api/agents/${Uri.encodeComponent(agentId)}/threads',
      jsonBody: const <String, String>{},
    );
    final decoded = _jsonMap(response.body);
    final threadId = decoded['thread_id'];
    if (threadId is! String || threadId.isEmpty) {
      throw const ApiException(ApiFailureKind.rejected, '没有返回会话');
    }
    return threadId;
  }

  Future<List<ChatMessage>> history(String agentId, String threadId) async {
    final response = await _request(
      'GET',
      '/api/agents/${Uri.encodeComponent(agentId)}/threads/${Uri.encodeComponent(threadId)}/history',
    );
    final decoded = _jsonMap(response.body);
    final raw = decoded['messages'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) ChatMessage.fromJson(Map<String, dynamic>.from(item)),
    ].where((message) => message.content.trim().isNotEmpty).toList();
  }

  Future<ApiResponse> _request(
    String method,
    String path, {
    Object? jsonBody,
  }) async {
    ensureAuthenticated(path, token);
    final headers = <String, String>{'Accept': 'application/json'};
    if (token != null && token!.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (jsonBody != null) {
      headers['Content-Type'] = 'application/json';
    }
    final ApiResponse response;
    try {
      response = await transport.send(
        method,
        apiUri(baseUrl, path),
        headers: headers,
        body: jsonBody == null ? null : jsonEncode(jsonBody),
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.unreachable();
    }
    if (response.statusCode == 401) {
      throw ApiException.unauthorized(messageFromErrorBody(401, response.body));
    }
    if (response.statusCode >= 400) {
      throw ApiException(
        ApiFailureKind.rejected,
        messageFromErrorBody(response.statusCode, response.body),
        statusCode: response.statusCode,
      );
    }
    return response;
  }

  Map<String, dynamic> _jsonMap(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const ApiException(ApiFailureKind.rejected, '响应格式无法识别');
  }
}
