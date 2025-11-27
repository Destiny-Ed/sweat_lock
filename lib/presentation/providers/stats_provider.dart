import 'package:flutter/material.dart';

class StatsProvider extends ChangeNotifier {
  List<String> statTab = ["weekly", "monthly", "all time"];

  String _selectedTab = "weekly";
  String get selectedTab => _selectedTab;

  set selectedTab(String tab) {
    _selectedTab = tab;
    notifyListeners();
  }
}
