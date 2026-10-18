import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class DmProfileCard extends StatelessWidget {
  final DmConversation conversation;

  const DmProfileCard({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = conversation.displayName;
    final nameParts = name.trim().split(RegExp(r'\s+'));
    final handle = nameParts.length > 1
        ? '@${nameParts.first}_${nameParts.last}'
        : '@${nameParts.first}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 76, 40, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(colors),
          const SizedBox(height: 12),
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
              children: [
                const TextSpan(
                  text: 'This conversation is just between you and ',
                ),
                TextSpan(
                  text: handle,
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const TextSpan(
                  text: '. Check out their profile to learn about them.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _showProfileDialog(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: Text(
              'View Profile',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(AppPalette colors) {
    final name = conversation.displayName;
    final avatarUrl = conversation.effectiveAvatarUrl;
    return CircleAvatar(
      radius: 39,
      backgroundColor: colors.primary,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            )
          : null,
    );
  }

  /// Shows the other person's profile using the details the DM already has.
  void _showProfileDialog(BuildContext context) {
    final colors = context.colors;
    final email = conversation.participantEmail;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(colors),
            const SizedBox(height: 12),
            Text(
              conversation.displayName,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            if (email != null && email.isNotEmpty) ...[
              const SizedBox(height: 6),
              SelectableText(
                email,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
