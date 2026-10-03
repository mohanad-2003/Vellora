import 'package:flutter/material.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/localization/l10n_lookup.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/utils/haptics.dart';
import 'package:vellora/core/widgets/app_button.dart';
import 'package:vellora/core/widgets/app_text_field.dart';
import 'package:vellora/core/widgets/auth_error_banner.dart';

/// Bottom-sheet form for writing a product review: pick 1-5 stars and add a
/// comment. [onSubmit] returns a failure key, or null once the review is saved.
class WriteReviewSheet extends StatefulWidget {
  const WriteReviewSheet({
    super.key,
    required this.onSubmit,
    required this.onDone,
  });

  final Future<String?> Function(int rating, String comment) onSubmit;
  final VoidCallback onDone;

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _busy = false;
  String? _fieldError;
  String? _failure;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _comment.text.trim();
    String? problem;
    if (_rating == 0) {
      problem = 'ratingRequired';
    } else if (text.length < 3) {
      problem = 'reviewTooShort';
    }
    if (problem != null) {
      setState(() => _fieldError = problem);
      return;
    }
    setState(() {
      _busy = true;
      _fieldError = null;
      _failure = null;
    });
    final failure = await widget.onSubmit(_rating, text);
    if (!mounted) return;
    if (failure == null) {
      widget.onDone();
    } else {
      setState(() {
        _busy = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.writeReview,
          style: context.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_failure != null) ...[
          AuthErrorBanner(
            failureKey: _failure!,
            onDismiss: () => setState(() => _failure = null),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(l10n.yourRating, style: context.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              Semantics(
                button: true,
                selected: i <= _rating,
                label: '$i',
                child: IconButton(
                  iconSize: 36,
                  // 48dp touch target around each star.
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: _busy
                      ? null
                      : () {
                          Haptics.selection();
                          setState(() {
                            _rating = i;
                            _fieldError = null;
                          });
                        },
                  icon: Icon(
                    i <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i <= _rating ? Colors.amber : colors.outline,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _comment,
          label: l10n.yourReview,
          hint: l10n.reviewHint,
          prefixIcon: Icons.rate_review_outlined,
          maxLines: 4,
        ),
        if (_fieldError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            tr(context, _fieldError!),
            style: context.textTheme.bodySmall?.copyWith(color: colors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: l10n.submitReview,
          icon: Icons.send_rounded,
          isLoading: _busy,
          onPressed: _submit,
        ),
      ],
    );
  }
}
