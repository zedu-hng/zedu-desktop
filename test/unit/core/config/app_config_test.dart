import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  group('AppConfig connectUrl', () {
    setUpAll(() {
      // Mirror an empty/absent `.env` value so fromEnvironment can read
      // dotenv keys and still fall through to the built-in default.
      dotenv.loadFromString(envString: 'CONNECT_URL=');
    });

    test('defaults to the staging Centrifugo websocket', () {
      const direct = AppConfig(
        apiBaseUrl: 'https://example.com/',
        usesMockData: false,
      );

      expect(direct.connectUrl, kDefaultConnectUrl);
      expect(
        AppConfig.fromEnvironment().connectUrl,
        direct.connectUrl,
        reason:
            'AppConfig() and AppConfig.fromEnvironment() must resolve to the '
            'same default Centrifugo websocket',
      );
    });

    test('accepts a custom connectUrl', () {
      const custom = AppConfig(
        apiBaseUrl: 'https://example.com/',
        usesMockData: false,
        connectUrl: 'wss://connect.example.com/connection/websocket',
      );

      expect(
        custom.connectUrl,
        'wss://connect.example.com/connection/websocket',
      );
    });

    test('reads CONNECT_URL from dotenv', () {
      dotenv.loadFromString(
        envString: 'CONNECT_URL=wss://dotenv.example/connection/websocket',
      );

      expect(
        AppConfig.fromEnvironment().connectUrl,
        'wss://dotenv.example/connection/websocket',
      );
    });
  });
}
