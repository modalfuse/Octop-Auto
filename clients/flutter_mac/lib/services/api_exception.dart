import 'dart:convert';

enum ApiFailureKind { unreachable, unauthorized, rejected }

class ApiException implements Exception {
  const ApiException(this.kind, this.message, {this.statusCode});

  final ApiFailureKind kind;
  final String message;
  final int? statusCode;

  factory ApiException.unreachable([String message = '服务不可达']) {
    return ApiException(ApiFailureKind.unreachable, message);
  }

  factory ApiException.unauthorized([String message = '未登录或登录已失效']) {
    return ApiException(ApiFailureKind.unauthorized, message, statusCode: 401);
  }

  bool get isUnauthorized => kind == ApiFailureKind.unauthorized;

  @override
  String toString() => message;
}

/// Pull a short message out of an Octop error envelope. Never returns the raw body.
String messageFromErrorBody(int statusCode, String body) {
  try {
    if (body.trim().isNotEmpty) {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message'] ?? decoded['detail'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
        if (message is List && message.isNotEmpty) {
          return message.first.toString();
        }
      }
    }
  } on FormatException {
    // Fall through to a status-only message.
  }
  if (statusCode == 401) return '未登录或登录已失效';
  return '请求失败（$statusCode）';
}
