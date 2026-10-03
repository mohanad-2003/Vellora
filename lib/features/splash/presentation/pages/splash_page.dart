import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/vellora_logo.dart';
import '../cubit/splash_cubit.dart';

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
            case SplashDestination.languageSelect:
              context.goNamed(RouteNames.nLanguageSelect);
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
    with SingleTickerProviderStateMixin {
  /// One calm entrance: mark → name → tagline → loader.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late final Animation<double> _markFade = _interval(0.00, 0.40);
  late final Animation<double> _markScale = Tween<double>(begin: 0.86, end: 1)
      .animate(_interval(0.00, 0.50, Curves.easeOutBack));
  late final Animation<double> _nameFade = _interval(0.25, 0.60);
  late final Animation<double> _nameSlide = Tween<double>(begin: 14, end: 0)
      .animate(_interval(0.25, 0.65, Curves.easeOutCubic));
  late final Animation<double> _taglineFade = _interval(0.50, 0.85);
  late final Animation<double> _loaderFade = _interval(0.70, 1.00);

  CurvedAnimation _interval(
    double begin,
    double end, [
    Curve curve = Curves.easeOut,
  ]) =>
      CurvedAnimation(
        parent: _entrance,
        curve: Interval(begin, end, curve: curve),
      );

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion && !_entrance.isCompleted) _entrance.value = 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E4A),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Brand navy into violet — the same family as the Vellora mark.
            colors: [Color(0xFF0B0E4A), Color(0xFF1A0F5C), Color(0xFF2E1280)],
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
                      child: const VelloraMark(size: 112, glow: true),
                    ),
                  ),
                  const SizedBox(height: 28),
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            color: Colors.white,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.22),
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
