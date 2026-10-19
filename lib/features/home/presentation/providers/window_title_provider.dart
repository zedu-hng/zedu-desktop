import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Sum of unread messages across channels and DMs.
final totalUnreadProvider = Provider<int>((ref) {
  final channels = ref.watch(channelProvider).value ?? const <Channel>[];
  final dms = ref.watch(dmListProvider).value ?? const <DmConversation>[];

  final channelUnread = channels.fold<int>(0, (sum, c) => sum + c.unreadCount);
  final dmUnread = dms.fold<int>(0, (sum, d) => sum + d.unreadCount);

  return channelUnread + dmUnread;
});

/// Builds the window title, e.g. "(37) Zedu - Learning Workspace".
String buildWindowTitle({required int unreadCount, String? workspaceName}) {
  final base = (workspaceName == null || workspaceName.isEmpty)
      ? 'Zedu'
      : 'Zedu - $workspaceName';
  return unreadCount > 0 ? '($unreadCount) $base' : base;
}

/// The title the desktop window should show right now.
final windowTitleProvider = Provider<String>((ref) {
  final unread = ref.watch(totalUnreadProvider);
  final workspaceName = ref.watch(workspaceProvider).selectedWorkspace?.name;
  return buildWindowTitle(unreadCount: unread, workspaceName: workspaceName);
});
