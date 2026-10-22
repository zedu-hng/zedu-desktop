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
    final authenticatedUser = ref.watch(authNotifierProvider).user;
    final notifier = ref.read(userProfileNotifierProvider.notifier);

    // Never show placeholder "Anonymous user" values as fallbacks. If the
    // profile account hasn't loaded yet, derive the account from the
    // authenticated user's data so the real name and email are shown.
    final account = state.account != null
        ? accountForAuthenticatedUser(state.account, authenticatedUser)
        : authenticatedUser != null
            ? profileAccountFromAuthUser(authenticatedUser)
            : ProfileAccount.empty();

    return ProfileSettingsShell(
      selectedSection: state.section,
      onSectionSelected: notifier.selectSection,
      child: _ProfileContent(
        state: state,
        account: account,
        notifier: notifier,
      ),
    );
  }
}

@visibleForTesting
ProfileAccount accountForAuthenticatedUser(
  ProfileAccount account,
  User? authenticatedUser,
) {
  if (authenticatedUser == null) return account;

  final authenticatedName = authenticatedUser.fullname.trim().isNotEmpty
      ? authenticatedUser.fullname.trim()
      : authenticatedUser.username;
  final name = account.name.trim();
  final email = account.email.trim();

  return account.copyWith(
    name: name.isEmpty || name.toLowerCase() == 'anonymous user'
        ? authenticatedName
        : name,
    email: email.isEmpty || email.toLowerCase() == 'anonymoususer@email.com'
        ? authenticatedUser.email
        : email,
    username:
        account.username.trim().isEmpty ||
            account.username.toLowerCase() == 'anonymoususer'
        ? authenticatedUser.username
        : account.username,
    avatarUrl: account.avatarUrl?.trim().isNotEmpty == true
        ? account.avatarUrl
        : authenticatedUser.avatarUrl,
  );
}

/// Builds a [ProfileAccount] from the authenticated user's data, avoiding
/// placeholder "Anonymous user" values. Used when the profile account hasn't
/// been loaded from the server yet.
@visibleForTesting
ProfileAccount profileAccountFromAuthUser(User authenticatedUser) {
  return ProfileAccount(
    name: authenticatedUser.fullname.trim().isNotEmpty
        ? authenticatedUser.fullname.trim()
        : authenticatedUser.username,
    email: authenticatedUser.email,
    timezone: '',
    avatarUrl: authenticatedUser.avatarUrl,
    username: authenticatedUser.username,
  );
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.state,
    required this.account,
    required this.notifier,
  });

  final UserProfileState state;
  final ProfileAccount account;
  final UserProfileNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 32, 40, 48),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: switch (state.section) {
            UserProfileSection.account => AccountSection(
              account: account,
              isSaving: state.isSaving,
              onSave: notifier.updateAccount,
              onDelete: notifier.deleteAccount,
            ),
            UserProfileSection.notifications => NotificationsSection(
              preferences:
                  state.notifications ?? NotificationPreferences.empty(),
              isSaving: state.isSaving,
              onSave: notifier.updateNotificationPreferences,
              onRevert: notifier.revertNotificationPreferences,
            ),
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
