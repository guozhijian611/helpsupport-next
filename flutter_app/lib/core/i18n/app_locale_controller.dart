import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

final appLocaleProvider = NotifierProvider<AppLocaleController, Locale?>(
  AppLocaleController.new,
);

class AppLocaleController extends Notifier<Locale?> {
  static const _storageKey = 'app.locale';
  static const _supportedLanguageCodes = {'en', 'zh'};

  @override
  Locale? build() {
    final stored = ref.read(sharedPreferencesProvider).getString(_storageKey);
    if (stored == null || !_supportedLanguageCodes.contains(stored)) {
      return null;
    }
    return Locale(stored);
  }

  Future<void> setLocale(Locale locale) async {
    final languageCode = locale.languageCode;
    if (!_supportedLanguageCodes.contains(languageCode)) {
      return;
    }
    state = Locale(languageCode);
    await ref
        .read(sharedPreferencesProvider)
        .setString(_storageKey, languageCode);
  }
}
