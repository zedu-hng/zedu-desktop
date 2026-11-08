import 'package:zedu/core/core.dart';

class ProfileFieldLabel extends StatelessWidget {
  const ProfileFieldLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.textTheme.labelSmall?.copyWith(
        color: context.colors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 32,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.divider),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: size * 0.56, color: context.colors.textPrimary),
      ),
    );
  }
}

class ProfileStatusPill extends StatelessWidget {
  const ProfileStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? context.colors.successBg : context.colors.errorBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive
                  ? context.colors.presenceActive
                  : context.colors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: context.textTheme.labelSmall?.copyWith(
              color: isActive ? context.colors.success : context.colors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
