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

  /// Pain-first story, then solution, then integrity — not a feature list.
  List<OnboardingModel> onboardingItems = [
    OnboardingModel(
      image: Assets.icons.google.path,
      title: '“Just five minutes.”',
      subtitle:
          'You open the feed for a quick break after lunch. Forty-five minutes later the deep-work block is gone — and so is the afternoon.',
    ),
    OnboardingModel(
      image: Assets.icons.google.path,
      title: 'The feed isn’t neutral.',
      subtitle:
          'Short video is engineered for the next hit. Willpower alone loses. You need a rule that fires before your brain negotiates.',
    ),
    OnboardingModel(
      image: Assets.icons.google.path,
      title: 'Earn the open.',
      subtitle:
          'SweatLock locks the apps you choose. Unlock with real push-ups, a walk, or reading plus a quiz — not by waving at the camera or skimming pages.',
    ),
  ];
}
