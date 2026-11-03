import 'package:flutter/foundation.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

void main() {
  group('SearchPanel', () {
    testWidgets('disposes its search controller when removed', (tester) async {
      final created = <Object>{};
      final disposed = <Object>{};
      void onEvent(ObjectEvent event) {
        if (event.object is! TextEditingController) return;
        if (event is ObjectCreated) created.add(event.object);
        if (event is ObjectDisposed) disposed.add(event.object);
      }

      FlutterMemoryAllocations.instance.addListener(onEvent);
      addTearDown(
        () => FlutterMemoryAllocations.instance.removeListener(onEvent),
      );

      await tester.pumpWidget(
        buildTestMaterialApp(Scaffold(body: SearchPanel(onClose: () {}))),
      );
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('hello'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());

      expect(created, isNotEmpty);
      expect(disposed, containsAll(created));
    });
  });
}
