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
import 'package:vellora/core/widgets/custom_snackbar.dart';
import 'package:vellora/core/widgets/password_strength_indicator.dart';
import 'package:vellora/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vellora/features/auth/presentation/widgets/auth_header.dart';

class CreateNewPasswordPage extends StatefulWidget {
  const CreateNewPasswordPage({super.key});

  @override
  State<CreateNewPasswordPage> createState() => _CreateNewPasswordPageState();
}

class _CreateNewPasswordPageState extends State<CreateNewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _password = '';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    context.hideKeyboard();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthResetPasswordRequested(newPassword: _passwordController.text),
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
            if (state.status == AuthStatus.passwordResetSuccess) {
              context.pushNamed(RouteNames.nPasswordResetSuccess);
            } else if (state.status == AuthStatus.failure &&
                state.failureKey != null) {
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
                      icon: Icons.lock_reset_rounded,
                      title: l10n.resetPasswordTitle,
                      subtitle: l10n.resetPasswordSubtitle,
                    ),
                    AppTextField(
                      controller: _passwordController,
                      label: l10n.newPassword,
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      onChanged: (v) => setState(() => _password = v),
                      validator: (v) {
                        final key = InputValidators.password(v);
                        return key == null ? null : tr(context, key);
                      },
                    ),
                    PasswordStrengthIndicator(password: _password),
                    SizedBox(height: AppSpacing.vLg),
                    AppTextField(
                      controller: _confirmController,
                      label: l10n.confirmNewPassword,
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
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
                    SizedBox(height: AppSpacing.vXxl),
                    AppButton(
                      label: l10n.resetPassword,
                      isLoading: state.isLoading,
                      onPressed: _submit,
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
