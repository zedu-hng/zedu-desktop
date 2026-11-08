class CreditsPaymentDeepLinkParser {
  const CreditsPaymentDeepLinkParser._();

  /// Dummy redirect URI — replace when backend confirms production URL.
  static const dummySuccessUri =
      'zedu://credits/payment-success?session_id=cs_test_placeholder';

  /// Documented trusted web callback hosts (staging & production).
  static const Set<String> defaultTrustedHosts = {
    'zedu.chat',
    'staging.zedu.chat',
    'api.zedu.chat',
    'api.staging.zedu.chat',
  };

  static String? extractSessionId(
    Uri uri, {
    Set<String> allowedHosts = defaultTrustedHosts,
  }) {
    if (!_isSupportedPaymentUri(uri, allowedHosts: allowedHosts)) return null;
    final sessionId = uri.queryParameters['session_id']?.trim();
    if (sessionId == null || sessionId.isEmpty) return null;
    return sessionId;
  }

  static bool _isSupportedPaymentUri(
    Uri uri, {
    required Set<String> allowedHosts,
  }) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final path = _normalizePath(uri.path);

    if (scheme == 'zedu' && host == 'credits' && path == '/payment-success') {
      return true;
    }

    if ((scheme == 'https' || scheme == 'http') &&
        allowedHosts.contains(host) &&
        (path == '/credits/payment-success' ||
            path.endsWith('/credits/payment-success'))) {
      return true;
    }

    return false;
  }

  static String _normalizePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '/';
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }
}
