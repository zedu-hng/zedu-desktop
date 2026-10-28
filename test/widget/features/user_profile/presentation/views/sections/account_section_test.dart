import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

ProfileAccount buildAccount({String username = ''}) {
  return ProfileAccount(
    name: 'Ada Okafor',
    email: 'ada@zedu.chat',
    timezone: 'Africa/Lagos',
    username: username,
  );
}

Widget buildSectionUnderTest(ProfileAccount account) {
  return ProviderScope(
    child: buildTestMaterialApp(
      Scaffold(
        body: SingleChildScrollView(
          child: AccountSection(
            account: account,
            isSaving: false,
            onSave: (_) {},
            onDelete: () async {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the account username when it is set', (tester) async {
    await tester.pumpWidget(
      buildSectionUnderTest(buildAccount(username: 'ada')),
    );

    expect(find.text('@ada'), findsOneWidget);
  });

  testWidgets('derives the handle from the name when username is empty', (
    tester,
  ) async {
    await tester.pumpWidget(buildSectionUnderTest(buildAccount()));

    expect(find.text('@adaokafor'), findsOneWidget);
  });
}
