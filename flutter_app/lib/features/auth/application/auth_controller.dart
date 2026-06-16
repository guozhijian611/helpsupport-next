import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';
import '../data/device_registration_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

final deviceRegistrationServiceProvider = Provider<DeviceRegistrationService>((
  ref,
) {
  return DeviceRegistrationService(
    ref.watch(apiClientProvider),
    ref.watch(firebasePushServiceProvider),
    ref.watch(sharedPreferencesProvider),
  );
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    final accessToken = await ref.read(tokenStorageProvider).readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    try {
      final session = await ref.read(authRepositoryProvider).refreshSession();
      await ref.read(authRepositoryProvider).saveSession(session);
      return session;
    } on Object {
      await ref.read(authRepositoryProvider).clearSession();
      return null;
    }
  }

  Future<void> accountLogin({
    required String username,
    required String password,
  }) {
    return _login(
      () => ref
          .read(authRepositoryProvider)
          .accountLogin(username: username, password: password),
    );
  }

  Future<VerificationCodeDelivery> sendRegisterEmailCode({
    required String email,
  }) {
    return ref.read(authRepositoryProvider).sendRegisterEmailCode(email: email);
  }

  Future<VerificationCodeDelivery> sendRegisterPhoneCode({
    required String mobile,
  }) {
    return ref
        .read(authRepositoryProvider)
        .sendRegisterPhoneCode(mobile: mobile);
  }

  Future<VerificationCodeDelivery> sendForgotEmailCode({
    required String email,
  }) {
    return ref.read(authRepositoryProvider).sendForgotEmailCode(email: email);
  }

  Future<VerificationCodeDelivery> sendForgotPhoneCode({
    required String mobile,
  }) {
    return ref.read(authRepositoryProvider).sendForgotPhoneCode(mobile: mobile);
  }

  Future<void> accountRegister({
    required String registerType,
    String? username,
    String? email,
    String? mobile,
    required String password,
    String? emailCode,
    String? mobileCode,
    required String memberRole,
    String? locale,
    String? timezone,
    String? nickname,
  }) {
    return _login(
      () => ref
          .read(authRepositoryProvider)
          .accountRegister(
            registerType: registerType,
            username: username,
            email: email,
            mobile: mobile,
            password: password,
            emailCode: emailCode,
            mobileCode: mobileCode,
            memberRole: memberRole,
            locale: locale,
            timezone: timezone,
            nickname: nickname,
          ),
    );
  }

  Future<void> googleLogin() {
    return _login(ref.read(authRepositoryProvider).googleLogin);
  }

  Future<void> appleLogin() {
    return _login(ref.read(authRepositoryProvider).appleLogin);
  }

  Future<AuthSession> refreshCurrentSession() async {
    final session = await ref.read(authRepositoryProvider).refreshSession();
    await ref.read(authRepositoryProvider).saveSession(session);
    state = AsyncValue.data(session);
    return session;
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await ref
            .read(deviceRegistrationServiceProvider)
            .unregisterCurrentDevice();
      } on Object {
        // Local logout must still clear credentials if device unregister fails.
      }
      await ref.read(authRepositoryProvider).clearSession();
      try {
        await ref.read(authRepositoryProvider).signOutIdentityProviders();
      } on Object {
        // Provider SDK sign-out is best-effort after local credentials are cleared.
      }
      return null;
    });
  }

  Future<void> _login(Future<AuthSession> Function() action) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final session = await action();
      await ref.read(authRepositoryProvider).saveSession(session);
      unawaited(_registerCurrentDeviceSafely());
      return session;
    });
  }

  Future<void> _registerCurrentDeviceSafely() async {
    try {
      await ref.read(deviceRegistrationServiceProvider).registerCurrentDevice();
    } on Object catch (error, stackTrace) {
      unawaited(
        ref
            .read(diagnosticLogServiceProvider)
            .recordWarning(
              category: 'push',
              message: 'Device registration skipped after login',
              details: {
                'error': error.toString(),
                'stack_trace': stackTrace.toString(),
              },
            )
            .catchError((_) {}),
      );
    }
  }
}
