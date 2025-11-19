import 'package:flutter/material.dart';
import 'package:sweat_lock/data/models/onboarding.dart';
import 'package:sweat_lock/gen/assets.gen.dart';

class OnboardingProvider extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  set currentIndex(int value) {
    _currentIndex = value;
    notifyListeners();
  }

  List<OnboardingModel> onboardingItems = [
    OnboardingModel(
      image: Assets.icons.google.path,
      title: "Turn your doomscrolling into gains.",
      subtitle:
          'Earn your screen time by completing quick, effective exercises.',
    ),
    OnboardingModel(
      image: Assets.icons.google.path,
      title: "Build health before scrolling",
      subtitle: 'A healthier you is just a workout away.',
    ),
    OnboardingModel(
      image: Assets.icons.google.path,
      title: "Turn your doomscrolling into gains.",
      subtitle:
          'Earn your screen time by completing quick, effective exercises.',
    ),
  ];
}
