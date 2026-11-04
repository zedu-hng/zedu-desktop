import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  group('SubscriptionTokenModel', () {
    test('parses a channel and token', () {
      final model = SubscriptionTokenModel.fromJson({
        'channel': 'channel-1',
        'token': 'abc.def.ghi',
      });

      expect(model.channel, 'channel-1');
      expect(model.token, 'abc.def.ghi');
    });

    test('falls back for missing fields', () {
      final model = SubscriptionTokenModel.fromJson(const {});

      expect(model.channel, isEmpty);
      expect(model.token, isEmpty);
    });

    test('round-trips through toJson', () {
      const original = SubscriptionTokenModel(
        channel: 'channel-1',
        token: 'abc.def.ghi',
      );

      final restored = SubscriptionTokenModel.fromJson(original.toJson());

      expect(restored.channel, original.channel);
      expect(restored.token, original.token);
    });
  });
}
