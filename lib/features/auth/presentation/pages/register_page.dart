import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vellora/core/di/injection.dart';
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
import 'package:vellora/core/widgets/terms_checkbox.dart';
import 'package:vellora/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vellora/features/auth/presentation/widgets/auth_header.dart';
import 'package:vellora/features/auth/presentation/widgets/social_login_buttons.dart';
import 'package:vellora/core/widgets/password_strength_indicator.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _agreedToTerms = false;
  bool _showBanner = false;
  String? _bannerKey;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    context.hideKeyboard();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        ),
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
            if (state.status == AuthStatus.authenticated) {
              context.goNamed(RouteNames.nHome);
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
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                context.pageGutter,
                AppSpacing.sm,
                context.pageGutter,
                AppSpacing.xxl,
              ),
              child: ResponsiveCenter(
                child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeader(
                      showLogo: true,
                      title: l10n.createAccount,
                      subtitle: l10n.registerSubtitle,
                    ),
                    if (_showBanner && _bannerKey != null)
                      AuthErrorBanner(
                        failureKey: _bannerKey!,
                        onDismiss: () => setState(() => _showBanner = false),
                      ),
                    AppTextField(
                      controller: _nameController,
                      label: l10n.fullName,
                      prefixIcon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final key = InputValidators.name(v);
                        return key == null ? null : tr(context, key);
                      },
                    ),
                    SizedBox(height: AppSpacing.vLg),
                    AppTextField(
                      controller: _emailController,
                      label: l10n.email,
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final key = InputValidators.email(v);
                        return key == null ? null : tr(context, key);
                      },
                    ),
                    SizedBox(height: AppSpacing.vLg),
                    AppTextField(
                      controller: _passwordController,
                      label: l10n.password,
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final key = InputValidators.password(v);
                        return key == null ? null : tr(context, key);
                      },
                    ),
                    // Live strength feedback as the user types.
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _passwordController,
                      builder: (_, value, _) =>
                          PasswordStrengthIndicator(password: value.text),
                    ),
                    SizedBox(height: AppSpacing.vLg),
                    AppTextField(
                      controller: _confirmController,
                      label: l10n.confirmPassword,
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) {
                        final key = InputValidators.confirmPassword(
                          v,
                          _passwordController.text,
                        );
                        return key == null ? null : tr(context, key);
                      },
                    ),
                    SizedBox(height: AppSpacing.vLg),
                    TermsCheckbox(
                      value: _agreedToTerms,
                      onChanged: (v) => setState(() => _agreedToTerms = v),
                      onTermsTap: () =>
                          context.pushNamed(RouteNames.nTermsPrivacy),
                    ),
                    SizedBox(height: AppSpacing.vXl),
                    AppButton(
                      label: l10n.register,
                      isLoading: state.isLoading,
                      onPressed: _agreedToTerms ? _submit : null,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _OrDivider(label: l10n.orContinueWith),
                    const SizedBox(height: AppSpacing.xl),
                    const SocialLoginButtons(),
                    const SizedBox(height: AppSpacing.xl),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.alreadyHaveAccount,
                          style: context.textTheme.bodyMedium,
                        ),
                        TextButton(
                          // Swap rather than stack, so Login <-> Sign up never
                          // builds a long back-stack.
                          onPressed: () =>
                              context.pushReplacementNamed(RouteNames.nLogin),
                          child: Text(l10n.login),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(label, style: context.textTheme.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
