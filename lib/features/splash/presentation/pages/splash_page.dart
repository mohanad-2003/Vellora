import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/routing/route_names.dart';
import 'package:vellora/core/widgets/vellora_logo.dart';
import 'package:vellora/features/splash/presentation/cubit/splash_cubit.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SplashCubit>()..decide(),
      child: BlocListener<SplashCubit, SplashDestination?>(
        listener: (context, destination) {
          if (destination == null) return;
          switch (destination) {
            case SplashDestination.onboarding:
              context.goNamed(RouteNames.nOnboarding);
            case SplashDestination.login:
              context.goNamed(RouteNames.nLogin);
            case SplashDestination.home:
              context.goNamed(RouteNames.nHome);
          }
        },
        child: const _SplashView(),
      ),
    );
  }
}

class _SplashView extends StatefulWidget {
  const _SplashView();

  @override
  State<_SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<_SplashView>
    with TickerProviderStateMixin {
  /// One calm entrance: mark → name → tagline → loader.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  /// Slow loop behind the mark: pulsing rings, drifting sparks and the loader.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  late final Animation<double> _markFade = _interval(0.00, 0.40);
  late final Animation<double> _markScale = Tween<double>(
    begin: 0.86,
    end: 1,
  ).animate(_interval(0.00, 0.50, Curves.easeOutBack));
  late final Animation<double> _nameFade = _interval(0.25, 0.60);
  late final Animation<double> _nameSlide = Tween<double>(
    begin: 14,
    end: 0,
  ).animate(_interval(0.25, 0.65, Curves.easeOutCubic));
  late final Animation<double> _taglineFade = _interval(0.50, 0.85);
  late final Animation<double> _loaderFade = _interval(0.70, 1.00);

  bool _reduceMotion = false;

  CurvedAnimation _interval(
    double begin,
    double end, [
    Curve curve = Curves.easeOut,
  ]) => CurvedAnimation(
    parent: _entrance,
    curve: Interval(begin, end, curve: curve),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _entrance.value = 1;
      _ambient.stop();
    } else if (!_ambient.isAnimating) {
      _ambient.repeat();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0A2620),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Deep emerald, the same family as the app and the system splash.
            colors: [Color(0xFF06150F), Color(0xFF0A2620), Color(0xFF0F4A3E)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _markFade,
                    child: ScaleTransition(
                      scale: _markScale,
                      child: SizedBox.square(
                        dimension: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _ambient,
                              builder: (_, _) => CustomPaint(
                                size: const Size.square(220),
                                painter: _HaloPainter(
                                  t: _reduceMotion ? 0.35 : _ambient.value,
                                ),
                              ),
                            ),
                            const VelloraMark(size: 112, glow: true),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _entrance,
                    builder: (_, child) => Opacity(
                      opacity: _nameFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _nameSlide.value),
                        child: child,
                      ),
                    ),
                    child: const VelloraWordmark(height: 30),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      context.l10n.splashTagline,
                      textAlign: TextAlign.center,
                      style: text.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  FadeTransition(
                    opacity: _loaderFade,
                    child: Semantics(
                      label: context.l10n.loading,
                      child: SizedBox(
                        width: 96,
                        height: 3,
                        child: AnimatedBuilder(
                          animation: _ambient,
                          builder: (_, _) => CustomPaint(
                            painter: _SweepPainter(
                              t: _reduceMotion ? 0.5 : _ambient.value,
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
    );
  }
}

const _gold = Color(0xFFE9B861);

/// Two gold rings that swell and fade out of the mark, and a few sparks that
/// drift around it.
class _HaloPainter extends CustomPainter {
  const _HaloPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final base = size.width * 0.28;

    for (final phase in const [0.0, 0.5]) {
      final k = (t + phase) % 1;
      final radius = base + (size.width * 0.5 - base) * k;
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = _gold.withValues(alpha: 0.32 * (1 - k)),
      );
    }

    const sparks = [(0.0, 0.46, 3.0), (2.1, 0.40, 2.2), (4.2, 0.48, 2.6)];
    for (final (angle, dist, r) in sparks) {
      final a = angle + t * 2 * math.pi * 0.5;
      final p = c + Offset(math.cos(a), math.sin(a)) * (size.width * dist);
      final twinkle = 0.5 + 0.5 * math.sin(t * 2 * math.pi + angle);
      canvas.drawCircle(
        p,
        r,
        Paint()..color = _gold.withValues(alpha: 0.25 + 0.55 * twinkle),
      );
    }
  }

  @override
  bool shouldRepaint(_HaloPainter old) => old.t != t;
}

/// A thin track with a gold segment sweeping across it.
class _SweepPainter extends CustomPainter {
  const _SweepPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(2),
    );
    canvas.drawRRect(
      track,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    canvas.save();
    canvas.clipRRect(track);
    final seg = size.width * 0.38;
    final x = -seg + (size.width + seg) * Curves.easeInOut.transform(t);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, seg, size.height),
        const Radius.circular(2),
      ),
      Paint()..color = _gold,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SweepPainter old) => old.t != t;
}
