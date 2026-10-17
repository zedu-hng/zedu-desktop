import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class FakeUserProfileNotifier extends UserProfileNotifier {
  @override
  UserProfileState build() => const UserProfileState();

  @override
  Future<List<Map<String, dynamic>>> fetchRegisteredUsers() async => [];
}

void main() {
  testWidgets(
    'InviteTeammatesModal renders clean hint text without stray pipe character',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileNotifierProvider.overrideWith(
              FakeUserProfileNotifier.new,
            ),
          ],
          child: buildTestMaterialApp(const InviteTeammatesModal()),
        ),
      );
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, 'Enter name or email');
      expect(textField.decoration?.hintText?.contains('|'), isFalse);
    },
  );
}
