import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final _channelMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orgId = ref.read(authNotifierProvider).user?.currentOrg;
      if (orgId != null && orgId.isNotEmpty) {
        ref.read(creditsNotifierProvider.notifier).load(orgId: orgId);
      }
    });
  }

  @override
  void dispose() {
    _channelMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final showProfile = ref.watch(personalProfilePanelProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const _HomeAppBar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, windowConstraints) {
                // Make room for the profile drawer and keep the message
                // composer visible on narrow windows.
                final compactProfileLayout =
                    showProfile && windowConstraints.maxWidth < 900;

                return Row(
                  children: [
                    AppSidebarRail(activeType: ref.watch(homeSidebarProvider)),
                    if (!compactProfileLayout) const _MainSidebarSwitcher(),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (compactProfileLayout) {
                            final composerClearance =
                                (constraints.maxHeight - 48)
                                    .clamp(0.0, 220.0)
                                    .toDouble();

                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: _ChatAreaSwitcher(
                                    messageController:
                                        _channelMessageController,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  bottom: composerClearance,
                                  child: PersonalProfilePanel(
                                    width: constraints.maxWidth,
                                  ),
                                ),
                              ],
                            );
                          }

                          final profileWidth = (constraints.maxWidth * 0.4)
                              .clamp(0.0, 360.0)
                              .toDouble();

                          return Row(
                            children: [
                              Expanded(
                                child: _ChatAreaSwitcher(
                                  messageController: _channelMessageController,
                                ),
                              ),
                              if (showProfile)
                                PersonalProfilePanel(width: profileWidth),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAppBar extends ConsumerWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final userName =
        ref.watch(authNotifierProvider).user?.fullname ?? 'Zedu User';

    return Container(
      height: 44,
      color: colors.sidebar,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            'Zedu',
            style: TextStyle(
              color: colors.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poetsen One',
            ),
          ),
          const SizedBox(width: 12),
          TopUserMenu(userName: userName),
          const Spacer(),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              height: 28,
              decoration: BoxDecoration(
                color: colors.onPrimary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(
                    Icons.search,
                    color: colors.onPrimary.withValues(alpha: 0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Search messages...',
                    style: TextStyle(
                      color: colors.onPrimary.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _MainSidebarSwitcher extends ConsumerWidget {
  const _MainSidebarSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeSidebarProvider);
    if (state == HomeSidebarType.dms) {
      return const DmSidebarList();
    }
    return const _MainSidebar();
  }
}

class _ChatAreaSwitcher extends ConsumerWidget {
  const _ChatAreaSwitcher({this.messageController});

  final TextEditingController? messageController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeSidebarProvider);
    final selectedDm = ref.watch(selectedDmProvider);

    if (state == HomeSidebarType.dms) {
      if (selectedDm != null) {
        return DmChatArea(conversation: selectedDm);
      } else {
        return Container(
          color: context.colors.background,
          child: Center(
            child: Text(
              'Select a conversation to start messaging',
              style: TextStyle(color: context.colors.textHint, fontSize: 16),
            ),
          ),
        );
      }
    }
    return HomeChatArea(messageController: messageController);
  }
}

class _MainSidebar extends StatelessWidget {
  const _MainSidebar();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 320,
      color: colors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Icon(Icons.arrow_drop_down, color: colors.onPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Channels',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const _ChannelItem(label: 'general'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.onPrimary.withValues(alpha: 0.24),
                ),
                borderRadius: BorderRadius.circular(6),
                color: colors.onPrimary.withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'View all channels',
                      style: TextStyle(
                        color: colors.onPrimary.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colors.onPrimary.withValues(alpha: 0.7),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const _AddChannelButton(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.arrow_right, color: colors.onPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'People',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelItem extends StatelessWidget {
  final String label;

  const _ChannelItem({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text(
            '#',
            style: TextStyle(
              color: colors.onPrimary.withValues(alpha: 0.54),
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: colors.onPrimary, fontSize: 15)),
        ],
      ),
    );
  }
}

class _AddChannelButton extends StatelessWidget {
  const _AddChannelButton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(
                color: colors.onPrimary.withValues(alpha: 0.38),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.add, color: colors.onPrimary, size: 14),
          ),
          const SizedBox(width: 12),
          Text(
            'Add channel',
            style: TextStyle(color: colors.onPrimary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// The Home pane for the channel picked in the sidebar.
class HomeChatArea extends ConsumerWidget {
  const HomeChatArea({super.key, this.messageController});

  final TextEditingController? messageController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The channel messages are not listed here yet, so the header, welcome
    // text and input hint carry the selected channel name.
    final chat = ref.watch(activeChatProvider);
    final channelName = chat.type == ActiveChatType.channel
        ? (chat.id ?? 'general')
        : 'general';

    return Column(
      children: [
        _buildChatHeader(context, channelName, ref),
        Expanded(child: _buildWelcomeScreen(context, channelName)),
        _buildMessageInput(context, channelName, messageController),
      ],
    );
  }

  Widget _buildChatHeader(
    BuildContext context,
    String channelName,
    WidgetRef ref,
  ) {
    final colors = context.colors;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '# $channelName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          _HeaderAction(icon: Icons.headphones_outlined, label: 'Start Buzz'),
          const SizedBox(width: 12),
          Tooltip(
            message: 'Open profile',
            child: InkWell(
              onTap: () =>
                  ref.read(personalProfilePanelProvider.notifier).state = true,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: colors.accent,
                child: Icon(Icons.person, size: 18, color: colors.onPrimary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.more_vert, color: colors.textHint),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen(BuildContext context, String channelName) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.celebration, size: 60, color: colors.primary),
          const SizedBox(height: 24),
          Text(
            'Welcome to #$channelName',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share all information relating to $channelName here. All team members await you! 😉',
            style: TextStyle(fontSize: 16, color: colors.textPrimary),
          ),
          const SizedBox(height: 32),
          const _InviteCard(),
        ],
      ),
    );
  }

  Widget _buildMessageInput(
    BuildContext context,
    String channelName,
    TextEditingController? messageController,
  ) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: colors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.format_bold, size: 20, color: colors.textHint),
                const SizedBox(width: 16),
                Icon(Icons.format_italic, size: 20, color: colors.textHint),
                const SizedBox(width: 16),
                Icon(Icons.link, size: 20, color: colors.textHint),
                const SizedBox(width: 16),
                Icon(Icons.list, size: 20, color: colors.textHint),
                const SizedBox(width: 16),
                Icon(Icons.code, size: 20, color: colors.textHint),
              ],
            ),
            Divider(height: 24, color: colors.divider),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'Message #$channelName',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.add, color: colors.textHint.withValues(alpha: 0.75)),
                const SizedBox(width: 12),
                Icon(
                  Icons.emoji_emotions_outlined,
                  color: colors.textHint.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.alternate_email,
                  color: colors.textHint.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.videocam_outlined,
                  color: colors.textHint.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.mic_none_outlined,
                  color: colors.textHint.withValues(alpha: 0.75),
                ),
                const Spacer(),
                Icon(
                  Icons.send_rounded,
                  color: colors.textHint.withValues(alpha: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: colors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textPrimary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: colors.textPrimary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: colors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primaryBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.person_add_outlined, color: colors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite teammates',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add more team members to collaborate',
                  style: TextStyle(color: colors.textHint, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.textHint),
        ],
      ),
    );
  }
}
