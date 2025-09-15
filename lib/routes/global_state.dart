import 'package:flutter/material.dart';

class GlobalState extends ChangeNotifier {
  String _userPreference = "Balanced Diet";

  String get userPreference => _userPreference;

  void setUserPreference(String preference) {
    _userPreference = preference;
    notifyListeners();
  }
}
