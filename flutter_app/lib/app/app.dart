import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/i18n/app_locale_controller.dart';
import '../core/settings/app_display_preferences.dart';
import '../l10n/generated/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class HelpSupportApp extends ConsumerWidget {
  const HelpSupportApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final textScale = ref.watch(appTextScaleProvider);
    final appConfigState = ref.watch(appConfigProvider);
    final appConfig = appConfigState.hasValue
        ? appConfigState.value ?? AppConfig.fallback
        : AppConfig.fallback;

    return MaterialApp.router(
      title: appConfig.name,
      debugShowCheckedModeBanner: false,
      locale: locale,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
