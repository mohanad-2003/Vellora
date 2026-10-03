import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/vellora_logo.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/onboarding_slide.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OnboardingCubit>(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final _controller = PageController();
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final page = _controller.page ?? 0;
    if (page != _page) setState(() => _page = page);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<OnboardingCubit>().complete();
    if (mounted) context.goNamed(RouteNames.nWelcome);
  }

  void _next(OnboardingCubit cubit) {
    if (cubit.isLastPage) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<OnboardingCubit>();
    final pages = OnboardingCubit.pages;
    final index = cubit.state;
    final l10n = context.l10n;
    final gutter = context.pageGutter;

    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final controlsHeight = 56 + AppSpacing.xxl + AppSpacing.xl + bottomSafe;
    final landscape = context.screenWidth > context.screenHeight * 1.15;

    final controls = Padding(
      padding: EdgeInsets.fromLTRB(
        gutter,
        0,
        gutter,
        AppSpacing.xl + bottomSafe,
      ),
      child: Row(
        children: [
          Semantics(
            label: l10n.pageOf(index + 1, pages.length),
            child: Row(
              children: List.generate(
                pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  width: i == index ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == index ? kBrandGold : Colors.white24,
                    borderRadius: AppRadius.rPill,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          _GoldButton(
            label: cubit.isLastPage ? l10n.getStarted : l10n.next,
            onPressed: () => _next(cubit),
          ),
        ],
      ),
    );

    // Onboarding is a brand moment: always dark navy with light status-bar
    // icons, whichever theme the app is in.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kOnboardingNavy,
        body: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: cubit.onPageChanged,
                itemBuilder: (_, i) => OnboardingSlide(
                  page: pages[i],
                  bottomInset: controlsHeight + AppSpacing.xl,
                  pageOffset: _page - i,
                ),
              ),
            ),
            // Controls float over the bottom of the artwork's navy fade.
            Positioned(
              left: landscape ? context.screenWidth / 2 : 0,
              right: 0,
              bottom: 0,
              child: controls,
            ),
            // Brand mark and Skip float over the artwork's clear top area.
            PositionedDirectional(
              top: MediaQuery.paddingOf(context).top + 12,
              start: gutter,
              child: const VelloraLogo(height: 38, onDark: true),
            ),
            PositionedDirectional(
              top: MediaQuery.paddingOf(context).top + 8,
              end: gutter - 6,
              child: Visibility(
                visible: !cubit.isLastPage,
                child: _SkipPill(label: l10n.skip, onTap: _finish),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brand-gold call to action. Gold on navy is the Vellora signature pairing.
class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Haptics.selection();
        onPressed();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: kBrandGold,
        foregroundColor: const Color(0xFF14102E),
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 28),
      ),
      iconAlignment: IconAlignment.end,
      // Directional arrows mirror automatically in RTL.
      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
      label: Text(label),
    );
  }
}

class _SkipPill extends StatelessWidget {
  const _SkipPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: AppRadius.rPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rPill,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Center(
              child: Text(
                label,
                style: context.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
