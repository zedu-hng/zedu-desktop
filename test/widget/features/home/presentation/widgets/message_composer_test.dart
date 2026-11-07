import 'dart:io';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

const _filePickerChannel = MethodChannel(
  'miguelruivo.flutter.plugins.filepicker',
);

String _posixStyle(String path) {
  if (!Platform.isWindows) return path;
  return path.replaceFirst(RegExp(r'^[A-Za-z]:'), '').replaceAll(r'\', '/');
}

void _fakeFilePicker(WidgetTester tester, List<String> paths) {
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    _filePickerChannel,
    (call) async => [
      for (final path in paths)
        {'path': path, 'name': path.split(RegExp(r'[/\\]')).last, 'size': 4},
    ],
  );
  addTearDown(
    () => messenger.setMockMethodCallHandler(_filePickerChannel, null),
  );
}

class _FakeProfileNotifier extends UserProfileNotifier {
  _FakeProfileNotifier(this.initial);

  final UserProfileState initial;

  @override
  UserProfileState build() => initial;

  @override
  Future<void> load() async {}
}

const _rocket = TeamMember(
  id: 'u-1',
  email: 'rocket@zedu.test',
  role: 'Member',
  dateJoined: '2026-01-01',
  status: TeamMemberStatus.active,
  name: '🚀 Rocket',
);

const _engineer = TeamMember(
  id: 'u-2',
  email: 'alice@zedu.test',
  role: 'Member',
  dateJoined: '2026-01-01',
  status: TeamMemberStatus.active,
  name: '👩‍💻 Alice',
);

const _blankName = TeamMember(
  id: 'u-3',
  email: 'blank@zedu.test',
  role: 'Member',
  dateJoined: '2026-01-01',
  status: TeamMemberStatus.active,
  name: '   ',
);

const _ada = TeamMember(
  id: 'u-4',
  email: 'ada@zedu.test',
  role: 'Admin',
  dateJoined: '2026-01-01',
  status: TeamMemberStatus.active,
  name: 'Ada Lovelace',
);

Future<void> _pumpWithMentionList(
  WidgetTester tester,
  List<TeamMember> members,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProfileNotifierProvider.overrideWith(
          () => _FakeProfileNotifier(UserProfileState(teamMembers: members)),
        ),
      ],
      child: buildTestMaterialApp(
        Scaffold(
          body: MessageComposer(
            activeChat: const ActiveChatState(
              type: ActiveChatType.channel,
              id: 'general',
            ),
            onSend: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(TextField));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), '@');
  await tester.pumpAndSettle();
}

void main() {
  group('MessageComposer mention suggestion avatars', () {
    testWidgets('show the whole first emoji for emoji-prefixed names', (
      tester,
    ) async {
      await _pumpWithMentionList(tester, [_rocket, _engineer]);

      expect(find.text('🚀'), findsOneWidget);
      expect(find.text('👩‍💻'), findsOneWidget);
      expect(find.text('🚀 Rocket'), findsOneWidget);
    });

    testWidgets('fall back to ? for whitespace-only names', (tester) async {
      await _pumpWithMentionList(tester, [_blankName]);

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('keep showing the first letter of ordinary names', (
      tester,
    ) async {
      await _pumpWithMentionList(tester, [_ada]);

      expect(find.text('A'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
    });
  });

  group('MessageComposer attachment handling', () {
    late Directory tempDir;
    late String reportPath;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.llfbandit.record/messages'),
            (call) async => null,
          );
      tempDir = Directory.systemTemp.createTempSync(
        'zedu_attach_composer_test',
      );
      final report = File(
        '${tempDir.path}${Platform.pathSeparator}specification.pdf',
      )..writeAsBytesSync([1, 2, 3, 4]);
      reportPath = _posixStyle(report.path);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets('preserves picked file paths in onSend and onSendMedia', (
      tester,
    ) async {
      String? sentMessage;
      List<XFile>? sentMedia;

      _fakeFilePicker(tester, [reportPath]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileNotifierProvider.overrideWith(
              () => _FakeProfileNotifier(
                UserProfileState(teamMembers: const [_ada]),
              ),
            ),
          ],
          child: buildTestMaterialApp(
            Scaffold(
              body: MessageComposer(
                activeChat: const ActiveChatState(
                  type: ActiveChatType.channel,
                  id: 'general',
                ),
                onSend: (msg) => sentMessage = msg,
                onSendMedia: (text, media) => sentMedia = media,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.byTooltip('Attach file'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      // Chip shows the filename
      expect(find.text('specification.pdf'), findsOneWidget);

      // Type some text
      await tester.enterText(find.byType(TextField), 'Check this document');
      await tester.pumpAndSettle();

      // Tap send
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();

      expect(sentMessage, 'Check this document\n[Attachment: $reportPath]');
      expect(sentMedia, isNotNull);
      expect(sentMedia!.length, 1);
      expect(sentMedia!.first.path, reportPath);
      expect(sentMedia!.first.name, contains('specification.pdf'));

      // Chips are cleared after send
      expect(find.text('specification.pdf'), findsNothing);
    });

    testWidgets('allows removing an attached file chip before sending', (
      tester,
    ) async {
      String? sentMessage;

      _fakeFilePicker(tester, [reportPath]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileNotifierProvider.overrideWith(
              () => _FakeProfileNotifier(
                UserProfileState(teamMembers: const [_ada]),
              ),
            ),
          ],
          child: buildTestMaterialApp(
            Scaffold(
              body: MessageComposer(
                activeChat: const ActiveChatState(
                  type: ActiveChatType.channel,
                  id: 'general',
                ),
                onSend: (msg) => sentMessage = msg,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.byTooltip('Attach file'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      expect(find.text('specification.pdf'), findsOneWidget);

      // Tap delete on the chip
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('specification.pdf'), findsNothing);
      expect(sentMessage, isNull);
    });
  });
}
