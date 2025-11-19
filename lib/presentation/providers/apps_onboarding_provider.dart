import 'package:flutter/material.dart';

class AppsOnboardingProvider extends ChangeNotifier {
  int _currentIndex = 1;
  int get currentIndex => _currentIndex;

  set currentIndex(int value) {
    _currentIndex = value;
    notifyListeners();
  }

  int maxIndex = 3;
}
