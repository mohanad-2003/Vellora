import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'product_image.dart';

/// Where a product's little picture starts its flight to the cart.
class FlightSource {
  const FlightSource({required this.rect, required this.imagePath});

  final Rect rect;
  final String imagePath;
}

/// What was just added, for the "added to your cart" chip.
class CartAdded {
  const CartAdded({required this.name, required this.imagePath});

  final String name;
  final String imagePath;
}

/// Feedback for adding to the cart from a product card: the product's picture
/// flies to the cart icon in the bar, and a chip over the bar shows what is in
/// the cart with a way to open it.
///
/// Only where the floating bar is on screen (phones). On a wide window, where
/// the navigation is a rail, [announce] says it did nothing and the caller shows
/// its usual message instead.
class CartFlight {
  CartFlight._();

  /// The cart icon in the bottom bar; the flight lands on it.
  static final GlobalKey navCartKey = GlobalKey(debugLabel: 'navCart');

  /// Set by the card's add button just before it reports the tap, so the flight
  /// knows where to start. Consumed (and cleared) by [announce].
  static FlightSource? pending;

  /// The latest add; the chip listens.
  static final ValueNotifier<CartAdded?> added = ValueNotifier(null);

  static Rect? get targetRect {
    final box = navCartKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Remembers where the tap came from: [context] is the add button's.
  static void markSource(BuildContext context, String imagePath) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    pending = FlightSource(
      rect: box.localToGlobal(Offset.zero) & box.size,
      imagePath: imagePath,
    );
  }

  /// Plays the flight (when it can) and shows the chip. False when there is no
  /// bar on screen: nothing was done.
  static bool announce(
    BuildContext context, {
    required String name,
    required String imagePath,
  }) {
    final to = targetRect;
    final source = pending;
    pending = null;
    if (to == null) return false;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final shown = CartAdded(name: name, imagePath: imagePath);
    if (source == null || overlay == null || reduce) {
      added.value = shown;
      return true;
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Flight(
        from: source.rect,
        to: to,
        imagePath: source.imagePath,
        onDone: () {
          entry.remove();
          added.value = shown;
        },
      ),
    );
    overlay.insert(entry);
    return true;
  }
}

/// The picture, shrinking along a small arc into the cart icon.
class _Flight extends StatefulWidget {
  const _Flight({
    required this.from,
    required this.to,
    required this.imagePath,
    required this.onDone,
  });

  final Rect from;
  final Rect to;
  final String imagePath;
  final VoidCallback onDone;

  @override
  State<_Flight> createState() => _FlightState();
}

class _FlightState extends State<_Flight> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.from.center;
    final end = widget.to.center;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_controller.value);
          final lift = math.sin(math.pi * t) * 70;
          final position = Offset.lerp(start, end, t)! - Offset(0, lift);
          final size = 52 - 30 * t;
          return Stack(
            children: [
              Positioned(
                left: position.dx - size / 2,
                top: position.dy - size / 2,
                width: size,
                height: size,
                child: Opacity(
                  opacity: 1 - 0.25 * t,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x55000000), blurRadius: 12),
                      ],
                    ),
                    child: ClipOval(
                      child: ProductImage(path: widget.imagePath),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
