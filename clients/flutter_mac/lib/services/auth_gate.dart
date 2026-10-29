/// Paths that the Octop API serves without a JWT.
bool isPublicApiPath(String path) {
  final bare = _bare(path);
  const exact = <String>{
    '/api/health',
    '/api/auth/login',
    '/api/auth/captcha',
    '/api/docs',
    '/api/openapi.json',
  };
  if (exact.contains(bare)) return true;
  return bare.startsWith('/api/setup/');
}

/// Block authenticated calls when no access token is present.
void ensureAuthenticated(String path, String? token) {
  if (isPublicApiPath(path)) return;
  if (token == null || token.trim().isEmpty) {
    throw const UnauthenticatedException();
  }
}

String _bare(String path) {
  final noQuery = path.split('?').first;
  if (noQuery.length > 1 && noQuery.endsWith('/')) {
    return noQuery.substring(0, noQuery.length - 1);
  }
  return noQuery;
}

class UnauthenticatedException implements Exception {
  const UnauthenticatedException();

  @override
  String toString() => '未登录';
}
