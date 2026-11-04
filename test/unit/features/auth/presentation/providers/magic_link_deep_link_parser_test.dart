import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('MagicLinkDeepLinkParser', () {
    test('extracts token from custom zedu scheme link', () {
      final uri = Uri.parse('zedu://auth/magick-link/verify?token=abc123');

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, 'abc123');
    });

    test('extracts token from https auth link', () {
      final uri = Uri.parse(
        'https://api.staging.zedu.chat/auth/magick-link/verify?token=abc123',
      );

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, 'abc123');
    });

    test('returns null for missing token query parameter', () {
      final uri = Uri.parse('zedu://auth/magick-link/verify');

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, isNull);
    });

    test('returns null for unsupported path', () {
      final uri = Uri.parse('zedu://auth/magick-link?token=abc123');

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, isNull);
    });

    test('extracts token from a trusted subdomain', () {
      final uri = Uri.parse(
        'https://app.zedu.chat/auth/magick-link/verify?token=abc123',
      );

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, 'abc123');
    });

    test('rejects a link from an unrelated host', () {
      final uri = Uri.parse(
        'https://evil.example/auth/magick-link/verify?token=abc123',
      );

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, isNull);
    });

    test('rejects a lookalike host that only ends with the domain', () {
      final uri = Uri.parse(
        'https://zedu.chat.evil.example/auth/magick-link/verify?token=abc123',
      );

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, isNull);
    });

    test('rejects a link whose host is empty', () {
      final uri = Uri.parse('/auth/magick-link/verify?token=abc123');

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, isNull);
    });
  });
}
