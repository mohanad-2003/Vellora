import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/haptics.dart';
import '../../domain/entities/coupon_offer_entity.dart';
import '../../domain/usecases/get_available_coupons_usecase.dart';

/// The coupons the shop lists, as chips to apply with a tap. Shows nothing
/// while loading, when there are none, or when they could not be fetched: the
/// code field above keeps working either way.
class AvailableCoupons extends StatefulWidget {
  const AvailableCoupons({
    super.key,
    required this.onApply,
    this.exclude,
    this.load,
  });

  final ValueChanged<String> onApply;

  /// A code that is already applied, left out of the list.
  final String? exclude;

  /// Fetches the coupons; defaults to the app's use case.
  final Future<List<CouponOfferEntity>> Function()? load;

  @override
  State<AvailableCoupons> createState() => _AvailableCouponsState();
}

class _AvailableCouponsState extends State<AvailableCoupons> {
  List<CouponOfferEntity> _coupons = const [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final coupons = widget.load != null
          ? await widget.load!()
          : (await sl<GetAvailableCouponsUseCase>()(const NoParams()))
              .getOrElse((_) => const []);
      if (mounted) setState(() => _coupons = coupons);
    } catch (_) {
      // The list is a convenience; the code field still works.
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = [
      for (final c in _coupons)
        if (c.code != widget.exclude) c,
    ];
    if (shown.isEmpty) return const SizedBox.shrink();

    final l10n = context.l10n;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.availableCoupons, style: context.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final c in shown)
                Semantics(
                  button: true,
                  label: '${c.code}, ${l10n.couponPercentOff(_percent(c))}',
                  excludeSemantics: true,
                  child: Material(
                    color: colors.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.rMd,
                      side: BorderSide(color: colors.primary.withValues(alpha: 0.35)),
                    ),
                    child: InkWell(
                      borderRadius: AppRadius.rMd,
                      onTap: () {
                        Haptics.light();
                        widget.onApply(c.code);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.code,
                              style: context.textTheme.labelLarge?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _detail(context, c),
                              style: context.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _percent(CouponOfferEntity c) =>
      c.discountPercent.toStringAsFixed(c.discountPercent % 1 == 0 ? 0 : 1);

  static String _detail(BuildContext context, CouponOfferEntity c) {
    final l10n = context.l10n;
    final parts = [
      l10n.couponPercentOff(_percent(c)),
      if (c.minSubtotal != null)
        l10n.couponMinSpend(c.minSubtotal!.toPrice()),
      if (c.firstOrderOnly) l10n.couponFirstOrderOnly,
    ];
    return parts.join(' · ');
  }
}
