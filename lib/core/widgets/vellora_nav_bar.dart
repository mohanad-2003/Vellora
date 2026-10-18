import 'package:flutter/material.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/theme/app_colors.dart';
import 'package:vellora/core/theme/app_radius.dart';
import 'package:vellora/core/utils/haptics.dart';

import 'count_badge.dart';
import 'glass_panel.dart';

/// One destination in the main navigation.
class NavDestinationItem {
  const NavDestinationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
    this.showDot = false,
    this.iconKey,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badgeCount;

  /// A small red dot (something is waiting there), when there is no count.
  final bool showDot;

  /// Marks the icon so something can be flown to it (the cart's).
  final Key? iconKey;
}

/// Bottom navigation: a floating pill of frosted deep-emerald glass. The page
/// scrolls under it (blurred and tinted), so it is clear glass, not a white
/// slab. The chosen destination opens into a champagne capsule with its icon
/// and name; the others are pale icons. A count badge pulses when it grows, and
/// a dot can mark a destination that needs a look.
///
/// The body must extend behind the bar (`Scaffold.extendBody`) and tab pages
/// leave `context.navClearance` at the end of their scrolling content.
///
/// Every item is at least 48dp tall, the name is one line and scales down
/// instead of overflowing, and the bar never grows wider than a phone.
class VelloraNavBar extends StatelessWidget {
  const VelloraNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<NavDestinationItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const double barHeight = 64;
  static const double _inset = 6;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: GlassPanel(
              radius: barHeight / 2,
              child: SizedBox(
                height: barHeight,
                child: Padding(
                  padding: const EdgeInsets.all(_inset),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final width = c.maxWidth;
                      final selectedWidth = (width * 0.4).clamp(104.0, 160.0);
                      final others = items.length > 1 ? items.length - 1 : 1;
                      final otherWidth = (width - selectedWidth) / others;
                      return Row(
                        children: [
                          for (var i = 0; i < items.length; i++)
                            _NavItem(
                              item: items[i],
                              selected: i == currentIndex,
                              width: i == currentIndex
                                  ? selectedWidth
                                  : otherWidth,
                              onTap: () {
                                if (i != currentIndex) Haptics.selection();
                                onSelected(i);
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The glass colours (shared with the other glass panels).
  static const Color glassDark = GlassPanel.glassDark;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final NavDestinationItem item;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Champagne capsule with deep emerald content on the glass; pale icons for
    // the rest. The same in light and dark, so the bar is one brand object.
    const capsule = kBrandGold;
    const onCapsule = kBrandNavy;
    final iconColor = selected ? onCapsule : GlassPanel.inkMuted(context);
    const labelColor = onCapsule;

    return Semantics(
      button: true,
      selected: selected,
      label: item.badgeCount > 0
          ? '${item.label}, ${context.l10n.cartItemsCount(item.badgeCount)}'
          : item.label,
      excludeSemantics: true,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: selected ? capsule : Colors.transparent,
          borderRadius: AppRadius.rPill,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.rPill,
          child: ClipRect(
            // The name appears while the capsule is still opening; clip rather
            // than overflow for those few frames.
            child: OverflowBox(
              maxWidth: double.infinity,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Icon(item: item, selected: selected, color: iconColor),
                  if (selected) ...[
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: (width - 24 - 6 - 14).clamp(0.0, 200.0),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          softWrap: false,
                          style: context.textTheme.labelLarge?.copyWith(
                            color: labelColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The icon: outline turns into filled with a small spring, and a badge or dot
/// sits on its corner.
class _Icon extends StatelessWidget {
  const _Icon({
    required this.item,
    required this.selected,
    required this.color,
  });

  final NavDestinationItem item;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: item.iconKey,
      clipBehavior: Clip.none,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutBack,
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            selected ? item.selectedIcon : item.icon,
            key: ValueKey(selected),
            size: 24,
            color: color,
          ),
        ),
        if (item.badgeCount > 0)
          PositionedDirectional(
            top: -8,
            end: -10,
            child: PulseOnChange(
              value: item.badgeCount,
              child: CountBadge(
                count: item.badgeCount,
                borderColor: GlassPanel.surface(context),
              ),
            ),
          )
        else if (item.showDot)
          PositionedDirectional(
            top: -3,
            end: -3,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: context.vellora.sale,
                shape: BoxShape.circle,
                border: Border.all(
                  color: GlassPanel.surface(context),
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Scales [child] up and back with a spring each time [value] goes up.
class PulseOnChange extends StatefulWidget {
  const PulseOnChange({super.key, required this.value, required this.child});

  final int value;
  final Widget child;

  @override
  State<PulseOnChange> createState() => _PulseOnChangeState();
}

class _PulseOnChangeState extends State<PulseOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.45,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.45,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 70,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(PulseOnChange old) {
    super.didUpdateWidget(old);
    if (widget.value > old.value && !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}
