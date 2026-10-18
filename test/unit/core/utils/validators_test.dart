import 'package:zedu/core/core.dart';

import '../../../helpers/helpers.dart';

class _MockBuildContext extends Mock implements BuildContext {}

void main() {
  late BuildContext context;

  setUp(() {
    context = _MockBuildContext();
  });

  group('Validators.validateEmail', () {
    test('accepts a valid email', () {
      expect(Validators.validateEmail(context, 'user@zedu.chat'), isNull);
    });

    test('accepts a valid email with surrounding whitespace', () {
      expect(Validators.validateEmail(context, '  user@zedu.chat '), isNull);
    });

    test('requires an email when the value is only whitespace', () {
      expect(Validators.validateEmail(context, '   '), 'Email is required');
    });

    test('requires an email when the value is null', () {
      expect(Validators.validateEmail(context, null), 'Email is required');
    });

    test('rejects an invalid email', () {
      expect(
        Validators.validateEmail(context, 'not-an-email'),
        'Please enter a valid email',
      );
    });
  });
}
