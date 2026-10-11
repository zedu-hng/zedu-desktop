import 'package:flutter/rendering.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

const _palette = AppPalette.light;

// Starts with a given conversation already selected.
class FakeSelectedDmNotifier extends SelectedDmNotifier {
  FakeSelectedDmNotifier(this._initial);

  final DmConversation? _initial;

  @override
  DmConversation? build() => _initial;
}

// Fake workspace notifier so the sidebar header needs no GetIt/locator setup.
class FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState();
}

// Fake list notifier that avoids the repository and GetIt/locator setup.
class FakeDmListNotifier extends DmListNotifier {
  FakeDmListNotifier(this._conversations);

  final List<DmConversation> _conversations;

  @override
  Future<List<DmConversation>> build() async => _conversations;
}

DmConversation buildConversation({
  String channelId = 'channel-1',
  String username = 'Ada Okafor',
  String previewMessage = 'See you at standup',
  int unreadCount = 0,
}) {
  return DmConversation(
    channelId: channelId,
    username: username,
    participantId: 'user-$channelId',
    previewMessage: previewMessage,
    unreadCount: unreadCount,
  );
}

Widget buildTileUnderTest(
  DmConversation conversation, {
  DmConversation? selected,
}) {
  return ProviderScope(
    overrides: [
      selectedDmProvider.overrideWith(() => FakeSelectedDmNotifier(selected)),
    ],
    child: buildTestMaterialApp(
      Scaffold(
        backgroundColor: _palette.sidebar,
        body: Column(children: [DmListTile(conversation: conversation)]),
      ),
    ),
  );
}

TextStyle textStyleOf(WidgetTester tester, String text) {
  return tester.widget<Text>(find.text(text)).style!;
}

// The renderer that paints ink (Ink decorations and InkWell highlights) for
// the Material nearest the tile.
RenderObject inkFeatures(WidgetTester tester) {
  return tester.allRenderObjects.firstWhere(
    (object) => object.runtimeType.toString() == '_RenderInkFeatures',
  );
}

// Colours are compared as 8-bit ARGB because ink highlights round the alpha.
// Matches when any rounded rectangle is painted in [color], whatever else is
// painted before it (the Ink decoration is always painted first).
PaintPattern paintsRRect(Color color) {
  return paints..something(
    (method, args) =>
        method == #drawRRect &&
        (args[1] as Paint).color.toARGB32() == color.toARGB32(),
  );
}

Future<TestGesture> hover(WidgetTester tester, Finder finder) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(tester.getCenter(finder));
  await tester.pumpAndSettle();
  return gesture;
}

