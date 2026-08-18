import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasRouted = false;

  @override
  void initState() {
    super.initState();
    _routeFromLocalSession();
  }

  Future<void> _routeFromLocalSession() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final tokens = await Future.wait([
      tokenStorage.readAccessToken(),
      tokenStorage.readRefreshToken(),
    ]);
    if (!mounted || _hasRouted) {
      return;
    }

    final accessToken = tokens[0];
    final refreshToken = tokens[1];
    final hasAccess = accessToken != null && accessToken.isNotEmpty;
    final hasRefresh = refreshToken != null && refreshToken.isNotEmpty;
    _scheduleRoute(
      hasAccess
          ? '/home'
          : hasRefresh
          ? '/login'
          : '/onboarding',
    );
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: const SizedBox.expand(),
    );
  }
}
