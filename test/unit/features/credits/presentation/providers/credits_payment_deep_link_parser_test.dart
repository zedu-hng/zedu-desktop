import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('CreditsPaymentDeepLinkParser', () {
    test('extracts session ID from custom zedu scheme link', () {
      final uri = Uri.parse(
        'zedu://credits/payment-success?session_id=cs_test_custom_scheme',
      );

      final sessionId = CreditsPaymentDeepLinkParser.extractSessionId(uri);

      expect(sessionId, 'cs_test_custom_scheme');
    });

    test('extracts session ID from trusted staging host', () {
      final uri = Uri.parse(
        'https://staging.zedu.chat/credits/payment-success?session_id=cs_test_staging',
      );

      final sessionId = CreditsPaymentDeepLinkParser.extractSessionId(uri);

      expect(sessionId, 'cs_test_staging');
    });

    test('extracts session ID from trusted production host', () {
      final uri = Uri.parse(
        'https://zedu.chat/credits/payment-success?session_id=cs_test_prod',
      );

      final sessionId = CreditsPaymentDeepLinkParser.extractSessionId(uri);

      expect(sessionId, 'cs_test_prod');
    });

    test('extracts session ID from trusted API staging host', () {
      final uri = Uri.parse(
        'https://api.staging.zedu.chat/api/v1/credits/payment-success?session_id=cs_test_api',
      );

      final sessionId = CreditsPaymentDeepLinkParser.extractSessionId(uri);

      expect(sessionId, 'cs_test_api');
    });

    test('rejects arbitrary untrusted host with valid payment path', () {
      final uri = Uri.parse(
        'https://evil.com/credits/payment-success?session_id=cs_test_attacker',
      );

      final sessionId = CreditsPaymentDeepLinkParser.extractSessionId(uri);

      expect(sessionId, isNull);
    });

    test('rejects lookalike / suffix domain host', () {
      final uri = Uri.parse(
        'https://fake-zedu.chat/credits/payment-success?session_id=cs_test_fake',
      );

      final sessionId = CreditsPaymentDeepLinkParser.extractSessionId(uri);

      expect(sessionId, isNull);
    });

    test('rejects subdomain on untrusted host', () {
      final uri = Uri.parse(
        'https://zedu.chat.attacker.com/credits/payment-success?session_id=cs_test_sub',
      );

      final sessionId = CreditsPaymentDeepLinkParser.extractSessionId(uri);

      expect(sessionId, isNull);
    });

    test('rejects unsupported schemes', () {
      final uri = Uri.parse(
        'ftp://zedu.chat/credits/payment-success?session_id=cs_test_ftp',
      );

      final sessionId = CreditsPaymentDeepLinkParser.extractSessionId(uri);

      expect(sessionId, isNull);
    });

    test('returns null when session_id query param is missing', () {
      final uri = Uri.parse(
        'https://staging.zedu.chat/credits/payment-success',
      );

      final sessionId = CreditsPaymentDeepLinkParser.extractSessionId(uri);

      expect(sessionId, isNull);
    });

    test('returns null when session_id query param is empty', () {
      final uri = Uri.parse(
        'https://staging.zedu.chat/credits/payment-success?session_id=   ',
      );

      final sessionId = CreditsPaymentDeepLinkParser.extractSessionId(uri);

      expect(sessionId, isNull);
    });

    test('returns null for unsupported path on trusted host', () {
      final uri = Uri.parse(
        'https://staging.zedu.chat/wrong/path?session_id=cs_test_123',
      );

      final sessionId = CreditsPaymentDeepLinkParser.extractSessionId(uri);

      expect(sessionId, isNull);
    });

    test('supports custom allowedHosts override', () {
      final uri = Uri.parse(
        'https://custom.internal.host/credits/payment-success?session_id=cs_custom',
      );

      expect(CreditsPaymentDeepLinkParser.extractSessionId(uri), isNull);

      final sessionId = CreditsPaymentDeepLinkParser.extractSessionId(
        uri,
        allowedHosts: {'custom.internal.host'},
      );

      expect(sessionId, 'cs_custom');
    });
  });
}

