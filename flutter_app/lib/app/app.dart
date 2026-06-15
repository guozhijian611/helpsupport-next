import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/i18n/app_locale_controller.dart';
import '../l10n/generated/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class HelpSupportApp extends ConsumerWidget {
  const HelpSupportApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(appLocaleProvider);
    final appConfig =
        ref.watch(appConfigProvider).valueOrNull ?? AppConfig.fallback;

    return MaterialApp.router(
      title: appConfig.name,
      debugShowCheckedModeBanner: false,
      locale: locale,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
