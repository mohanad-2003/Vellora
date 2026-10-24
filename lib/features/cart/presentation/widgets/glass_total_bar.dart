import 'package:flutter/material.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/extensions/num_extensions.dart';
import 'package:vellora/core/theme/app_colors.dart';
import 'package:vellora/core/utils/haptics.dart';
import 'package:vellora/core/widgets/glass_panel.dart';

/// The cart's and checkout's bottom bar on frosted glass: the total on the start
/// side and the champagne call to action. A null [onPressed] (or [loading])
/// keeps the button inert.
///
/// The page scrolls under it, so the page leaves [clearance] at its end.
class GlassTotalBar extends StatelessWidget {
  const GlassTotalBar({
    super.key,
    required this.total,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.savings,
  });

  final double total;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  /// What the shopper saves with the current discount, shown under the total.
  final double? savings;

  /// Height the page keeps free at its end for the bar and its margins.
  static const double clearance = 96;

  static const double _height = 64;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final enabled = onPressed != null && !loading;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: GlassPanel(
            radius: _height / 2,
            child: SizedBox(
              height: _height,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 14,
                        end: 8,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 112),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.total,
                                style: text.labelSmall?.copyWith(
                                  color: GlassPanel.inkMuted(context),
                                ),
                              ),
                              Text(
                                total.toPrice(),
                                maxLines: 1,
                                style: text.titleMedium?.copyWith(
                                  color: GlassPanel.ink(context),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (savings != null && savings! > 0)
                                Text(
                                  '-${savings!.toPrice()}',
                                  maxLines: 1,
                                  style: text.labelSmall?.copyWith(
                                    color: context.isDark
                                        ? kBrandAccent
                                        : context.vellora.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Semantics(
                        button: true,
                        enabled: enabled,
                        label: label,
                        excludeSemantics: true,
                        onTap: enabled ? onPressed : null,
                        child: Opacity(
                          opacity: onPressed == null ? 0.4 : 1,
                          child: Material(
                            color: kBrandAccent,
                            shape: const StadiumBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: enabled
                                  ? () {
                                      Haptics.light();
                                      onPressed!();
                                    }
                                  : null,
                              child: SizedBox(
                                height: 52,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: loading
                                        ? const SizedBox.square(
                                            dimension: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: kBrandNavy,
                                            ),
                                          )
                                        : FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (icon != null) ...[
                                                  Icon(
                                                    icon,
                                                    size: 20,
                                                    color: kBrandNavy,
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                                Text(
                                                  label,
                                                  maxLines: 1,
                                                  softWrap: false,
                                                  style: text.labelLarge
                                                      ?.copyWith(
                                                        color: kBrandNavy,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
