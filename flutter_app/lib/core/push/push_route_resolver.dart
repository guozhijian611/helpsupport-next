class PushRouteResolver {
  static const messagesRoute = '/me/messages';

  static String resolveFromPushData(
    Map<String, String> data, {
    String? role,
  }) {
    return resolve(
          bizType: data['biz_type'] ?? '',
          bizId: _asInt(data['biz_id']),
          route: data['route'] ?? '',
          payload: Map<String, dynamic>.from(data),
          scene: data['scene'],
          templateCode: data['template_code'],
          role: role,
          fallbackToMessages: true,
        ) ??
        messagesRoute;
  }

  static String? resolve({
    required String bizType,
    required int bizId,
    required String route,
    required Map<String, dynamic> payload,
    String? scene,
    String? templateCode,
    int messageType = 0,
    String? role,
    bool fallbackToMessages = false,
  }) {
    final sceneKey = (scene ?? '').trim();
    final template = (templateCode ?? '').trim();
    final isDoctor = role == 'doctor';

    if (sceneKey == 'developer_test' || payload['developer_test'] == '1') {
      return messagesRoute;
    }

    final postId = _firstInt(payload, const ['post_id'], fallback: 0);
    final memberId = _firstInt(payload, const ['member_id'], fallback: 0);

    if (bizType == 'community_follow_member' ||
        sceneKey == 'community_follow' ||
        template == 'community_follow') {
      final id = memberId > 0 ? memberId : bizId;
      if (id > 0) {
        return '/community/profile/$id';
      }
      return '/home?tab=community';
    }

    if (bizType == 'community_comment' ||
        bizType == 'community_audit_result' ||
        sceneKey == 'community_reply' ||
        template == 'community_reply') {
      final id = postId > 0 ? postId : bizId;
      if (id > 0) {
        return '/community/post/$id';
      }
      return '/home?tab=community';
    }

    if (bizType == 'task_reminder' ||
        sceneKey == 'task_reminder' ||
        template == 'task_reminder') {
      return isDoctor ? '/doctor/plan' : '/home?tab=plan';
    }

    if (bizType == 'appointment' ||
        sceneKey == 'appointment_update' ||
        template == 'appointment_update') {
      return isDoctor ? '/doctor/patients' : '/appointments/mine';
    }

    if (bizType == 'doctor_audit' ||
        bizType == 'doctor_profile' ||
        sceneKey == 'doctor_audit_result' ||
        template == 'doctor_audit_result') {
      if (bizType == 'doctor_profile') {
        return '/me/settings';
      }
      return '/register/doctor-certification';
    }

    final mapped = _mapLegacyRoute(
      route,
      postId: postId > 0 ? postId : bizId,
      memberId: memberId > 0 ? memberId : bizId,
      isDoctor: isDoctor,
    );
    if (mapped != null) {
      return mapped;
    }

    if (_isAllowedFlutterRoute(route)) {
      return route;
    }

    if (bizType.startsWith('community_') ||
        messageType == 1 ||
        messageType == 2) {
      return '/home?tab=community';
    }
    if (messageType == 3) {
      return isDoctor ? '/doctor/plan' : '/home?tab=plan';
    }
    if (messageType == 4) {
      return isDoctor ? '/doctor/patients' : '/appointments/mine';
    }

    return fallbackToMessages ? messagesRoute : null;
  }

  static String? _mapLegacyRoute(
    String route, {
    required int postId,
    required int memberId,
    required bool isDoctor,
  }) {
    final path = _routePath(route);
    if (path.isEmpty) {
      return null;
    }

    switch (path) {
      case '/pages/community/detail':
      case '/community/post':
        return postId > 0 ? '/community/post/$postId' : '/home?tab=community';
      case '/pages/community/profile':
      case '/community/profile':
        return memberId > 0
            ? '/community/profile/$memberId'
            : '/home?tab=community';
      case '/pages/appointment/detail':
        return isDoctor ? '/doctor/patients' : '/appointments/mine';
      case '/pages/doctor/appointments':
        return '/doctor/patients';
      case '/pages/plan/tasks':
        return isDoctor ? '/doctor/plan' : '/home?tab=plan';
      case '/pages/me/doctor-certification':
        return '/register/doctor-certification';
      case '/pages/message/detail':
        return messagesRoute;
      default:
        return null;
    }
  }

  static bool _isAllowedFlutterRoute(String route) {
    final path = _routePath(route);
    if (path == '/me/messages' ||
        path == '/home' ||
        path == '/appointments/mine' ||
        path == '/doctor/patients' ||
        path == '/doctor/plan' ||
        path == '/register/doctor-certification' ||
        path == '/me/settings') {
      return true;
    }
    final postMatch = RegExp(r'^/community/post/\d+$');
    final profileMatch = RegExp(r'^/community/profile/\d+$');
    return postMatch.hasMatch(path) || profileMatch.hasMatch(path);
  }

  static String _routePath(String route) {
    final text = route.trim();
    if (text.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(text.startsWith('/') ? 'app://local$text' : text);
    if (uri == null) {
      return text.split('?').first;
    }
    return uri.path.isEmpty ? text.split('?').first : uri.path;
  }

  static int _firstInt(
    Map<String, dynamic> values,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final parsed = _asInt(values[key]);
      if (parsed > 0) {
        return parsed;
      }
    }
    return fallback;
  }

  static int _asInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
