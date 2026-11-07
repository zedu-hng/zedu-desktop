import 'package:zedu/features/features.dart';

/// Current user as returned by `GET /profile`.
///
/// The profile payload differs from the login `user` object: it has no
/// organisation block and uses ISO-8601 dates, so it is parsed separately
/// and mapped onto the same [User] entity.
class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.username,
    required this.avatarUrl,
    required this.defaultAvatarUrl,
    required this.createdAt,
    required this.isActive,
    this.isVerified = true,
    this.isOnboarded = true,
    this.currentOrg = '',
    this.currentOrganisationSlug = '',
    this.status = UserStatus.empty,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String username;
  final String avatarUrl;
  final String defaultAvatarUrl;
  final DateTime createdAt;
  final bool isActive;
  final bool isVerified;
  final bool isOnboarded;
  final String currentOrg;
  final String currentOrganisationSlug;

  /// The user's custom status and presence, so they survive a restart.
  final UserStatus status;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      // `id` is the profile row; `userId` is the user the session belongs to.
      id:
          json['userId'] as String? ??
          json['user_id'] as String? ??
          json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      defaultAvatarUrl: json['default_avatar_url'] as String? ?? '',
      createdAt: _parseDate(json['created_at']),
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? true,
      isOnboarded: json['is_onboarded'] as bool? ?? true,
      currentOrg:
          json['organisation_id'] as String? ??
          json['current_org'] as String? ??
          '',
      currentOrganisationSlug:
          json['current_organisation_slug'] as String? ?? '',
      status: _parseStatus(json),
    );
  }

  User toEntity() => User(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    phone: phone,
    username: username,
    isVerified: isVerified,
    isOnboarded: isOnboarded,
    createdAt: createdAt,
    currentOrg: currentOrg,
    currentOrganisationSlug: currentOrganisationSlug,
    avatarUrl: avatarUrl,
    defaultAvatarUrl: defaultAvatarUrl,
    status: status,
  );

  /// Reads `icon`, `text`, `pause_notification`, `status_timeout` and
  /// `online`. Empty strings mean no status, as in `changeStatus`.
  static UserStatus _parseStatus(Map<String, dynamic> json) {
    final icon = json['icon'];
    final text = json['text'];
    final online = json['online'];
    return UserStatus(
      emoji: icon is String && icon.isNotEmpty ? icon : null,
      text: text is String && text.isNotEmpty ? text : null,
      expiresAt: _parseStatusExpiry(json['status_timeout']),
      pauseNotifications: json['pause_notification'] == true,
      online: online is bool ? online : true,
    );
  }

  /// `status_timeout` holds Unix seconds when the server knows the expiry.
  /// It can also be empty or hold the raw value the client sent
  /// ("30 minutes", "dont-clear"). Those give no time, so the status is kept
  /// without an expiry; the server clears it when it runs out.
  static DateTime? _parseStatusExpiry(Object? raw) {
    final seconds = switch (raw) {
      num value => value.toInt(),
      String value => int.tryParse(value.trim()),
      _ => null,
    };
    if (seconds == null || seconds <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  /// Accepts ISO-8601 strings and epoch-seconds strings.
  static DateTime _parseDate(Object? raw) {
    if (raw is String) {
      final iso = DateTime.tryParse(raw);
      if (iso != null) return iso;
      final seconds = int.tryParse(raw);
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
