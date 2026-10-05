import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/two_factor_code_field.dart';
import '../bloc/auth_bloc.dart';

/// Asks for the authenticator code after the password was accepted. The dialog
/// lives above the page's providers, so the page hands over its [bloc].
Future<void> showTwoFactorLoginDialog(BuildContext context, AuthBloc bloc) {
  return AppDialog.show<void>(
    context,
    child: BlocProvider.value(value: bloc, child: const _TwoFactorLoginCard()),
  );
}

class _TwoFactorLoginCard extends StatefulWidget {
  const _TwoFactorLoginCard();

  @override
  State<_TwoFactorLoginCard> createState() => _TwoFactorLoginCardState();
}

class _TwoFactorLoginCardState extends State<_TwoFactorLoginCard> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (_code.text.length != 6) {
      setState(() => _error = 'fieldRequired');
      return;
    }
    setState(() => _error = null);
    context.read<AuthBloc>().add(AuthTwoFactorSubmitted(code: _code.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          // The login page navigates home; close this dialog if it is still
          // the top route (the router may already have removed it).
          if (ModalRoute.of(context)?.isActive ?? false) {
            Navigator.of(context).pop();
          }
        } else if (state.status == AuthStatus.failure) {
          setState(() => _error = state.failureKey);
        }
      },
      builder: (context, state) {
        final busy = state.status == AuthStatus.loading;
        return ConfirmDialogCard(
          icon: Icons.verified_user_outlined,
          title: l10n.twoFactorDialogTitle,
          message: l10n.twoFactorDialogBody,
          confirmLabel: l10n.verify,
          cancelLabel: l10n.cancel,
          busy: busy,
          onConfirm: _submit,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TwoFactorCodeField(
                controller: _code,
                enabled: !busy,
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  tr(context, _error!),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
