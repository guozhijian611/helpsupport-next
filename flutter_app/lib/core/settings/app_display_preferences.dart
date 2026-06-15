import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

final appThemeModeProvider =
    NotifierProvider<AppThemeModeController, ThemeMode>(
      AppThemeModeController.new,
    );

final appTextScaleProvider = NotifierProvider<AppTextScaleController, double>(
  AppTextScaleController.new,
);

class AppThemeModeController extends Notifier<ThemeMode> {
  static const _storageKey = 'app.theme_mode';

  @override
  ThemeMode build() {
    final stored = ref.read(sharedPreferencesProvider).getString(_storageKey);
    return _fromStorage(stored);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_storageKey, mode.name);
  }

  ThemeMode _fromStorage(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}

class AppTextScaleController extends Notifier<double> {
  static const _storageKey = 'app.text_scale';
  static const small = 0.92;
  static const standard = 1.0;
  static const large = 1.08;

  @override
  double build() {
    final stored = ref.read(sharedPreferencesProvider).getDouble(_storageKey);
    return _normalize(stored ?? standard);
  }

  Future<void> setScale(double value) async {
    final normalized = _normalize(value);
    state = normalized;
    await ref
        .read(sharedPreferencesProvider)
        .setDouble(_storageKey, normalized);
  }

  double _normalize(double value) {
    if (value <= (small + standard) / 2) {
      return small;
    }
    if (value >= (standard + large) / 2) {
      return large;
    }
    return standard;
  }
}
