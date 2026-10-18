enum TeamMemberStatus { active, pending, inactive }

/// Invites per page, shared by the datasource and the Invites tab.
const invitesPageSize = 20;

class TeamMember {
  const TeamMember({
    required this.id,
    required this.email,
    required this.role,
    required this.dateJoined,
    required this.status,
    this.name,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String role;
  final String dateJoined;
  final TeamMemberStatus status;
  final String? name;
  final String? avatarUrl;

  TeamMember copyWith({
    String? id,
    String? email,
    String? role,
    String? dateJoined,
    TeamMemberStatus? status,
    String? name,
    String? avatarUrl,
  }) {
    return TeamMember(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      dateJoined: dateJoined ?? this.dateJoined,
      status: status ?? this.status,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
