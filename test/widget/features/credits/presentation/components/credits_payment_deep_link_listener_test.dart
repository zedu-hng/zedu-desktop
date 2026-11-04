import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/features/features.dart';

class MockAppLinks extends Mock implements AppLinks {}

void main() {
  group('CreditsPaymentDeepLinkListener', () {
    late MockAppLinks mockAppLinks;
    late StreamController<Uri> linkController;

    setUp(() {
      mockAppLinks = MockAppLinks();
      linkController = StreamController<Uri>.broadcast();

      when(
        () => mockAppLinks.uriLinkStream,
      ).thenAnswer((_) => linkController.stream);
    });

    tearDown(() async {
      await linkController.close();
    });

    testWidgets('does not subscribe when disposed during the initial link', (
      tester,
    ) async {
      final initialLink = Completer<Uri?>();
      when(
        () => mockAppLinks.getInitialLink(),
      ).thenAnswer((_) => initialLink.future);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CreditsPaymentDeepLinkListener(
              appLinks: mockAppLinks,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      // Dispose while the initial link is still loading.
      await tester.pumpWidget(const SizedBox.shrink());
      initialLink.complete(null);
      await tester.pump();

      verifyNever(() => mockAppLinks.uriLinkStream);
    });
  });
}
