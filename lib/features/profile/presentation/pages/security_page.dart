import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/auth_error_banner.dart';
import '../../../../core/widgets/custom_bottom_sheet.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/settings_tile.dart';
import '../../../auth/presentation/bloc/user_session_cubit.dart';
import '../cubit/security_cubit.dart';
import '../widgets/two_factor_dialogs.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SecurityCubit>()
        ..load(context.read<UserSessionCubit>().state?.email),
      child: const _SecurityView(),
    );
  }
}

class _SecurityView extends StatelessWidget {
  const _SecurityView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBarWidget(title: l10n.security),
      body: SafeArea(
        child: BlocBuilder<SecurityCubit, SecurityState>(
          builder: (context, state) {
            final cubit = context.read<SecurityCubit>();
            return ListView(
              padding: EdgeInsets.all(AppSpacing.screenH),
              children: [
                _SectionLabel(label: l10n.signInSecurity),
                SizedBox(height: AppSpacing.vSm),
                _Group(
                  children: [
                    SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: l10n.changePassword,
                      onTap: () => _changePassword(context),
                    ),
                    SettingsTile(
                      icon: Icons.fingerprint_rounded,
                      title: l10n.biometricLogin,
                      subtitle: l10n.biometricLoginSub,
                      trailing: Switch(
                        value: state.biometrics,
                        onChanged: (on) => _toggleBiometrics(context, on),
                      ),
                    ),
                    SettingsTile(
                      icon: Icons.verified_user_outlined,
                      title: l10n.twoFactorAuth,
                      subtitle: l10n.twoFactorAuthSub,
                      trailing: Switch(
                        value: state.twoFactor ?? false,
                        // Disabled until the server says what the state is.
                        onChanged: state.twoFactor == null
                            ? null
                            : (on) => _toggleTwoFactor(context, on),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.vXl),
                _SectionLabel(label: l10n.alerts),
                SizedBox(height: AppSpacing.vSm),
                _Group(
                  children: [
                    SettingsTile(
                      icon: Icons.notifications_active_outlined,
                      title: l10n.loginAlerts,
                      subtitle: l10n.loginAlertsSub,
                      trailing: Switch(
                        value: state.loginAlerts,
                        onChanged: cubit.toggleLoginAlerts,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _toggleBiometrics(BuildContext context, bool enable) async {
    final l10n = context.l10n;
    final result = await context.read<SecurityCubit>().setBiometrics(
      enable: enable,
      email: context.read<UserSessionCubit>().state?.email,
      reason: l10n.biometricReason,
    );
    if (!context.mounted) return;
    switch (result) {
      case BiometricResult.changed:
        AppSnackbar.success(
          context,
          enable ? l10n.biometricEnabled : l10n.biometricDisabled,
        );
      case BiometricResult.unavailable:
        AppSnackbar.error(context, l10n.biometricUnavailable);
      case BiometricResult.cancelled:
        break;
    }
  }

  Future<void> _toggleTwoFactor(BuildContext context, bool enable) async {
    final l10n = context.l10n;
    final cubit = context.read<SecurityCubit>();
    final changed = enable
        ? await showTwoFactorSetupDialog(context, cubit)
        : await showTwoFactorDisableDialog(context, cubit);
    if (changed && context.mounted) {
      AppSnackbar.success(
        context,
        enable ? l10n.twoFactorEnabled : l10n.twoFactorDisabled,
      );
    }
  }

  void _changePassword(BuildContext context) {
    // The sheet lives in the Navigator's overlay, outside this page's
    // providers, so take what it needs before opening it.
    final cubit = context.read<SecurityCubit>();
    AppBottomSheet.show(
      context,
      child: ChangePasswordForm(
        onSubmit: cubit.changePassword,
        onDone: () {
          Navigator.of(context).pop();
          AppSnackbar.success(context, context.l10n.passwordChanged);
        },
      ),
    );
  }
}

@visibleForTesting
class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({
    super.key,
    required this.onSubmit,
    required this.onDone,
  });

  /// Returns a failure key, or null once the password was changed.
  final Future<String?> Function(String current, String next) onSubmit;
  final VoidCallback onDone;

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await widget.onSubmit(_current.text, _next.text);
    if (!mounted) return;
    if (failure == null) {
      widget.onDone();
    } else {
      setState(() {
        _busy = false;
        _error = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.changePassword,
            style: context.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.vLg),
          if (_error != null) ...[
            AuthErrorBanner(
              failureKey: _error!,
              onDismiss: () => setState(() => _error = null),
            ),
            SizedBox(height: AppSpacing.vMd),
          ],
          AppTextField(
            controller: _current,
            label: l10n.currentPassword,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            // Only required: the account may predate the 8-character rule, and
            // the server is what checks that the password is the right one.
            validator: (v) {
              final key = InputValidators.loginPassword(v);
              return key == null ? null : tr(context, key);
            },
          ),
          SizedBox(height: AppSpacing.vMd),
          AppTextField(
            controller: _next,
            label: l10n.newPassword,
            prefixIcon: Icons.lock_reset_rounded,
            obscureText: true,
            validator: (v) {
              final key = InputValidators.password(v);
              return key == null ? null : tr(context, key);
            },
          ),
          SizedBox(height: AppSpacing.vMd),
          AppTextField(
            controller: _confirm,
            label: l10n.confirmNewPassword,
            prefixIcon: Icons.lock_reset_rounded,
            obscureText: true,
            validator: (v) {
              final key = InputValidators.confirmPassword(v, _next.text);
              return key == null ? null : tr(context, key);
            },
          ),
          SizedBox(height: AppSpacing.vXl),
          AppButton(
            label: l10n.updatePassword,
            icon: Icons.check_rounded,
            isLoading: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: AppSpacing.sm),
      child: Text(
        label,
        style: context.textTheme.labelLarge?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: context.colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
                color: context.colors.outlineVariant,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
