import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../domain/entities/onboarding_page_entity.dart';

/// Tracks the current onboarding page and persists the "seen" flag on finish.
@injectable
class OnboardingCubit extends Cubit<int> {
  OnboardingCubit(this._prefs) : super(0);

  final SharedPreferences _prefs;

  static const List<OnboardingPageEntity> pages = [
    OnboardingPageEntity(
      imagePath: AssetPaths.onboardingDiscover,
      titleKey: 'onboardingTitle1',
      bodyKey: 'onboardingBody1',
    ),
    OnboardingPageEntity(
      imagePath: AssetPaths.onboardingShopping,
      titleKey: 'onboardingTitle2',
      bodyKey: 'onboardingBody2',
    ),
    OnboardingPageEntity(
      imagePath: AssetPaths.onboardingDelivery,
      titleKey: 'onboardingTitle3',
      bodyKey: 'onboardingBody3',
    ),
  ];

  bool get isLastPage => state == pages.length - 1;

  void onPageChanged(int index) => emit(index);

  Future<void> complete() async {
    await _prefs.setBool(AppConstants.prefOnboardingSeen, true);
  }
}
