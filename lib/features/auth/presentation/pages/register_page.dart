import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/localization/l10n_lookup.dart';
import 'package:vellora/core/routing/route_names.dart';
import 'package:vellora/core/utils/input_validators.dart';
import 'package:vellora/core/widgets/app_button.dart';
import 'package:vellora/core/widgets/app_text_field.dart';
import 'package:vellora/core/widgets/auth_error_banner.dart';
import 'package:vellora/core/widgets/custom_snackbar.dart';
import 'package:vellora/core/widgets/terms_checkbox.dart';
import 'package:vellora/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vellora/features/auth/presentation/widgets/auth_scaffold.dart';
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

    return BlocConsumer<AuthBloc, AuthState>(
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
        return AuthScaffold(
          title: l10n.createAccount,
          subtitle: l10n.registerSubtitle,
          switchPrompt: l10n.alreadyHaveAccount,
          switchLabel: l10n.login,
          // Swap rather than stack, so Login <-> Sign up never builds a long
          // back-stack.
          onSwitch: () => context.pushReplacementNamed(RouteNames.nLogin),
          orLabel: l10n.orContinueWith,
          // Four fields and the terms row need the room first.
          socialMinHeight: 700,
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
                  controller: _nameController,
                  label: l10n.fullName,
                  floatingLabel: true,
                  verticalPadding: d.fieldPadding,
                  prefixIcon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final key = InputValidators.name(v);
                    return key == null ? null : tr(context, key);
                  },
                ),
                SizedBox(height: d.gap),
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
                SizedBox(height: d.gap),
                AppTextField(
                  controller: _confirmController,
                  label: l10n.confirmPassword,
                  floatingLabel: true,
                  verticalPadding: d.fieldPadding,
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
                SizedBox(height: d.gap),
                TermsCheckbox(
                  value: _agreedToTerms,
                  onChanged: (v) => setState(() => _agreedToTerms = v),
                  onTermsTap: () => context.pushNamed(RouteNames.nTermsPrivacy),
                ),
                SizedBox(height: d.gap),
                AppButton(
                  label: l10n.register,
                  isLoading: state.isLoading,
                  onPressed: _agreedToTerms ? _submit : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
