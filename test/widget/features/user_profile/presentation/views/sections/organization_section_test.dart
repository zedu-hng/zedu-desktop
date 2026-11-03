import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

void main() {
  group('OrganizationSection', () {
    testWidgets('Delete organization button uses the palette error colour', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestMaterialApp(
          Scaffold(
            body: SingleChildScrollView(
              child: OrganizationSection(
                organization: const OrganizationProfile(
                  id: 'org-1',
                  name: 'Acme',
                  natureOfBusiness: 'Design agency',
                  country: 'Nigeria',
                ),
                isSaving: false,
                onSave: (_) {},
                onDelete: () async {},
                onLeave: () async {},
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.ancestor(
        of: find.text('Delete organization'),
        matching: find.byType(OutlinedButton),
      );
      final style = tester.widget<OutlinedButton>(buttonFinder).style!;
      final error = tester.element(buttonFinder).colors.error;

      expect(style.foregroundColor?.resolve(<WidgetState>{}), error);
      expect(style.side?.resolve(<WidgetState>{})?.color, error);
    });
  });
}
