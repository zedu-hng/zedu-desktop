/// Represents the user's custom status and online presence.
class UserStatus {
  const UserStatus({
    this.emoji,
    this.text,
    this.expiresAt,
    this.pauseNotifications = false,
    this.online = true,
  });

  final String? emoji;
  final String? text;
  final DateTime? expiresAt;
  final bool pauseNotifications;

  /// true = Active (green dot), false = Away (grey dot).
  final bool online;

  bool get hasCustomStatus =>
      emoji != null || (text != null && text!.isNotEmpty);

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  UserStatus copyWith({
    String? emoji,
    String? text,
    DateTime? expiresAt,
    bool clearExpiry = false,
    bool? pauseNotifications,
    bool? online,
  }) {
    return UserStatus(
      emoji: emoji ?? this.emoji,
      text: text ?? this.text,
      expiresAt: clearExpiry ? null : (expiresAt ?? this.expiresAt),
      pauseNotifications: pauseNotifications ?? this.pauseNotifications,
      online: online ?? this.online,
    );
  }

  UserStatus cleared() => UserStatus(online: online);

  static const empty = UserStatus();
}

/// Duration options for status expiry, matching the Zedu API strings.
enum StatusTimeout {
  thirtyMinutes('30 minutes'),
  oneHour('1 hour'),
  today('today'),
  thisWeek('this week'),
  // The backend rejects "don't remove" ("invalid expiry value"); its accepted
  // never-expire values are "dont-clear" / "don't-clear" / "dont clear" /
  // "don't clear" (see zedu-be Profile.ParseStatusExpiry).
  dontRemove('dont-clear');

  const StatusTimeout(this.apiValue);

  /// The exact string value expected by `profile/change-status` → status_timeout.
  final String apiValue;

  /// Human-readable label shown in the dropdown.
  String get label => switch (this) {
    StatusTimeout.thirtyMinutes => '30 minutes',
    StatusTimeout.oneHour => '1 hour',
    StatusTimeout.today => 'Today',
    StatusTimeout.thisWeek => 'This week',
    StatusTimeout.dontRemove => "Don't remove",
  };
}
