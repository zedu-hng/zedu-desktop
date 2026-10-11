import 'package:zedu/features/features.dart';

enum UserProfileSection {
  account,
  notifications,
  security,
  organization,
  userManagement,
  rolesAndPermissions,
  billing,
}

class UserProfileState {
  const UserProfileState({
    this.section = UserProfileSection.account,
    this.account,
    this.notifications,
    this.organization,
    this.securitySessions = const [],
    this.teamMembers = const [],
    this.invites = const [],
    this.invitesPage = 1,
    this.isInvitesLoading = false,
    this.rolesAndPermissions = const [],
    this.billing,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  final UserProfileSection section;
  final ProfileAccount? account;
  final NotificationPreferences? notifications;
  final OrganizationProfile? organization;
  final List<SecuritySession> securitySessions;
  final List<TeamMember> teamMembers;
  final List<TeamMember> invites;
  final int invitesPage;
  final bool isInvitesLoading;
  final List<RolePermission> rolesAndPermissions;
  final BillingInfo? billing;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  UserProfileState copyWith({
    UserProfileSection? section,
    ProfileAccount? account,
    NotificationPreferences? notifications,
    OrganizationProfile? organization,
    List<SecuritySession>? securitySessions,
    List<TeamMember>? teamMembers,
    List<TeamMember>? invites,
    int? invitesPage,
    bool? isInvitesLoading,
    List<RolePermission>? rolesAndPermissions,
    BillingInfo? billing,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return UserProfileState(
      section: section ?? this.section,
      account: account ?? this.account,
      notifications: notifications ?? this.notifications,
      organization: organization ?? this.organization,
      securitySessions: securitySessions ?? this.securitySessions,
      teamMembers: teamMembers ?? this.teamMembers,
      invites: invites ?? this.invites,
      invitesPage: invitesPage ?? this.invitesPage,
      isInvitesLoading: isInvitesLoading ?? this.isInvitesLoading,
      rolesAndPermissions: rolesAndPermissions ?? this.rolesAndPermissions,
      billing: billing ?? this.billing,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}
