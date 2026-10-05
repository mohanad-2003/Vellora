import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/two_factor_code_field.dart';
import '../../../auth/domain/entities/two_factor_setup.dart';
import '../cubit/security_cubit.dart';

/// Walks the user through adding the account to an authenticator app and
/// confirming with a code. True once two-factor is on.
Future<bool> showTwoFactorSetupDialog(
  BuildContext context,
  SecurityCubit cubit,
) async {
  final done = await AppDialog.show<bool>(
    context,
    child: _SetupCard(cubit: cubit),
  );
  return done ?? false;
}

/// Asks for the password and a current code, then turns two-factor off. True
/// once it is off.
Future<bool> showTwoFactorDisableDialog(
  BuildContext context,
  SecurityCubit cubit,
) async {
  final done = await AppDialog.show<bool>(
    context,
    child: _DisableCard(cubit: cubit),
  );
  return done ?? false;
}

void _closeWith(BuildContext context, bool result) {
  if (context.mounted && (ModalRoute.of(context)?.isActive ?? false)) {
    Navigator.of(context).pop(result);
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.error);

  final String? error;

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        tr(context, error!),
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.error,
        ),
      ),
    );
  }
}

class _SetupCard extends StatefulWidget {
  const _SetupCard({required this.cubit});

  final SecurityCubit cubit;

  @override
  State<_SetupCard> createState() => _SetupCardState();
}

class _SetupCardState extends State<_SetupCard> {
  final _code = TextEditingController();
  TwoFactorSetup? _setup;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await widget.cubit.startTwoFactorSetup();
    if (!mounted) return;
    setState(() {
      _setup = result.setup;
      _error = result.error;
    });
  }

  Future<void> _confirm() async {
    if (_setup == null) return;
    if (_code.text.length != 6) {
      setState(() => _error = 'fieldRequired');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await widget.cubit.enableTwoFactor(_code.text);
    if (!mounted) return;
    if (failure == null) {
      _closeWith(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = failure;
      });
    }
  }

  /// "ABCD EFGH ..." so the key is easy to read and type.
  String _grouped(String secret) =>
      RegExp('.{1,4}').allMatches(secret).map((m) => m.group(0)).join(' ');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final setup = _setup;
    return ConfirmDialogCard(
      icon: Icons.verified_user_outlined,
      title: l10n.twoFactorSetupTitle,
      message: l10n.twoFactorSetupBody,
      confirmLabel: l10n.twoFactorTurnOn,
      cancelLabel: l10n.cancel,
      busy: _busy,
      onConfirm: setup == null ? () {} : _confirm,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (setup == null && _error == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (setup != null) ...[
            Text(l10n.twoFactorKeyLabel, style: context.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: AppRadius.rMd,
              ),
              child: SelectableText(
                _grouped(setup.secret),
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: context.textTheme.titleMedium?.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l10n.copyKey,
              icon: Icons.copy_rounded,
              variant: AppButtonVariant.text,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: setup.secret));
                if (context.mounted) {
                  AppSnackbar.success(context, l10n.keyCopied);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TwoFactorCodeField(
              controller: _code,
              enabled: !_busy,
              onSubmitted: (_) => _confirm(),
            ),
          ],
          _ErrorText(_error),
        ],
      ),
    );
  }
}

class _DisableCard extends StatefulWidget {
  const _DisableCard({required this.cubit});

  final SecurityCubit cubit;

  @override
  State<_DisableCard> createState() => _DisableCardState();
}

class _DisableCardState extends State<_DisableCard> {
  final _password = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_password.text.isEmpty || _code.text.length != 6) {
      setState(() => _error = 'fieldRequired');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await widget.cubit.disableTwoFactor(
      _password.text,
      _code.text,
    );
    if (!mounted) return;
    if (failure == null) {
      _closeWith(context, true);
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
    return ConfirmDialogCard(
      icon: Icons.shield_outlined,
      danger: true,
      title: l10n.twoFactorDisableTitle,
      message: l10n.twoFactorDisableBody,
      confirmLabel: l10n.turnOff,
      cancelLabel: l10n.cancel,
      busy: _busy,
      onConfirm: _confirm,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _password,
            label: l10n.password,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            enabled: !_busy,
          ),
          const SizedBox(height: AppSpacing.md),
          TwoFactorCodeField(
            controller: _code,
            enabled: !_busy,
            onSubmitted: (_) => _confirm(),
          ),
          _ErrorText(_error),
        ],
      ),
    );
  }
}
