import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../localization/l10n_lookup.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Inline, dismissible error banner shown at the top of auth forms on failure.
/// Complements (does not replace) the transient [AppSnackbar]. Icon + tone vary
/// by failure category via the failure [l10nKey]. Animates in on mount so it
/// reads as a deliberate alert rather than a layout jump.
class AuthErrorBanner extends StatefulWidget {
  const AuthErrorBanner({
    super.key,
    required this.failureKey,
    required this.onDismiss,
  });

  /// Stable failure key (e.g. `noConnection`, `serverError`, `somethingWentWrong`).
  final String failureKey;
  final VoidCallback onDismiss;

  @override
  State<AuthErrorBanner> createState() => _AuthErrorBannerState();
}

class _AuthErrorBannerState extends State<AuthErrorBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..forward();

  late final Animation<double> _curved =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData get _icon => switch (widget.failureKey) {
        'noConnection' => Icons.wifi_off_rounded,
        'serverError' => Icons.cloud_off_rounded,
        _ => Icons.error_outline_rounded,
      };

  Color get _tone => switch (widget.failureKey) {
        'noConnection' => AppColors.warning,
        _ => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    final tone = _tone;
    return FadeTransition(
      opacity: _controller,
      child: SizeTransition(
        sizeFactor: _curved,
        child: Container(
          margin: EdgeInsets.only(bottom: AppSpacing.vLg),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.vMd,
          ),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.10),
            borderRadius: AppRadius.rMd,
            border: Border.all(color: tone.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(_icon, color: tone, size: 20),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  tr(context, widget.failureKey),
                  style: context.textTheme.bodyMedium?.copyWith(color: tone),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              InkWell(
                onTap: widget.onDismiss,
                borderRadius: AppRadius.rPill,
                child: Icon(Icons.close_rounded, color: tone, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
