import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../extensions/context_extensions.dart';
import 'app_text_field.dart';

/// Input for the 6-digit code from an authenticator app.
class TwoFactorCodeField extends StatelessWidget {
  const TwoFactorCodeField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: context.l10n.twoFactorCode,
      hint: '000000',
      prefixIcon: Icons.pin_outlined,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      enabled: enabled,
      autofillHints: const [AutofillHints.oneTimeCode],
      onSubmitted: onSubmitted,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
    );
  }
}
