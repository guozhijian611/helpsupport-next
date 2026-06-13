import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpsupport_app/app/theme.dart';
import 'package:helpsupport_app/features/home/presentation/home_shell.dart';
import 'package:helpsupport_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('home shell renders bottom navigation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeShell(),
      ),
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Patient'), findsWidgets);
    expect(find.byIcon(Icons.memory_outlined), findsOneWidget);
  });
}
