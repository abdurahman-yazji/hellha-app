import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = AsyncNotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends AsyncNotifier<ThemeMode> {
  final _preferences = SharedPreferencesAsync();

  static const _storageKey = 'hellha_dark_mode';

  @override
  Future<ThemeMode> build() async {
    final isDark = await _preferences.getBool(_storageKey);

    // قبل اختيار المستخدم، نتبع إعداد الجهاز.
    if (isDark == null) {
      return ThemeMode.system;
    }

    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDarkMode(bool enabled) async {
    await _preferences.setBool(_storageKey, enabled);

    state = AsyncData(enabled ? ThemeMode.dark : ThemeMode.light);
  }
}
