import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class SecuritySection extends StatefulWidget {
  const SecuritySection({
    super.key,
    required this.sessions,
    required this.isSaving,
    required this.onChangePassword,
  });

  final List<SecuritySession> sessions;
  final bool isSaving;
  final Future<void> Function({
    required String currentPassword,
    required String newPassword,
  })
  onChangePassword;

  @override
  State<SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<SecuritySection> {
  bool _isChangingPassword = false;

  Future<void> _handleChangePassword(BuildContext context) async {
    await showChangePasswordDialog(
      context,
      ({required currentPassword, required newPassword}) async {
        setState(() => _isChangingPassword = true);
        try {
          await widget.onChangePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
        } finally {
          if (mounted) setState(() => _isChangingPassword = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Your Account Security',
          subtitle: 'Keeping your data secure by staying in-the-know',
          trailing: AppButton.outlined(
            label: 'Change password',
            expand: false,
            height: 44,
            loading: _isChangingPassword,
            onPressed: () => _handleChangePassword(context),
          ),
        ),
        const SizedBox(height: 28),
        _SessionsTable(sessions: widget.sessions),
      ],
    );
  }
}

class _SessionsTable extends StatelessWidget {
  const _SessionsTable({required this.sessions});

  final List<SecuritySession> sessions;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 800),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFFAFAFA)),
            columns: const [
              DataColumn(label: Text('Device')),
              DataColumn(label: Text('Location')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Last active')),
              DataColumn(label: Text('Status')),
            ],
            rows: sessions.map((session) {
              return DataRow(
                cells: [
                  DataCell(Text(session.device)),
                  DataCell(Text(session.location)),
                  DataCell(Text(session.date)),
                  DataCell(Text(session.lastActive)),
                  DataCell(ProfileStatusPill(status: session.status)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
