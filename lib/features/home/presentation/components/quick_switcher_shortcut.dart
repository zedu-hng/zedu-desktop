import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Opens the [QuickSwitcherDialog] on Cmd+K (macOS) or Ctrl+K (Windows,
/// Linux) from any screen once the user is signed in.
class QuickSwitcherShortcut extends ConsumerStatefulWidget {
  final Widget child;

  const QuickSwitcherShortcut({super.key, required this.child});

  @override
  ConsumerState<QuickSwitcherShortcut> createState() =>
      _QuickSwitcherShortcutState();
}

class _QuickSwitcherShortcutState extends ConsumerState<QuickSwitcherShortcut> {
  bool _open = false;

  Future<void> _showSwitcher() async {
    final signedIn =
        ref.read(authNotifierProvider).status == AuthStatus.authenticated;
    final navigatorContext =
        AppRouter.router.routerDelegate.navigatorKey.currentContext;
    if (_open || !signedIn || navigatorContext == null) return;

    _open = true;
    try {
      // Wait for the lists to load, so Cmd/Ctrl+K right after launch still
      // finds every channel and DM.
      final channelList = await ref
          .read(channelProvider.future)
          .catchError((_) => const <Channel>[]);
      final dmList = await ref
          .read(dmListProvider.future)
          .catchError((_) => const <DmConversation>[]);
      final channels = channelList
          .where((c) => !c.archived)
          .map((c) => QuickSwitcherEntry.channel(c.name));
      final dms = dmList.map(QuickSwitcherEntry.dm);
      final rootContext =
          AppRouter.router.routerDelegate.navigatorKey.currentContext;
      if (!mounted || rootContext == null || !rootContext.mounted) return;

      await showDialog<void>(
        context: rootContext,
        builder: (dialogContext) => QuickSwitcherDialog(
          entries: [...channels, ...dms],
          onSelected: (entry) {
            Navigator.of(dialogContext).pop();
            _openEntry(entry);
          },
        ),
      );
    } finally {
      _open = false;
    }
  }

  void _openEntry(QuickSwitcherEntry entry) {
    final conversation = entry.conversation;
    if (conversation == null) {
      ref.read(homeSidebarProvider.notifier).setType(HomeSidebarType.home);
      ref.read(activeChatProvider.notifier).selectChannel(entry.label);
    } else {
      ref.read(homeSidebarProvider.notifier).setType(HomeSidebarType.dms);
      ref.read(selectedDmProvider.notifier).select(conversation);
    }

    final location = AppRouter.router.routerDelegate.currentConfiguration.uri;
    if (location.path != AppRouter.home) {
      AppRouter.router.go(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _showSwitcher,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _showSwitcher,
      },
      child: widget.child,
    );
  }
}
