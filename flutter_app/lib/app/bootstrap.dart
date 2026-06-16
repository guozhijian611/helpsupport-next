import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as timezone;

import '../core/api/api_client.dart';
import '../core/auth/token_storage.dart';
import '../core/config/build_info.dart';
import '../core/diagnostics/diagnostic_log_service.dart';
import '../core/notifications/local_notification_service.dart';
import '../core/permissions/permission_service.dart';
import '../core/providers/app_providers.dart';
import '../core/push/firebase_push_service.dart';
import '../features/onboarding/data/onboarding_repository.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  timezone.initializeTimeZones();

  final sharedPreferences = await SharedPreferences.getInstance();
  const tokenStorage = SecureTokenStorage();
  final diagnosticLogService = DiagnosticLogService();
  final apiClient = ApiClient(
    tokenStorage: tokenStorage,
    diagnosticLogService: diagnosticLogService,
  );
  final notificationService = LocalNotificationService();
  final firebasePushService = FirebasePushService();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      diagnosticLogService.recordFlutterError(details).catchError((_) {}),
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    unawaited(
      diagnosticLogService
          .recordUnhandledError(error, stackTrace)
          .catchError((_) {}),
    );
    return false;
  };

  unawaited(
    notificationService.initialize().catchError((error, stackTrace) {
      return diagnosticLogService.recordWarning(
        category: 'app.bootstrap',
        message: 'Local notification initialization failed',
        details: {
          'error': error.toString(),
          'stack_trace': stackTrace.toString(),
        },
      );
    }),
  );
  unawaited(
    firebasePushService.initialize().catchError((error, stackTrace) {
      return diagnosticLogService.recordWarning(
        category: 'app.bootstrap',
        message: 'Firebase push initialization failed',
        details: {
          'error': error.toString(),
          'stack_trace': stackTrace.toString(),
        },
      );
    }),
  );
  unawaited(
    diagnosticLogService
        .recordInfo(
          category: 'app.lifecycle',
          message: 'Application started',
          details: {'app_version': BuildInfo.appVersion},
        )
        .catchError((_) {}),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        tokenStorageProvider.overrideWithValue(tokenStorage),
        apiClientProvider.overrideWithValue(apiClient),
        diagnosticLogServiceProvider.overrideWithValue(diagnosticLogService),
        onboardingRepositoryProvider.overrideWithValue(
          OnboardingRepository(apiClient),
        ),
        localNotificationServiceProvider.overrideWithValue(notificationService),
        firebasePushServiceProvider.overrideWithValue(firebasePushService),
        permissionServiceProvider.overrideWithValue(PermissionService()),
      ],
      child: const HelpSupportApp(),
    ),
  );
}
