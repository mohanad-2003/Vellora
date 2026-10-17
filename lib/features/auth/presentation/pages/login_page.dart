import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/auth_error_banner.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/two_factor_login_dialog.dart';

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
  bool _twoFactorOpen = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _askTwoFactorCode(BuildContext context) async {
    if (_twoFactorOpen) return;
    _twoFactorOpen = true;
    await showTwoFactorLoginDialog(context, context.read<AuthBloc>());
    _twoFactorOpen = false;
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

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.goNamed(RouteNames.nHome);
        } else if (state.status == AuthStatus.twoFactorRequired) {
          _askTwoFactorCode(context);
        } else if (state.status == AuthStatus.failure &&
            state.failureKey != null &&
            // A wrong code is reported inside the dialog instead.
            !_twoFactorOpen) {
          setState(() {
            _showBanner = true;
            _bannerKey = state.failureKey;
          });
          AppSnackbar.error(context, tr(context, state.failureKey!));
        }
      },
      builder: (context, state) {
        return AuthScaffold(
          title: l10n.welcomeBack,
          subtitle: l10n.loginSubtitle,
          switchPrompt: l10n.dontHaveAccount,
          switchLabel: l10n.register,
          // Swap rather than stack (see Register).
          onSwitch: () => context.pushReplacementNamed(RouteNames.nRegister),
          orLabel: l10n.orContinueWith,
          socialMinHeight: 560,
          banner: _showBanner && _bannerKey != null
              ? AuthErrorBanner(
                  failureKey: _bannerKey!,
                  onDismiss: () => setState(() => _showBanner = false),
                )
              : null,
          body: (context, d) => Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _emailController,
                  label: l10n.email,
                  floatingLabel: true,
                  verticalPadding: d.fieldPadding,
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
                SizedBox(height: d.gap),
                AppTextField(
                  controller: _passwordController,
                  label: l10n.password,
                  floatingLabel: true,
                  verticalPadding: d.fieldPadding,
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
                const SizedBox(height: 2),
                // Wraps onto two lines instead of squeezing when the text is
                // long (Arabic) or scaled up.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _RememberMe(
                      value: _rememberMe,
                      label: l10n.rememberMe,
                      onChanged: (v) => setState(() => _rememberMe = v),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.pushNamed(RouteNames.nForgotPassword),
                      child: Text(l10n.forgotPassword),
                    ),
                  ],
                ),
                SizedBox(height: d.gap - 4),
                AppButton(
                  label: l10n.login,
                  isLoading: state.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Checkbox + label as one 44dp-high tap target.
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
          constraints: const BoxConstraints(minHeight: 44),
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
