import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/data/onboarding_repository.dart';
import '../api/api_client.dart';
import '../auth/token_storage.dart';
import '../diagnostics/diagnostic_log_service.dart';
import '../notifications/local_notification_service.dart';
import '../permissions/permission_service.dart';
import '../push/firebase_push_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences is initialized in bootstrap.');
});

final tokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return const SecureTokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    diagnosticLogService: ref.watch(diagnosticLogServiceProvider),
  );
});

final diagnosticLogServiceProvider = Provider<DiagnosticLogService>((ref) {
  return DiagnosticLogService();
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.watch(apiClientProvider));
});

final localNotificationServiceProvider = Provider<LocalNotificationService>((
  ref,
) {
  return LocalNotificationService();
});

final firebasePushServiceProvider = Provider<FirebasePushService>((ref) {
  return FirebasePushService();
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});
