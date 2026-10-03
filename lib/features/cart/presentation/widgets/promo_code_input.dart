import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/haptics.dart';
import '../../domain/entities/promo_code_entity.dart';

/// Promo-code field with Apply button, applied state and inline error.
class PromoCodeInput extends StatefulWidget {
  const PromoCodeInput({
    super.key,
    required this.applied,
    required this.isApplying,
    required this.hasError,
    required this.onApply,
    required this.onRemove,
  });

  final PromoCodeEntity? applied;
  final bool isApplying;
  final bool hasError;
  final ValueChanged<String> onApply;
  final VoidCallback onRemove;

  @override
  State<PromoCodeInput> createState() => _PromoCodeInputState();
}

class _PromoCodeInputState extends State<PromoCodeInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.isEmpty || widget.isApplying) return;
    Haptics.light();
    widget.onApply(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final success = context.vellora.success;

    if (widget.applied != null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: success.withValues(alpha: 0.12),
          borderRadius: AppRadius.rMd,
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: success, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                '${widget.applied!.code} (-${widget.applied!.discountPercent.toInt()}%)',
                style: context.textTheme.titleSmall,
              ),
            ),
            TextButton(
              onPressed: widget.onRemove,
              child: Text(l10n.removeItem),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: l10n.promoCode,
              prefixIcon: const Icon(Icons.local_offer_outlined),
              errorText: widget.hasError ? l10n.invalidPromo : null,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: widget.isApplying ? null : _submit,
            child: widget.isApplying
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.apply),
          ),
        ),
      ],
    );
  }
}
