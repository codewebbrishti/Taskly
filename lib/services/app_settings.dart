import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences, saved on the device.
class AppSettings extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  String userName = '';
  bool use24h = false;
  bool weekStartsMonday = true;
  String? profileImagePath;
  bool remindersEnabled = true;

  SharedPreferences? _prefs;

  Future<void> load() async {
    final p = _prefs = await SharedPreferences.getInstance();
    final savedTheme = p.getString('themeMode');
    themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == savedTheme,
      orElse: () => ThemeMode.system,
    );
    userName = p.getString('userName') ?? '';
    use24h = p.getBool('use24h') ?? false;
    weekStartsMonday = p.getBool('weekStartsMonday') ?? true;
    profileImagePath = p.getString('profileImagePath');
    remindersEnabled = p.getBool('remindersEnabled') ?? true;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    _prefs?.setString('themeMode', mode.name);
    notifyListeners();
  }

  void setUserName(String name) {
    userName = name;
    _prefs?.setString('userName', name);
    notifyListeners();
  }

  void setUse24h(bool value) {
    use24h = value;
    _prefs?.setBool('use24h', value);
    notifyListeners();
  }

  void setRemindersEnabled(bool value) {
    remindersEnabled = value;
    _prefs?.setBool('remindersEnabled', value);
    notifyListeners();
  }

  /// Pass null to remove the photo. The old file is deleted from the device.
  void setProfileImage(String? path) {
    final old = profileImagePath;
    profileImagePath = path;
    if (path == null) {
      _prefs?.remove('profileImagePath');
    } else {
      _prefs?.setString('profileImagePath', path);
    }
    if (old != null && old != path) {
      () async {
        try {
          final f = File(old);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }();
    }
    notifyListeners();
  }

  void setWeekStartsMonday(bool value) {
    weekStartsMonday = value;
    _prefs?.setBool('weekStartsMonday', value);
    notifyListeners();
  }
}

final AppSettings settings = AppSettings();
