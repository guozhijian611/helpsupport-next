import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_models.dart';
import '../../../core/providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasLocalSession = false;
  bool _localSessionReady = false;
  bool _hasRouted = false;

  @override
  void initState() {
    super.initState();
    _primeLocalSessionFlag();
  }

  Future<void> _primeLocalSessionFlag() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final accessToken = await tokenStorage.readAccessToken();
    final refreshToken = await tokenStorage.readRefreshToken();
    if (!mounted) {
      return;
    }
    setState(() {
      _hasLocalSession =
          (accessToken?.isNotEmpty ?? false) ||
          (refreshToken?.isNotEmpty ?? false);
      _localSessionReady = true;
    });
  }

  void _routeWhenReady(AsyncValue<AuthSession?> authState) {
    if (_hasRouted || !_localSessionReady) {
      return;
    }

    switch (authState) {
      case AsyncLoading():
        return;
      case AsyncData(:final value):
        _scheduleRoute(
          value != null
              ? '/home'
              : (_hasLocalSession ? '/login' : '/onboarding'),
        );
      case AsyncError():
        _scheduleRoute(_hasLocalSession ? '/login' : '/onboarding');
    }
  }

  void _scheduleRoute(String location) {
    _hasRouted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.go(location);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    _routeWhenReady(authState);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: const SizedBox.expand(),
    );
  }
}
