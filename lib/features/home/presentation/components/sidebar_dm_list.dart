import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The direct messages in the Home sidebar, with your own space first as
/// "[Name] (you)". Tapping a row opens that conversation in the chat area.
///
/// It reads the same list as the DMs tab, so it makes no request of its own.
class SidebarDmList extends ConsumerWidget {
  const SidebarDmList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dmState = ref.watch(dmListProvider);
    final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
    final isOnline = ref.watch(
      authNotifierProvider.select((s) => s.user?.status.online ?? false),
    );
    final activeChat = ref.watch(activeChatProvider);

    final conversations = ownSpaceFirst(
      dmState.hasError
          ? const <DmConversation>[]
          : dmState.value ?? const <DmConversation>[],
      userId,
    );

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: [
        for (final conversation in conversations)
          _SidebarDmItem(
            conversation: conversation,
            isOwnSpace: conversation.isOwnSpaceOf(userId),
            isOnline: isOnline,
            isSelected:
                activeChat.type == ActiveChatType.directMessage &&
                activeChat.id == conversation.channelId,
            onTap: () {
              ref.read(selectedDmProvider.notifier).select(conversation);
              ref
                  .read(activeChatProvider.notifier)
                  .selectDirectMessage(conversation.channelId);
            },
          ),
      ],
    );
  }
}

class _SidebarDmItem extends StatelessWidget {
  const _SidebarDmItem({
    required this.conversation,
    required this.isOwnSpace,
    required this.isOnline,
    required this.isSelected,
    required this.onTap,
  });

  final DmConversation conversation;
  final bool isOwnSpace;
  final bool isOnline;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = conversation.displayName;
    final avatarUrl = conversation.effectiveAvatarUrl;

    return Material(
      color: isSelected
          ? colors.onPrimary.withValues(alpha: 0.12)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: colors.onPrimary.withValues(alpha: 0.2),
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Text(
                              name[0].toUpperCase(),
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    if (isOwnSpace && isOnline)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          key: const ValueKey('own-space-online-dot'),
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: colors.presenceActive,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.sidebar,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: name,
                    children: [
                      if (isOwnSpace)
                        TextSpan(
                          text: ' (you)',
                          style: TextStyle(
                            color: colors.onPrimary.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.onPrimary, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
