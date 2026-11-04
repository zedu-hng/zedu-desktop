class MagicLinkDeepLinkParser {
  const MagicLinkDeepLinkParser._();

  /// The product domain whose links the app will act on. The web app and its
  /// subdomains (`app.zedu.chat`, `api.staging.zedu.chat`, ...) are trusted;
  /// any other host is ignored, so a hostile page cannot hand the app a token.
  static const String _trustedDomain = 'zedu.chat';

  static String? extractToken(Uri uri) {
    if (!_isSupportedMagicLinkUri(uri)) return null;
    final token = uri.queryParameters['token']?.trim();
    if (token == null || token.isEmpty) return null;
    return token;
  }

  static bool _isSupportedMagicLinkUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final path = _normalizePath(uri.path);

    if (scheme == 'zedu' && host == 'auth' && path == '/magick-link/verify') {
      return true;
    }

    if ((scheme == 'https' || scheme == 'http') &&
        _isTrustedHost(host) &&
        path.endsWith('/auth/magick-link/verify')) {
      return true;
    }

    return false;
  }

  static bool _isTrustedHost(String host) {
    return host == _trustedDomain || host.endsWith('.$_trustedDomain');
  }

  static String _normalizePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '/';
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }
}
