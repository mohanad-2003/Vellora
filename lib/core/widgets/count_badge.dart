import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// Small numeric badge (cart count, unread notifications).
///
/// Hidden at 0 and capped at "99+". Digits are laid out left-to-right in every
/// locale so "99+" never reads as "+99" in Arabic.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, this.maxCount = 99});

  final int count;
  final int maxCount;

  static String format(int count, {int maxCount = 99}) =>
      count > maxCount ? '$maxCount+' : '$count';

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final label = format(count, maxCount: maxCount);
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.vellora.accent,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: context.colors.surface, width: 1.5),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          label,
          maxLines: 1,
          style: context.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 10.5,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
