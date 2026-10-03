import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/localization/l10n_lookup.dart';
import 'package:vellora/core/responsive/responsive.dart';
import 'package:vellora/core/routing/route_names.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/utils/input_validators.dart';
import 'package:vellora/core/widgets/app_bar_widget.dart';
import 'package:vellora/core/widgets/app_button.dart';
import 'package:vellora/core/widgets/app_text_field.dart';
import 'package:vellora/core/widgets/auth_error_banner.dart';
import 'package:vellora/core/widgets/custom_snackbar.dart';
import 'package:vellora/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vellora/features/auth/presentation/widgets/auth_header.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthBloc is provided by the password-reset ShellRoute so pendingEmail /
    // resetToken persist across the OTP → reset chain.
    return const _ForgotPasswordView();
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _showBanner = false;
  String? _bannerKey;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    context.hideKeyboard();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthForgotPasswordRequested(email: _emailController.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: const AppBarWidget(),
      body: SafeArea(
        top: false,
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.passwordResetSent) {
              context.pushNamed(RouteNames.nOtpVerification);
            } else if (state.status == AuthStatus.failure &&
                state.failureKey != null) {
              setState(() {
                _showBanner = true;
                _bannerKey = state.failureKey;
              });
              AppSnackbar.error(context, tr(context, state.failureKey!));
            }
          },
          builder: (context, state) {
            return ResponsiveCenter(child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.vSm,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeader(
                      showLogo: true,
                      title: l10n.forgotPasswordTitle,
                      subtitle: l10n.forgotPasswordSubtitle,
                    ),
                    if (_showBanner && _bannerKey != null)
                      AuthErrorBanner(
                        failureKey: _bannerKey!,
                        onDismiss: () => setState(() => _showBanner = false),
                      ),
                    AppTextField(
                      controller: _emailController,
                      label: l10n.email,
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) {
                        final key = InputValidators.email(v);
                        return key == null ? null : tr(context, key);
                      },
                    ),
                    SizedBox(height: AppSpacing.vXxl),
                    AppButton(
                      label: l10n.sendResetLink,
                      isLoading: state.isLoading,
                      onPressed: _submit,
                    ),
                    SizedBox(height: AppSpacing.vLg),
                    TextButton.icon(
                      onPressed: () => context.pop(),
                      // Directional arrow: mirrors automatically in RTL.
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(l10n.backToLogin),
                    ),
                  ],
                ),
              ),
            ));
          },
        ),
      ),
    );
  }
}
