import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/routing/route_names.dart';
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
import '../cubit/security_cubit.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SecurityCubit>(),
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
    // The sheet lives in the Navigator's overlay, outside this page's
    // providers, so take what it needs before opening it.
    final cubit = context.read<SecurityCubit>();
    AppBottomSheet.show(
      context,
      child: _ChangePasswordForm(
        onSubmit: cubit.changePassword,
        onDone: () {
          Navigator.of(context).pop();
          AppSnackbar.success(context, context.l10n.passwordChanged);
        },
      ),
    );
  }

  void _deleteAccount(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SecurityCubit>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    AppBottomSheet.show(
      context,
      child: _DeleteAccountSheet(
        onConfirm: cubit.deleteAccount,
        onDeleted: () {
          Navigator.of(context).pop();
          router.go(RouteNames.login);
          messenger.showSnackBar(SnackBar(content: Text(l10n.accountDeleted)));
        },
      ),
    );
  }
}

/// Confirms deleting the account with the password, then calls the server.
class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet({required this.onConfirm, required this.onDeleted});

  /// Returns a failure key, or null once the account is deleted.
  final Future<String?> Function(String password) onConfirm;
  final VoidCallback onDeleted;

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'fieldRequired');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await widget.onConfirm(_password.text);
    if (!mounted) return;
    if (failure == null) {
      widget.onDeleted();
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
    return Column(
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
        SizedBox(height: AppSpacing.vLg),
        AppTextField(
          controller: _password,
          label: l10n.password,
          hint: l10n.deleteAccountPasswordHint,
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: true,
        ),
        if (_error != null) ...[
          SizedBox(height: AppSpacing.vSm),
          Text(
            tr(context, _error!),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.error,
            ),
          ),
        ],
        SizedBox(height: AppSpacing.vXl),
        AppButton(
          label: l10n.deleteAccount,
          icon: Icons.delete_outline_rounded,
          isLoading: _busy,
          onPressed: _confirm,
        ),
        SizedBox(height: AppSpacing.vMd),
        AppButton(
          label: l10n.cancel,
          variant: AppButtonVariant.outline,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _ChangePasswordForm extends StatefulWidget {
  const _ChangePasswordForm({required this.onSubmit, required this.onDone});

  /// Returns a failure key, or null once the password was changed.
  final Future<String?> Function(String current, String next) onSubmit;
  final VoidCallback onDone;

  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
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
