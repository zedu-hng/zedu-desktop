import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class UserProfileView extends ConsumerWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<UserProfileState>(userProfileNotifierProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          AppToastService.show(
            context,
            type: AppToastType.error,
            message: next.error!,
          );
        });
      }
      if (next.successMessage != null &&
          previous?.successMessage != next.successMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          AppToastService.show(
            context,
            type: AppToastType.success,
            message: next.successMessage!,
          );
        });
      }
    });

    final state = ref.watch(userProfileNotifierProvider);
    final notifier = ref.read(userProfileNotifierProvider.notifier);
    final workspaceName = ref.watch(
      workspaceProvider.select((s) => s.selectedWorkspace?.name),
    );

    return ProfileSettingsShell(
      selectedSection: state.section,
      onSectionSelected: notifier.selectSection,
      child: _ProfileContent(
        state: state,
        notifier: notifier,
        workspaceName: workspaceName,
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.state,
    required this.notifier,
    required this.workspaceName,
  });

  final UserProfileState state;
  final UserProfileNotifier notifier;
  final String? workspaceName;

  static const padding = EdgeInsets.fromLTRB(28, 32, 40, 48);
  static const maxContentWidth = 1000.0;

  @override
  Widget build(BuildContext context) {
    // Notifications scrolls on its own so its unsaved-changes bar can stay
    // pinned below the scrolling content.
    if (state.section == UserProfileSection.notifications) {
      return NotificationsSection(
        preferences: state.notifications ?? NotificationPreferences.empty(),
        isSaving: state.isSaving,
        onSave: notifier.updateNotificationPreferences,
        workspaceName: workspaceName,
        padding: padding,
        maxContentWidth: maxContentWidth,
      );
    }
    return SingleChildScrollView(
      padding: padding,
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: switch (state.section) {
            UserProfileSection.account => AccountSection(
              account: state.account ?? ProfileAccount.empty(),
              isSaving: state.isSaving,
              onSave: notifier.updateAccount,
              onDelete: notifier.deleteAccount,
            ),
            UserProfileSection.notifications => const SizedBox.shrink(),
            UserProfileSection.security => SecuritySection(
              sessions: state.securitySessions,
              isSaving: state.isSaving,
              onChangePassword: notifier.changePassword,
            ),
            UserProfileSection.organization => OrganizationSection(
              organization: state.organization ?? OrganizationProfile.empty(),
              isSaving: state.isSaving,
              onSave: notifier.updateOrganization,
              onDelete: notifier.deleteOrganization,
              onLeave: notifier.leaveOrganization,
            ),
            UserProfileSection.userManagement => UserManagementSection(
              members: state.teamMembers,
              invites: state.invites,
              invitesPage: state.invitesPage,
              isInvitesLoading: state.isInvitesLoading,
              invitesLoadFailed: state.invitesLoadFailed,
              onLoadInvites: notifier.loadInvites,
              onDeleteInvite: notifier.deleteInvite,
              isSaving: state.isSaving,
              onInvite: notifier.inviteMember,
              onUpdate: notifier.updateMember,
              onRemove: notifier.removeMember,
            ),
            UserProfileSection.rolesAndPermissions =>
              RolesAndPermissionsSection(roles: state.rolesAndPermissions),
            UserProfileSection.billing => BillingSection(
              billing: state.billing ?? BillingInfo.empty(),
              onInvite: notifier.inviteMember,
            ),
          },
        ),
      ),
    );
  }
}