void main() {
  final selectedFill = _palette.onPrimary.withValues(alpha: 0.16);
  final hoverFill = _palette.onPrimary.withValues(alpha: 0.06);

  group('DmListTile', () {
    testWidgets('read row: normal name, dimmer preview, no badge or bar', (
      tester,
    ) async {
      await tester.pumpWidget(buildTileUnderTest(buildConversation()));

      final name = textStyleOf(tester, 'Ada Okafor');
      expect(name.fontWeight, FontWeight.w500);
      expect(name.color, _palette.onPrimary);

      final preview = textStyleOf(tester, 'See you at standup');
      expect(preview.fontWeight, FontWeight.w400);
      expect(preview.color, _palette.onPrimary.withValues(alpha: 0.72));

      expect(find.text('0'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              (w.decoration as BoxDecoration).color == _palette.accent,
        ),
        findsNothing,
      );
      expect(inkFeatures(tester), isNot(paintsRRect(selectedFill)));
    });

    testWidgets('unread row: bold name, full-white preview and teal badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTileUnderTest(buildConversation(unreadCount: 3)),
      );

      final name = textStyleOf(tester, 'Ada Okafor');
      expect(name.fontWeight, FontWeight.w700);
      expect(name.color, _palette.onPrimary);

      final preview = textStyleOf(tester, 'See you at standup');
      expect(preview.fontWeight, FontWeight.w700);
      expect(preview.color, _palette.onPrimary);

      final badgeText = textStyleOf(tester, '3');
      expect(badgeText.color, _palette.textPrimary);
      final badge = tester.widget<Container>(
        find.ancestor(of: find.text('3'), matching: find.byType(Container)),
      );
      expect((badge.decoration! as BoxDecoration).color, _palette.accent);
    });

    testWidgets('selected row: white 16% fill and teal bar on the left', (
      tester,
    ) async {
      final conversation = buildConversation();
      await tester.pumpWidget(
        buildTileUnderTest(conversation, selected: conversation),
      );

      expect(inkFeatures(tester), paintsRRect(selectedFill));

      final bar = find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            (w.decoration as BoxDecoration).color == _palette.accent,
      );
      expect(bar, findsOneWidget);
      final barRect = tester.getRect(bar);
      final tileRect = tester.getRect(find.byType(InkWell));
      expect(barRect.width, 3);
      expect(barRect.left, tileRect.left);
      expect(barRect.height, tileRect.height);
    });

    testWidgets('another conversation being selected leaves this row plain', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTileUnderTest(
          buildConversation(),
          selected: buildConversation(channelId: 'other'),
        ),
      );

      expect(inkFeatures(tester), isNot(paintsRRect(selectedFill)));
    });

    testWidgets('hovered row: light highlight and the click cursor', (
      tester,
    ) async {
      await tester.pumpWidget(buildTileUnderTest(buildConversation()));

      expect(inkFeatures(tester), isNot(paintsRRect(hoverFill)));

      await hover(tester, find.byType(DmListTile));

      expect(inkFeatures(tester), paintsRRect(hoverFill));
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.click,
      );
    });

    testWidgets('rows are rounded and inset 8px with no divider lines', (
      tester,
    ) async {
      await tester.pumpWidget(buildTileUnderTest(buildConversation()));

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.borderRadius, BorderRadius.circular(6));

      final tileRect = tester.getRect(find.byType(DmListTile));
      final rowRect = tester.getRect(find.byType(InkWell));
      expect(rowRect.left - tileRect.left, 8);
      expect(tileRect.right - rowRect.right, 8);
      expect(tileRect.height - rowRect.height, 2);

      final bordered = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).border != null,
      );
      expect(bordered, findsNothing);
    });

    testWidgets('tapping a row selects the conversation', (tester) async {
      final conversation = buildConversation();
      await tester.pumpWidget(buildTileUnderTest(conversation));

      await tester.tap(find.byType(DmListTile));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(DmListTile)),
      );
      expect(container.read(selectedDmProvider), same(conversation));
      expect(inkFeatures(tester), paintsRRect(selectedFill));
    });
  });

  group('DmSidebarList', () {
    testWidgets('row ink paints on a Material above the sidebar colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workspaceProvider.overrideWith(FakeWorkspaceNotifier.new),
            dmListProvider.overrideWith(
              () => FakeDmListNotifier([buildConversation()]),
            ),
          ],
          child: buildTestMaterialApp(const Scaffold(body: DmSidebarList())),
        ),
      );
      await tester.pumpAndSettle();

      final nearestMaterial = find
          .ancestor(
            of: find.byType(DmListTile),
            matching: find.byType(Material),
          )
          .first;
      expect(
        tester.widget<Material>(nearestMaterial).type,
        MaterialType.transparency,
      );
      // That Material must sit inside the sidebar's coloured Container, or
      // the Container paints over the hover and selected ink.
      final sidebar = find.byWidgetPredicate(
        (w) => w is Container && w.color == _palette.sidebar,
      );
      expect(
        find.descendant(of: sidebar, matching: nearestMaterial),
        findsOneWidget,
      );

      await hover(tester, find.byType(DmListTile));
      expect(tester.renderObject(nearestMaterial), paintsRRect(hoverFill));
    });
  });
}
