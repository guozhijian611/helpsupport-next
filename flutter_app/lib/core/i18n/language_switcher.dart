import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_locale_controller.dart';

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLocale = ref.watch(appLocaleProvider);
    final currentLanguage =
        selectedLocale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final selected = {'zh', 'en'}.contains(currentLanguage)
        ? currentLanguage
        : 'en';

    return SegmentedButton<String>(
      showSelectedIcon: false,
      style: _style(context),
      segments: const [
        ButtonSegment(value: 'zh', label: Text('中文')),
        ButtonSegment(value: 'en', label: Text('EN')),
      ],
      selected: {selected},
      onSelectionChanged: (values) {
        if (values.isEmpty) {
          return;
        }
        unawaited(
          ref.read(appLocaleProvider.notifier).setLocale(Locale(values.first)),
        );
      },
    );
  }

  ButtonStyle _style(BuildContext context) {
    if (!onDark) {
      return const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }

    return ButtonStyle(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return Colors.white.withValues(alpha: 0.14);
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF2E7D6B);
        }
        return Colors.white;
      }),
      side: WidgetStatePropertyAll(
        BorderSide(color: Colors.white.withValues(alpha: 0.54)),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
