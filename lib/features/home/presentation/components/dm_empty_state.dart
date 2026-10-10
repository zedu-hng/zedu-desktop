import 'package:zedu/core/core.dart';

/// Shown on the right of the DMs tab when no conversation is selected.
class DmEmptyState extends StatelessWidget {
  const DmEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.background,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 123,
                height: 123,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/svgs/dm_empty_chat.svg',
                  width: 60,
                  height: 56,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your messages',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 28.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Select a conversation from the list to start messaging.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color.lerp(
                    colors.textPrimary,
                    colors.primary,
                    0.28,
                  )!.withValues(alpha: 0.64),
                  fontSize: 16.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
