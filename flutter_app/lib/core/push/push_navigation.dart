import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/message/application/message_controller.dart';
import '../providers/app_providers.dart';
import 'firebase_push_diagnostics.dart';
import 'firebase_push_service.dart';
import 'push_route_resolver.dart';

final pendingPushDataProvider = StateProvider<Map<String, String>?>(
  (ref) => null,
);

class PushNavigationHost extends ConsumerStatefulWidget {
  const PushNavigationHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushNavigationHost> createState() => _PushNavigationHostState();
}

class _PushNavigationHostState extends ConsumerState<PushNavigationHost> {
  StreamSubscription<List<FirebasePushEvent>>? _eventsSubscription;
  GoRouter? _router;
  final Set<String> _handledEventKeys = <String>{};
  var _flushing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _bind();
    });
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _router?.routerDelegate.removeListener(_scheduleFlush);
    super.dispose();
  }

  void _bind() {
    final router = ref.read(appRouterProvider);
    if (!identical(_router, router)) {
      _router?.routerDelegate.removeListener(_scheduleFlush);
      _router = router;
      router.routerDelegate.addListener(_scheduleFlush);
    }

    final service = ref.read(firebasePushServiceProvider);
    _consumeOpenedEvents(service.latestEvents);
    _eventsSubscription ??= service.receivedEvents.listen((events) {
      if (!mounted) {
        return;
      }
      _consumeOpenedEvents(events);
    });
    _scheduleFlush();
  }

  void _consumeOpenedEvents(List<FirebasePushEvent> events) {
    for (final event in events) {
      if (event.source != 'opened' && event.source != 'initial') {
        continue;
      }
      final key = _eventKey(event);
      if (!_handledEventKeys.add(key)) {
        continue;
      }
      ref.read(pendingPushDataProvider.notifier).state = Map<String, String>.from(
        event.data,
      );
      _scheduleFlush();
    }
  }

  void _scheduleFlush() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _flush();
      }
    });
  }

  void _flush() {
    if (_flushing) {
      return;
    }
    final pending = ref.read(pendingPushDataProvider);
    if (pending == null || pending.isEmpty) {
      return;
    }

    final router = ref.read(appRouterProvider);
    Uri location;
    try {
      location = router.routerDelegate.currentConfiguration.uri;
    } catch (_) {
      return;
    }
    if (_shouldWait(location.path)) {
      return;
    }

    final auth = ref.read(authControllerProvider);
    if (!auth.hasValue) {
      return;
    }
    if (auth.value == null) {
      return;
    }

    final route = PushRouteResolver.resolveFromPushData(
      pending,
      role: auth.value?.currentRole,
    );
    ref.read(pendingPushDataProvider.notifier).state = null;
    _flushing = true;
    _markMessageRead(pending);
    _openRoute(router, location, route);
    _flushing = false;
  }

  bool _shouldWait(String path) {
    return path.isEmpty ||
        path == '/' ||
        path == '/onboarding' ||
        path == '/login' ||
        path.startsWith('/register') ||
        path.startsWith('/forgot-password') ||
        path.startsWith('/protocol');
  }

  void _openRoute(GoRouter router, Uri current, String route) {
    final currentFull = current.toString();
    if (currentFull == route || current.path == route) {
      return;
    }
    if (route.startsWith('/home')) {
      router.go(route);
      return;
    }
    router.push(route);
  }

  void _markMessageRead(Map<String, String> data) {
    final messageId = int.tryParse(data['message_id'] ?? '') ?? 0;
    if (messageId <= 0) {
      return;
    }
    unawaited(() async {
      try {
        await ref
            .read(messageRepositoryProvider)
            .readMessage(messageId: messageId);
        ref.invalidate(unreadMessageCountProvider);
        ref.invalidate(messageListProvider);
      } catch (_) {
        // Navigation should not fail if the read API is unavailable.
      }
    }());
  }

  String _eventKey(FirebasePushEvent event) {
    final messageId = event.data['message_id'] ?? event.messageId;
    if (messageId != null && messageId.isNotEmpty) {
      return messageId;
    }
    return '${event.source}:${event.receivedAt.microsecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      _scheduleFlush();
    });
    ref.listen(pendingPushDataProvider, (previous, next) {
      _scheduleFlush();
    });
    return widget.child;
  }
}
