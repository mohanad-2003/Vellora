import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_bottom_sheet.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/settings_tile.dart';
import '../cubit/security_cubit.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SecurityCubit(),
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
                        onChanged: cubit.toggleBiometrics,
                      ),
                    ),
                    SettingsTile(
                      icon: Icons.verified_user_outlined,
                      title: l10n.twoFactorAuth,
                      subtitle: l10n.twoFactorAuthSub,
                      trailing: Switch(
                        value: state.twoFactor,
                        onChanged: cubit.toggleTwoFactor,
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
                SizedBox(height: AppSpacing.vXl),
                _Group(
                  children: [
                    SettingsTile(
                      icon: Icons.delete_outline_rounded,
                      title: l10n.deleteAccount,
                      destructive: true,
                      onTap: () => _deleteAccount(context),
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

  void _changePassword(BuildContext context) {
    AppBottomSheet.show(
      context,
      child: _ChangePasswordForm(
        onDone: () {
          Navigator.of(context).pop();
          AppSnackbar.success(context, context.l10n.passwordChanged);
        },
      ),
    );
  }

  void _deleteAccount(BuildContext context) {
    final l10n = context.l10n;
    AppBottomSheet.show(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: context.colors.error,
            size: 48,
          ),
          SizedBox(height: AppSpacing.vMd),
          Text(
            l10n.deleteAccountConfirmTitle,
            style: context.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.vSm),
          Text(
            l10n.deleteAccountConfirmBody,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.vXl),
          AppButton(
            label: l10n.deleteAccount,
            icon: Icons.delete_outline_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              AppSnackbar.show(context, message: l10n.comingSoon);
            },
          ),
          SizedBox(height: AppSpacing.vMd),
          AppButton(
            label: l10n.cancel,
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordForm extends StatefulWidget {
  const _ChangePasswordForm({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onDone();
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
          AppTextField(
            controller: _current,
            label: l10n.currentPassword,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            validator: (v) {
              final key = InputValidators.password(v);
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
