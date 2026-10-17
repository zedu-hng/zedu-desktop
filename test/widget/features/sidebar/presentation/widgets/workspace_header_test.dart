import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  testWidgets('plus button selects the New Group Chat page', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: WorkspaceSwitcherHeader())),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WorkspaceSwitcherHeader)),
    );
    expect(
      container.read(activeChatProvider).type,
      isNot(ActiveChatType.newGroupChat),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(
      container.read(activeChatProvider).type,
      ActiveChatType.newGroupChat,
    );
  });
}
