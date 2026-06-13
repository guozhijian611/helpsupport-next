import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as timezone;

import '../core/api/api_client.dart';
import '../core/auth/token_storage.dart';
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
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final notificationService = LocalNotificationService();
  final firebasePushService = FirebasePushService();

  await notificationService.initialize();
  await firebasePushService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        tokenStorageProvider.overrideWithValue(tokenStorage),
        apiClientProvider.overrideWithValue(apiClient),
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
