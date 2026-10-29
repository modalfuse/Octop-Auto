/// Normalize a user-entered Octop origin.
///
/// Accepts `host:port` and full `http`/`https` URLs. Returns an origin
/// without a trailing slash, or null when the value cannot be a base URL.
String? normalizeBaseUrl(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return null;
  if (!text.contains('://')) {
    text = 'http://$text';
  }
  final uri = Uri.tryParse(text);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty) return null;
  if (uri.userInfo.isNotEmpty) return null;
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '${uri.scheme}://${uri.host}$port';
}

/// Join [base] with an absolute API [path] such as `/api/health`.
Uri apiUri(String base, String path) {
  final origin = normalizeBaseUrl(base);
  if (origin == null) {
    throw FormatException('invalid base url');
  }
  final suffix = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$origin$suffix');
}

/// Dashboard chat socket: `WS /api/agents/{id}/chat/ws?token=`.
Uri chatWebSocketUri(String base, String agentId, String token) {
  final http =
      apiUri(base, '/api/agents/${Uri.encodeComponent(agentId)}/chat/ws');
  return Uri(
    scheme: http.scheme == 'https' ? 'wss' : 'ws',
    host: http.host,
    port: http.hasPort ? http.port : null,
    path: http.path,
    queryParameters: <String, String>{'token': token},
  );
}
