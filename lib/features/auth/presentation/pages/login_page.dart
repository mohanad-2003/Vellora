import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/auth_error_banner.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/staggered_reveal.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_header.dart';
import '../widgets/social_login_buttons.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _showBanner = false;
  String? _bannerKey;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    context.hideKeyboard();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gutter = context.pageGutter;

    return Scaffold(
      // Back button only when reached from Welcome; Login is also the landing
      // page for returning signed-out users, where there is nothing to pop.
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
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                gutter,
                AppSpacing.sm,
                gutter,
                AppSpacing.xxl,
              ),
              child: ResponsiveCenter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StaggeredReveal(
                        child: AuthHeader(
                          showLogo: true,
                          title: l10n.welcomeBack,
                          subtitle: l10n.loginSubtitle,
                        ),
                      ),
                      if (_showBanner && _bannerKey != null)
                        AuthErrorBanner(
                          failureKey: _bannerKey!,
                          onDismiss: () => setState(() => _showBanner = false),
                        ),
                      StaggeredReveal(
                        delay: const Duration(milliseconds: 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              controller: _emailController,
                              label: l10n.email,
                              hint: 'you@example.com',
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
                            const SizedBox(height: AppSpacing.lg),
                            AppTextField(
                              controller: _passwordController,
                              label: l10n.password,
                              hint: '••••••',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: true,
                              autofillHints: const [AutofillHints.password],
                              autocorrect: false,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              validator: (v) {
                                final key = InputValidators.loginPassword(v);
                                return key == null ? null : tr(context, key);
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            // Wraps onto two lines instead of squeezing when
                            // the text is long (Arabic) or scaled up.
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _RememberMe(
                                  value: _rememberMe,
                                  label: l10n.rememberMe,
                                  onChanged: (v) =>
                                      setState(() => _rememberMe = v),
                                ),
                                TextButton(
                                  onPressed: () => context.pushNamed(
                                    RouteNames.nForgotPassword,
                                  ),
                                  child: Text(l10n.forgotPassword),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppButton(
                              label: l10n.login,
                              isLoading: state.isLoading,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      StaggeredReveal(
                        delay: const Duration(milliseconds: 160),
                        child: Column(
                          children: [
                            _OrDivider(label: l10n.orContinueWith),
                            const SizedBox(height: AppSpacing.xl),
                            const SocialLoginButtons(),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            l10n.dontHaveAccount,
                            style: context.textTheme.bodyMedium,
                          ),
                          TextButton(
                            // Swap rather than stack (see Register).
                            onPressed: () => context.pushReplacementNamed(
                              RouteNames.nRegister,
                            ),
                            child: Text(l10n.register),
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

/// Checkbox + label as one 48dp-high tap target.
class _RememberMe extends StatelessWidget {
  const _RememberMe({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: label,
      excludeSemantics: true,
      onTap: () => onChanged(!value),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 24,
                child: Checkbox(
                  value: value,
                  onChanged: (v) => onChanged(v ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: context.textTheme.bodyMedium),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
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
