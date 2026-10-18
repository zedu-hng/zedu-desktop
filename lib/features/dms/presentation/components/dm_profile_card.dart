import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class DmProfileCard extends StatelessWidget {
  final DmConversation conversation;

  /// Below this width the View Profile button moves under the intro text.
  static const double narrowBreakpoint = 480;

  static const double _avatarRadius = 20;
  static const double _avatarGap = 12;

  const DmProfileCard({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = conversation.displayName;
    final nameParts = name.trim().split(RegExp(r'\s+'));
    final handle = nameParts.length > 1
        ? '@${nameParts.first}_${nameParts.last}'
        : '@${nameParts.first}';

    final avatar = CircleAvatar(
      radius: _avatarRadius,
      backgroundColor: colors.primary,
      backgroundImage: conversation.effectiveAvatarUrl != null
          ? NetworkImage(conversation.effectiveAvatarUrl!)
          : null,
      child: conversation.effectiveAvatarUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )
          : null,
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 13, color: colors.textPrimary),
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
      ],
    );

    final identity = Row(
      children: [
        avatar,
        const SizedBox(width: _avatarGap),
        Expanded(child: details),
      ],
    );

    final viewProfileButton = OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
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
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 24, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < narrowBreakpoint) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(
                    left: _avatarRadius * 2 + _avatarGap,
                  ),
                  child: viewProfileButton,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 16),
              viewProfileButton,
            ],
          );
        },
      ),
    );
  }
}
