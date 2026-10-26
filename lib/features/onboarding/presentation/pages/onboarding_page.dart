import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/brand_backdrop.dart';
import '../../../../core/widgets/vellora_logo.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/onboarding_slide.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<OnboardingCubit>(),
    child: const _OnboardingView(),
  );
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final _controller = PageController();
  double _page = 0;
  bool _finishing = false;

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
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await context.read<OnboardingCubit>().complete();
      if (mounted) context.goNamed(RouteNames.nWelcome);
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  void _next(OnboardingCubit cubit) {
    Haptics.selection();
    if (cubit.isLastPage) {
      _finish();
    } else if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(cubit.state + 1);
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
    final l10n = context.l10n;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kOnboardingNavy,
        body: BrandBackdrop(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: SizedBox(
                            height: 32,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: VelloraLogo(height: 32, onDark: true),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _LanguageButton(),
                      if (!cubit.isLastPage)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: TextButton(
                            onPressed: _finishing ? null : _finish,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFBDCEC8),
                              minimumSize: const Size(48, 48),
                            ),
                            child: Text(l10n.skip),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: pages.length,
                        onPageChanged: cubit.onPageChanged,
                        itemBuilder: (_, i) => OnboardingSlide(
                          page: pages[i],
                          pageOffset: _page - i,
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 516),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            label: l10n.pageOf(cubit.state + 1, pages.length),
                            excludeSemantics: true,
                            child: Row(
                              children: [
                                ...List.generate(
                                  pages.length,
                                  (i) => AnimatedContainer(
                                    duration: Duration(
                                      milliseconds:
                                          MediaQuery.disableAnimationsOf(
                                            context,
                                          )
                                          ? 0
                                          : 250,
                                    ),
                                    margin: const EdgeInsetsDirectional.only(
                                      end: 6,
                                    ),
                                    width: i == cubit.state ? 28 : 7,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: i == cubit.state
                                          ? kBrandAccent
                                          : Colors.white24,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    l10n.pageOf(cubit.state + 1, pages.length),
                                    textAlign: TextAlign.end,
                                    style: context.textTheme.labelSmall
                                        ?.copyWith(
                                          color: const Color(0xFFBDCEC8),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _finishing ? null : () => _next(cubit),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kBrandAccent,
                                foregroundColor: kBrandNavy,
                                minimumSize: const Size(0, 56),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              iconAlignment: IconAlignment.end,
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                              ),
                              label: Text(
                                cubit.isLastPage ? l10n.getStarted : l10n.next,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context) {
    final toArabic = context.watch<LocaleCubit>().state.languageCode != 'ar';
    return Semantics(
      button: true,
      label: toArabic ? 'العربية' : 'English',
      excludeSemantics: true,
      child: TextButton(
        onPressed: () {
          Haptics.selection();
          sl<LocaleCubit>().toggle();
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          toArabic ? 'ع' : 'EN',
          style: TextStyle(fontFamily: toArabic ? 'Cairo' : 'Inter'),
        ),
      ),
    );
  }
}
