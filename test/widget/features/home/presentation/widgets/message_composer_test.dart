import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _FakeUserProfileNotifier extends UserProfileNotifier {
  @override
  UserProfileState build() => const UserProfileState();
}

Widget buildComposerUnderTest({required ActiveChatState activeChat}) {
  return ProviderScope(
    overrides: [
      userProfileNotifierProvider.overrideWith(_FakeUserProfileNotifier.new),
    ],
    child: buildTestMaterialApp(
      Scaffold(
        body: MessageComposer(
          activeChat: activeChat,
          onSend: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  group('MessageComposer placeholder tests', () {
    testWidgets('displays channel placeholder for standard channel', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildComposerUnderTest(
          activeChat: const ActiveChatState(
            type: ActiveChatType.channel,
            id: 'announcements',
          ),
        ),
      );
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, 'Message #announcements');
    });

    testWidgets('displays group placeholder for groupDm', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildComposerUnderTest(
          activeChat: const ActiveChatState(
            type: ActiveChatType.groupDm,
            id: 'group-123',
          ),
        ),
      );
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, 'Message group...');
    });

    testWidgets('displays recipient placeholder with @ for directMessage', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildComposerUnderTest(
          activeChat: const ActiveChatState(
            type: ActiveChatType.directMessage,
            id: 'john_doe',
          ),
        ),
      );
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, 'Message @john_doe');
    });

    testWidgets('displays select recipient placeholder for newGroupChat', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildComposerUnderTest(
          activeChat: ActiveChatState.newGroupChat,
        ),
      );
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(
        textField.decoration?.hintText,
        'Select a recipient above to start messaging...',
      );
    });
  });
}
