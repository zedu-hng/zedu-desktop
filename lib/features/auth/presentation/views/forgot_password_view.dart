import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ForgotPasswordView extends ConsumerStatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  ConsumerState<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends ConsumerState<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmitPressed() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authNotifierProvider.notifier)
        .forgotPassword(email: _emailController.text.trim());

    if (success && mounted) {
      AppToastService.show(
        context,
        type: AppToastType.success,
        message: 'Password reset instructions sent!',
      );
      context.go(AppRouter.resetPassword, extra: _emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        AppToastService.show(
          context,
          type: AppToastType.error,
          message: next.error!,
        );
      }
    });

    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: context.colors.background,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('assets/pngs/zedu_logo.png', width: 83, height: 31),
              Text.rich(
                TextSpan(
                  text: 'Remember your password? ',
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: context.colors.textPrimary,
                    fontFamily: FontFamily.roboto,
                  ),
                  children: [
                    TextSpan(
                      text: 'Sign in',
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: context.colors.primary,
                        fontFamily: FontFamily.roboto,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => context.go(AppRouter.login),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                context.gapV(136),
                Text(
                  'Forgot Password',
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                context.gapV(12),
                Text(
                  'Enter the email you used in creating your account, we will send you\ninstructions on how to reset your password.',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                context.gapV(48),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _emailController,
                        label: 'Email address',
                        hint: 'johndoe@email.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _onSubmitPressed(),
                        validator: (value) =>
                            Validators.validateEmail(context, value),
                      ),
                      context.gapV(24),
                      AppButton(
                        label: 'Submit',
                        loading: authState.isLoading,
                        onPressed: _onSubmitPressed,
                      ),
                      context.gapV(16),
                      AppButton.outlined(
                        label: 'Back to Login',
                        onPressed: () => context.go(AppRouter.login),
                      ),
                    ],
                  ),
                ),
                context.gapV(48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
