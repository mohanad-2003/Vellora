import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_snackbar.dart';

/// Opens the confirm-with-password sheet. [onConfirm] deletes the account on
/// the server and returns a failure key, or null once it is gone; the session
/// is then signed out and the user lands on the login screen.
void showDeleteAccountSheet(
  BuildContext context, {
  required Future<String?> Function(String password) onConfirm,
}) {
  final router = GoRouter.of(context);
  // Built now: the page's context is gone by the time the account is deleted.
  final messenger = ScaffoldMessenger.of(context);
  final deletedSnack = AppSnackbar.build(
    context,
    message: context.l10n.accountDeleted,
    type: SnackType.success,
  );
  AppDialog.show(
    context,
    child: DeleteAccountSheet(
      onConfirm: onConfirm,
      onDeleted: () {
        router.go(RouteNames.login);
        messenger.showSnackBar(deletedSnack);
      },
    ),
  );
}

/// Confirms deleting the account with the password, then calls the server.
class DeleteAccountSheet extends StatefulWidget {
  const DeleteAccountSheet({
    super.key,
    required this.onConfirm,
    required this.onDeleted,
  });

  /// Returns a failure key, or null once the account is deleted.
  final Future<String?> Function(String password) onConfirm;
  final VoidCallback onDeleted;

  @override
  State<DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<DeleteAccountSheet> {
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
    if (failure == null) {
      // Clearing the session makes the router replace the page stack, and the
      // sheet goes with the page below it, but its widget stays mounted while
      // it animates out. Popping then would remove the login page instead, so
      // only pop a sheet whose route is still active.
      if (mounted && (ModalRoute.of(context)?.isActive ?? false)) {
        Navigator.of(context).pop();
      }
      widget.onDeleted();
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ConfirmDialogCard(
      icon: Icons.delete_forever_rounded,
      danger: true,
      busy: _busy,
      title: l10n.deleteAccountConfirmTitle,
      message: l10n.deleteAccountConfirmBody,
      confirmLabel: l10n.deleteAccount,
      cancelLabel: l10n.cancel,
      onConfirm: _confirm,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _password,
            label: l10n.password,
            hint: l10n.deleteAccountPasswordHint,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            enabled: !_busy,
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
  }
}
