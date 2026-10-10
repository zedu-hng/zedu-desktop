import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class AppSidebarRail extends ConsumerWidget {
  const AppSidebarRail({
    super.key,
    required this.activeType,
    this.onTypeSelected,
    this.settingsSelected = false,
  });

  static const double width = 50;

  final HomeSidebarType? activeType;
  final ValueChanged<HomeSidebarType>? onTypeSelected;
  final bool settingsSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    void select(HomeSidebarType type) {
      if (onTypeSelected != null) {
        onTypeSelected!(type);
        return;
      }
      ref.read(homeSidebarProvider.notifier).setType(type);
    }

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.sidebar,
        border: Border(
          right: BorderSide(color: colors.onPrimary.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _RailNavItem(
            icon: Icons.home_filled,
            label: 'Home',
            isActive: activeType == HomeSidebarType.home,
            onTap: () => select(HomeSidebarType.home),
          ),
          _RailNavItem(
            icon: Icons.chat_bubble_outline,
            label: 'DMs',
            isActive: activeType == HomeSidebarType.dms,
            onTap: () => select(HomeSidebarType.dms),
          ),
          _RailNavItem(
            icon: Icons.people_outline,
            label: 'People',
            isActive: activeType == HomeSidebarType.people,
            onTap: () => select(HomeSidebarType.people),
          ),
          _RailNavItem(
            icon: Icons.folder_open_outlined,
            label: 'Files',
            isActive: activeType == HomeSidebarType.files,
            onTap: () => select(HomeSidebarType.files),
          ),
          _BuzzRailItem(
            isActive: activeType == HomeSidebarType.buzz,
            onTap: () => select(HomeSidebarType.buzz),
          ),
          const Spacer(),
          _RailBottomIcon(
            icon: Icons.notifications_none_outlined,
            hasNotification: (ref.watch(workspaceProvider).selectedWorkspace?.unreadCount ?? 0) > 0,
            onTap: () {
              // Fire a test notification replicating DM notification
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification will fire in 5 seconds.'),
                  duration: Duration(seconds: 3),
                ),
              );
              Future.delayed(const Duration(seconds: 5), () {
                ref
                    .read(notificationServiceProvider)
                    .handleIncomingMessage(
                      {
                        'user_id': 'system_notification',
                        'content': 'This is a test notification from Zedu.',
                      },
                      'system',
                      'Zedu',
                      forceShow: true,
                    );
              });
            },
          ),
          _RailBottomIcon(
            icon: Icons.settings_outlined,
            selected: settingsSelected,
            onTap: () {
              context.go(AppRouter.profile);
            },
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 16, top: 8),
            child: UserMenuButton(),
          ),
        ],
      ),
    );
  }
}

class _BuzzRailItem extends ConsumerWidget {
  const _BuzzRailItem({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(activeCallProvider).state;
    final tooltip = call.lastCallAt == null
        ? 'Buzz'
        : 'Last Buzz: ${_formatDateTime(call.lastCallAt!)}';

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: _RailNavItem(
        icon: Icons.phone_outlined,
        label: 'Buzz',
        isActive: isActive,
        onTap: onTap,
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day}/${local.month}/${local.year} $hour:$minute $period';
  }
}

class _RailNavItem extends StatelessWidget {
  const _RailNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive
                    ? colors.primary.withValues(alpha: 0.95)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: colors.onPrimary, size: 18),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: colors.onPrimary.withValues(alpha: 0.92),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailBottomIcon extends StatelessWidget {
  const _RailBottomIcon({
    required this.icon,
    this.hasNotification = false,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final bool hasNotification;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected
                    ? colors.primary.withValues(alpha: 0.95)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: colors.onPrimary, size: 18),
            ),
            if (hasNotification)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
