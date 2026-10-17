import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class UserManagementSection extends StatefulWidget {
  const UserManagementSection({
    super.key,
    required this.members,
    required this.invites,
    required this.invitesPage,
    required this.isInvitesLoading,
    required this.invitesLoadFailed,
    required this.onLoadInvites,
    required this.onDeleteInvite,
    required this.isSaving,
    required this.onInvite,
    required this.onUpdate,
    required this.onRemove,
  });

  final List<TeamMember> members;
  final List<TeamMember> invites;
  final int invitesPage;
  final bool isInvitesLoading;
  final bool invitesLoadFailed;
  final Future<void> Function({int page, String search}) onLoadInvites;
  final Future<void> Function(String inviteId) onDeleteInvite;
  final bool isSaving;
  final Future<void> Function({required String email, required String role})
  onInvite;
  final ValueChanged<TeamMember> onUpdate;
  final ValueChanged<String> onRemove;

  @override
  State<UserManagementSection> createState() => _UserManagementSectionState();
}

class _UserManagementSectionState extends State<UserManagementSection> {
  final _searchController = TextEditingController();
  final _inviteSearchController = TextEditingController();
  String _inviteSearch = '';
  String _roleFilter = 'All Roles';
  bool _showInvites = false;

  @override
  void dispose() {
    _searchController.dispose();
    _inviteSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.members.where((member) {
      final matchesQuery =
          query.isEmpty || member.email.toLowerCase().contains(query);
      final matchesRole =
          _roleFilter == 'All Roles' || member.role == _roleFilter;
      return matchesQuery && matchesRole;
    }).toList();

    if (_showInvites) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [..._headerAndTabs(context), _invitesCard(context)],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._headerAndTabs(context),
        ProfileCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search by name or email',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _roleFilter,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'All Roles',
                          child: Text('All Roles'),
                        ),
                        DropdownMenuItem(
                          value: 'Administrator',
                          child: Text('Administrator'),
                        ),
                        DropdownMenuItem(
                          value: 'Manager',
                          child: Text('Manager'),
                        ),
                        DropdownMenuItem(value: 'User', child: Text('User')),
                      ],
                      onChanged: (value) => setState(() {
                        _roleFilter = value ?? 'All Roles';
                      }),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 880,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFFAFAFA),
                    ),
                    columns: const [
                      DataColumn(label: Text('Email Address')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Date Joined')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: filtered.map((member) {
                      return DataRow(
                        cells: [
                          DataCell(_MemberIdentity(email: member.email)),
                          DataCell(Text(member.role)),
                          DataCell(Text(member.dateJoined)),
                          DataCell(
                            ProfileStatusPill(status: member.status.name),
                          ),
                          DataCell(
                            Row(
                              children: [
                                SquareIconButton(
                                  icon: Icons.edit_outlined,
                                  size: 28,
                                  onTap: () => _showMemberDialog(
                                    context,
                                    member,
                                    widget.onUpdate,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SquareIconButton(
                                  icon: Icons.delete_outline,
                                  size: 28,
                                  onTap: () => _confirmRemove(
                                    context,
                                    member.email,
                                    () async => widget.onRemove(member.id),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    AppButton.outlined(
                      label: 'Previous',
                      expand: false,
                      height: 36,
                      disabled: true,
                    ),
                    const Spacer(),
                    Text('1', style: context.textTheme.bodySmall),
                    const Spacer(),
                    AppButton.outlined(
                      label: 'Next',
                      expand: false,
                      height: 36,
                      disabled: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _headerAndTabs(BuildContext context) => [
    ProfileSectionHeader(
      title: 'Your Team',
      subtitle: 'Manage all members of your team.',
      trailing: AppButton(
        label: 'Invite People',
        expand: false,
        height: 44,
        loading: widget.isSaving,
        onPressed: () => _showInviteDialog(context, widget.onInvite),
      ),
    ),
    const SizedBox(height: 34),
    Row(
      children: [
        InkWell(
          onTap: () => setState(() => _showInvites = false),
          child: _TabLabel(
            label: 'Members',
            count: widget.members.length,
            active: !_showInvites,
          ),
        ),
        const SizedBox(width: 32),
        InkWell(
          onTap: () => setState(() => _showInvites = true),
          child: _TabLabel(
            label: 'Invites',
            count: widget.invites.length,
            active: _showInvites,
          ),
        ),
      ],
    ),
    const SizedBox(height: 24),
  ];

  Widget _invitesCard(BuildContext context) {
    final invites = widget.invites;
    final page = widget.invitesPage;
    return ProfileCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 300,
                child: TextField(
                  controller: _inviteSearchController,
                  onSubmitted: (value) {
                    _inviteSearch = value.trim();
                    widget.onLoadInvites(search: _inviteSearch);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by email',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.isInvitesLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            )
          else if (invites.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Text(
                widget.invitesLoadFailed
                    ? "Couldn't load invites."
                    : 'No invites found',
                style: context.textTheme.bodyMedium,
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 880,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFFAFAFA),
                  ),
                  columns: const [
                    DataColumn(label: Text('Email Address')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Date Invited')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: [
                    for (final invite in invites)
                      DataRow(
                        cells: [
                          DataCell(_MemberIdentity(email: invite.email)),
                          DataCell(Text(invite.role)),
                          DataCell(Text(_formatDate(invite.dateJoined))),
                          const DataCell(ProfileStatusPill(status: 'invited')),
                          DataCell(
                            SquareIconButton(
                              icon: Icons.delete_outline,
                              size: 28,
                              onTap: () => showProfileConfirmDialog(
                                context,
                                title: 'Delete invite?',
                                message:
                                    'The invite sent to ${invite.email} will be cancelled.',
                                confirmLabel: 'Delete invite',
                                destructive: true,
                                onConfirm: () =>
                                    widget.onDeleteInvite(invite.id),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AppButton.outlined(
                  label: 'Previous',
                  expand: false,
                  height: 36,
                  disabled: page <= 1 || widget.isInvitesLoading,
                  onPressed: () => widget.onLoadInvites(
                    page: page - 1,
                    search: _inviteSearch,
                  ),
                ),
                const Spacer(),
                Text('$page', style: context.textTheme.bodySmall),
                const Spacer(),
                AppButton.outlined(
                  label: 'Next',
                  expand: false,
                  height: 36,
                  disabled:
                      invites.length < invitesPageSize ||
                      widget.isInvitesLoading,
                  onPressed: () => widget.onLoadInvites(
                    page: page + 1,
                    search: _inviteSearch,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(
    BuildContext context,
    Future<void> Function({required String email, required String role})
    onInvite,
  ) => showInviteMemberDialog(context, onInvite);

  void _showMemberDialog(
    BuildContext context,
    TeamMember member,
    ValueChanged<TeamMember> onUpdate,
  ) => showEditMemberDialog(context, member, onUpdate);

  Future<void> _confirmRemove(
    BuildContext context,
    String email,
    Future<void> Function() onConfirm,
  ) => showProfileConfirmDialog(
    context,
    title: 'Remove team member?',
    message: '$email will lose access to this organization.',
    confirmLabel: 'Remove member',
    onConfirm: onConfirm,
    destructive: true,
  );
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.count,
    required this.active,
  });
  final String label;
  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? context.colors.sidebar
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFE9E9FF)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: context.textTheme.labelSmall?.copyWith(
                  color: active
                      ? context.colors.sidebar
                      : const Color(0xFF6B7280),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        if (active) ...[
          const SizedBox(height: 8),
          Container(height: 2, width: 80, color: context.colors.sidebar),
        ],
      ],
    );
  }
}

String _formatDate(String iso) {
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) return iso;
  const months =
      'January February March April May June July August September October November December';
  return '${months.split(' ')[date.month - 1]} ${date.day}, ${date.year}';
}

class _MemberIdentity extends StatelessWidget {
  const _MemberIdentity({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFE9FBFA),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.person, size: 18, color: Color(0xFF17C9BD)),
          ),
        ),
        const SizedBox(width: 12),
        Text(email, style: context.textTheme.bodyMedium),
      ],
    );
  }
}
