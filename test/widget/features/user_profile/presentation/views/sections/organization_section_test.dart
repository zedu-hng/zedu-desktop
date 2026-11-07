import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

void main() {
  testWidgets('renders organization avatar container with primaryBg token', (
    tester,
  ) async {
    const org = OrganizationProfile(
      id: 'org-1',
      name: 'Acme Corp',
      natureOfBusiness: 'Technology',
      country: 'US',
    );

    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: OrganizationSection(
            organization: org,
            onSave: (_) {},
            onDelete: () async {},
            onLeave: () async {},
          ),
        ),
      ),
    );

    expect(find.text('AC'), findsOneWidget);
    final containerFinder = find.ancestor(
      of: find.text('AC'),
      matching: find.byType(Container),
    );
    expect(containerFinder, findsWidgets);

    final containerWidget = tester.widget<Container>(containerFinder.first);
    final decoration = containerWidget.decoration as BoxDecoration?;
    expect(decoration?.color, equals(AppPalette.light.primaryBg));
  });

  testWidgets('Delete organization uses the error colour token', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: OrganizationSection(
            organization: const OrganizationProfile(
              id: 'org-1',
              name: 'Acme',
              natureOfBusiness: 'Technology',
              country: 'Nigeria',
            ),
            onSave: (_) {},
            onDelete: () async {},
            onLeave: () async {},
          ),
        ),
      ),
    );

    final button = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Delete organization'),
        matching: find.byType(OutlinedButton),
      ),
    );
    final style = button.style!;
    final error = AppPalette.light.error;

    expect(style.foregroundColor!.resolve({}), error);
    expect(style.side!.resolve({})!.color, error);
  });

  testWidgets(
    'sign out and delete wrap instead of overflowing a narrow panel',
    (tester) async {
      tester.view.physicalSize = const Size(560, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestMaterialApp(
          Scaffold(
            body: OrganizationSection(
              organization: OrganizationProfile(
                id: 'org-1',
                name: 'Zedu',
                natureOfBusiness: 'Software',
                country: 'Nigeria',
              ),
              onSave: _noopSave,
              onDelete: _noop,
              onLeave: _noop,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Sign out of workspace'), findsOneWidget);
      expect(find.text('Delete organization'), findsOneWidget);

      final signOut = tester.getRect(find.text('Sign out of workspace'));
      final deleteOrg = tester.getRect(find.text('Delete organization'));
      expect(deleteOrg.top, greaterThan(signOut.bottom));
    },
  );
}

void _noopSave(OrganizationProfile _) {}

Future<void> _noop() async {}
