import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpsupport_app/app/theme.dart';
import 'package:helpsupport_app/features/auth/application/auth_controller.dart';
import 'package:helpsupport_app/features/auth/data/auth_models.dart';
import 'package:helpsupport_app/features/home/presentation/home_shell.dart';
import 'package:helpsupport_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('home shell renders bottom navigation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_TestAuthController.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeShell(),
        ),
      ),
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Patient'), findsWidgets);
    expect(find.byIcon(Icons.memory_outlined), findsOneWidget);
  });
}

class _TestAuthController extends AuthController {
  @override
  Future<AuthSession?> build() async {
    return const AuthSession(
      token: AuthToken(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        tokenType: 'Bearer',
        expiresIn: 3600,
      ),
      member: {'id': 1, 'username': 'tester'},
      profile: {},
      doctorProfile: {},
    );
  }
}
