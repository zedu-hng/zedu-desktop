import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ReferralView extends ConsumerWidget {
  const ReferralView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final user = ref.watch(authNotifierProvider).user;
    final username = user?.username.isNotEmpty == true
        ? user!.username.toLowerCase()
        : 'member';
    final referralCode = 'ZEDU-${username.toUpperCase()}';
    final referralLink = 'https://zedu.chat/join?ref=$referralCode';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: colors.divider)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                    tooltip: 'Back to Home',
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRouter.home);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Referrals & Rewards',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${user?.creditBalance ?? 0} Credits',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Referral Hero Card
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colors.primary, const Color(0xFF4338CA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invite Friends, Earn 50 Credits',
                                style: textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Share your referral link with friends and colleagues. '
                                'When they join Zedu, both of you earn 50 AI credits.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        referralLink,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.copy, size: 16),
                                      label: const Text('Copy Link'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colors.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: referralLink),
                                        );
                                        AppToastService.show(
                                          context,
                                          type: AppToastType.success,
                                          message:
                                              'Referral link copied to clipboard!',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Stats Grid
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Total Invited',
                                value: '0',
                                icon: Icons.people_outline,
                                iconColor: colors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: _StatCard(
                                title: 'Successful Signups',
                                value: '0',
                                icon: Icons.check_circle_outline,
                                iconColor: Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: _StatCard(
                                title: 'Credits Earned',
                                value: '0',
                                icon: Icons.card_giftcard_outlined,
                                iconColor: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // How it Works Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How Referrals Work',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const _StepRow(
                                stepNumber: '1',
                                title: 'Share your link',
                                description:
                                    'Send your personalized link or referral code to teammates or friends.',
                              ),
                              const SizedBox(height: 16),
                              const _StepRow(
                                stepNumber: '2',
                                title: 'They join Zedu',
                                description:
                                    'Your referrals register an account and start using the workspace.',
                              ),
                              const SizedBox(height: 16),
                              const _StepRow(
                                stepNumber: '3',
                                title: 'Get rewarded',
                                description:
                                    'Both you and your referral instantly receive 50 AI credits.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // History / Empty State
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.divider),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.group_add_outlined,
                                size: 48,
                                color: colors.textHint,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No Referrals Yet',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Share your referral link above to start inviting teammates and earning rewards.',
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.stepNumber,
    required this.title,
    required this.description,
  });

  final String stepNumber;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
