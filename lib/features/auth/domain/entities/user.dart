import 'user_status.dart';

class User {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.fullName = '',
    required this.email,
    required this.phone,
    required this.username,
    required this.isVerified,
    required this.isOnboarded,
    required this.createdAt,
    required this.currentOrg,
    required this.currentOrganisationSlug,
    required this.avatarUrl,
    required this.defaultAvatarUrl,
    this.creditBalance = 0,
    this.subscriptionPlanId = 'free',
    this.aiCreditsPurchasable = true,
    this.status = UserStatus.empty,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String phone;
  final String username;
  final bool isVerified;
  final bool isOnboarded;
  final DateTime createdAt;
  final String currentOrg;
  final String currentOrganisationSlug;
  final String avatarUrl;
  final String defaultAvatarUrl;
  final int creditBalance;
  final String subscriptionPlanId;
  final bool aiCreditsPurchasable;

  /// Live presence and custom status for this user.
  final UserStatus status;

  String get fullname =>
      fullName.trim().isNotEmpty ? fullName : '$firstName $lastName';
}
