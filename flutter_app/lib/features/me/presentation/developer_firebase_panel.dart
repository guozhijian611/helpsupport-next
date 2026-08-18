import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/push/firebase_push_diagnostics.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_models.dart';

class DeveloperFirebasePanel extends ConsumerStatefulWidget {
  const DeveloperFirebasePanel({super.key});

  @override
  ConsumerState<DeveloperFirebasePanel> createState() =>
      DeveloperFirebasePanelState();
}

class DeveloperFirebasePanelState
    extends ConsumerState<DeveloperFirebasePanel> {
  bool _loading = true;
  bool _busy = false;
  String? _deviceId;
  String? _actionHint;
  FirebasePushDiagnostics? _diagnostics;
  Map<String, dynamic> _serverDebug = const <String, dynamic>{};
  StreamSubscription<List<FirebasePushEvent>>? _eventsSubscription;

  @override
  void initState() {
    super.initState();
    unawaited(refresh());
    _eventsSubscription = ref
        .read(firebasePushServiceProvider)
        .receivedEvents
        .listen((events) {
          final diagnostics = _diagnostics;
          if (!mounted || diagnostics == null) {
            return;
          }
          setState(() {
            _diagnostics = diagnostics.copyWith(recentEvents: events);
          });
        });
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

  Future<void> refresh({bool waitForApns = false}) async {
    setState(() => _loading = true);
    final pushService = ref.read(firebasePushServiceProvider);
    final deviceService = ref.read(deviceRegistrationServiceProvider);
    try {
      if (!pushService.isAvailable) {
        await pushService.initialize(force: true);
      }
      final diagnostics = await pushService.readDiagnostics(
        waitForApns: waitForApns,
      );
      final deviceId = await deviceService.readCurrentDeviceId();
      Map<String, dynamic> serverDebug = const <String, dynamic>{};
      if (_isLoggedIn) {
        try {
          serverDebug = await deviceService.readServerPushDebug();
        } on Object catch (error) {
          serverDebug = <String, dynamic>{'error': error.toString()};
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _diagnostics = diagnostics;
        _deviceId = deviceId;
        _serverDebug = serverDebug;
        _loading = false;
      });
      await ref
          .read(diagnosticLogServiceProvider)
          .recordInfo(
            category: 'developer.firebase',
            message: 'Refreshed Firebase push diagnostics',
            details: diagnostics.toSafeJson(),
          );
    } on Object catch (error) {
      await ref
          .read(diagnosticLogServiceProvider)
          .recordError(
            category: 'developer.firebase',
            message: 'Refreshing Firebase push diagnostics failed',
            details: {'error': error.toString()},
          );
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      context.showCenteredNotice(_errorText(context, error));
    }
  }

  bool get _isLoggedIn {
    final session = ref.read(authControllerProvider).valueOrNull;
    return session is AuthSession;
  }

  Future<void> _copy(String? value, String emptyMessage) async {
    if (value == null || value.isEmpty) {
      context.showCenteredNotice(emptyMessage);
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    context.showCenteredNotice(_t(context, '已复制到剪贴板', 'Copied to clipboard'));
  }

  Future<void> _requestPermission() async {
    setState(() => _busy = true);
    try {
      await ref.read(firebasePushServiceProvider).requestPermission();
      await ref.read(permissionServiceProvider).requestNotifications();
      await refresh();
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(
        _t(context, '已请求推送权限', 'Push permission requested'),
      );
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _registerDevice() async {
    if (!_isLoggedIn) {
      context.showCenteredNotice(
        _t(context, '请先登录后再登记推送设备', 'Sign in before registering this device.'),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(deviceRegistrationServiceProvider).registerCurrentDevice();
      await refresh();
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(
        _t(
          context,
          '已重新向服务器登记当前设备',
          'Current device registered with the server.',
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _refreshToken() async {
    setState(() => _busy = true);
    try {
      await ref.read(firebasePushServiceProvider).refreshToken();
      if (_isLoggedIn) {
        await ref
            .read(deviceRegistrationServiceProvider)
            .registerCurrentDevice();
      }
      await refresh(waitForApns: Platform.isIOS);
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(
        _t(context, '已刷新 FCM Token', 'FCM token refreshed'),
      );
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _sendTestPush() async {
    if (!_isLoggedIn) {
      context.showCenteredNotice(
        _t(context, '请先登录后再发送测试推送', 'Sign in before sending a test push.'),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(deviceRegistrationServiceProvider).registerCurrentDevice();
      final result = await ref
          .read(deviceRegistrationServiceProvider)
          .sendDeveloperTestPush();
      await refresh();
      if (!mounted) {
        return;
      }
      final error = (result['error'] as String?)?.trim() ?? '';
      final sent = result['sent'] == true;
      final results = (result['results'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .toList(growable: false);
      final successCount = results
          .where((item) => item['success'] == true)
          .length;
      setState(() {
        _serverDebug = result;
        _actionHint = sent && successCount > 0
            ? _t(
                context,
                'FCM 已接受 $successCount 台设备。请看本页顶部横幅、切到桌面或下拉通知中心确认实际到达。',
                'FCM accepted $successCount device(s). Check the banner, Home Screen, or Notification Center.',
              )
            : _t(
                context,
                '测试推送未成功${error.isEmpty ? '' : '：$error'}。请对照下方检查项。',
                'Test push failed${error.isEmpty ? '' : ': $error'}. Check the items below.',
              );
      });
      context.showCenteredNotice(
        sent && successCount > 0
            ? _t(context, '测试推送已发出', 'Test push sent')
            : _t(context, '测试推送失败', 'Test push failed'),
      );
      await ref
          .read(diagnosticLogServiceProvider)
          .recordInfo(
            category: 'developer.firebase',
            message: 'Sent developer Firebase test push',
            details: {
              'sent': sent,
              'error': error,
              'success_count': successCount,
              'result_count': results.length,
            },
          );
    } on Object catch (error) {
      await ref
          .read(diagnosticLogServiceProvider)
          .recordError(
            category: 'developer.firebase',
            message: 'Sending developer Firebase test push failed',
            details: {'error': error.toString()},
          );
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);
    ref.watch(appConfigProvider);
    final palette = _FirebasePanelPalette.of(context);
    final diagnostics = _diagnostics;
    final checks = diagnostics == null
        ? const <_CheckItem>[]
        : _buildChecks(context, diagnostics);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            _t(context, 'Firebase 推送诊断', 'Firebase push diagnostics'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: palette.secondaryText,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t(
                    context,
                    '对照客户端 Token、系统权限、APNs 环境和服务器登记状态，并可直接发一条测试推送。',
                    'Inspect client tokens, permission, APNs environment, and server registration, then send a test push.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.secondaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                if (_loading && diagnostics == null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: CircularProgressIndicator(color: palette.accent),
                    ),
                  )
                else ...[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _chip(
                        palette,
                        Icons.cloud_outlined,
                        diagnostics?.available == true
                            ? _t(context, 'Firebase 已初始化', 'Firebase ready')
                            : _t(
                                context,
                                'Firebase 未就绪',
                                'Firebase unavailable',
                              ),
                      ),
                      if ((diagnostics?.projectId ?? '').isNotEmpty)
                        _chip(
                          palette,
                          Icons.tag_rounded,
                          diagnostics!.projectId,
                        ),
                      if ((diagnostics?.senderId ?? '').isNotEmpty)
                        _chip(
                          palette,
                          Icons.numbers_rounded,
                          'Sender ${diagnostics!.senderId}',
                        ),
                      if (diagnostics?.nativePlatform == 'ios' &&
                          diagnostics!.apsEnvironment.isNotEmpty)
                        _chip(
                          palette,
                          Icons.apple,
                          'APNs ${diagnostics.apsEnvironment}',
                        ),
                      if (_deviceId != null)
                        _chip(
                          palette,
                          Icons.smartphone_rounded,
                          '${_t(context, '设备', 'Device')} ${_shortId(_deviceId!)}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...checks.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CheckRow(palette: palette, item: item),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TokenRow(
                    palette: palette,
                    title: 'FCM Token',
                    value: diagnostics?.fcmToken,
                    error: diagnostics?.fcmTokenError,
                    onCopy: () => _copy(
                      diagnostics?.fcmToken,
                      _t(context, '当前没有 FCM Token', 'No FCM token yet'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TokenRow(
                    palette: palette,
                    title: 'APNs Token',
                    value: diagnostics?.apnsToken,
                    error: diagnostics?.apnsTokenError,
                    onCopy: () => _copy(
                      diagnostics?.apnsToken,
                      _t(context, '当前没有 APNs Token', 'No APNs token yet'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: _busy || _loading ? null : _sendTestPush,
                        icon: const Icon(Icons.outgoing_mail),
                        label: Text(_t(context, '发送测试推送', 'Send test push')),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy || _loading
                            ? null
                            : () => refresh(waitForApns: Platform.isIOS),
                        icon: _loading
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(_t(context, '刷新诊断', 'Refresh diagnostics')),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy || _loading ? null : _registerDevice,
                        icon: const Icon(Icons.phonelink_setup_rounded),
                        label: Text(
                          _t(context, '重新登记设备', 'Re-register device'),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy || _loading
                            ? null
                            : _requestPermission,
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: Text(
                          _t(context, '请求推送权限', 'Request push permission'),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _busy || _loading ? null : _refreshToken,
                        icon: const Icon(Icons.sync_rounded),
                        label: Text(_t(context, '刷新 Token', 'Refresh token')),
                      ),
                    ],
                  ),
                  if (_actionHint != null) ...[
                    const SizedBox(height: 12),
                    _HintBox(palette: palette, text: _actionHint!),
                  ],
                  if (_serverResultText(context).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _HintBox(
                      palette: palette,
                      text: _serverResultText(context),
                    ),
                  ],
                  if ((diagnostics?.recentEvents ?? const []).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _t(context, '最近收到的远程消息', 'Recent remote messages'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: palette.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...diagnostics!.recentEvents.map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _EventRow(palette: palette, event: event),
                      ),
                    ),
                  ],
                  if ((diagnostics?.initializeError ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _HintBox(
                      palette: palette,
                      text:
                          '${_t(context, '初始化错误', 'Initialize error')}: ${diagnostics!.initializeError}',
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_CheckItem> _buildChecks(
    BuildContext context,
    FirebasePushDiagnostics diagnostics,
  ) {
    final appConfig = ref.watch(appConfigProvider).valueOrNull;
    final serverEnabled = _serverDebug['firebase_enabled'] == true;
    final serverProjectId =
        (_serverDebug['firebase_project_id'] as String?)?.trim() ??
        appConfig?.firebaseProjectId ??
        '';
    final projectMatches =
        diagnostics.projectId.isNotEmpty &&
        serverProjectId.isNotEmpty &&
        diagnostics.projectId == serverProjectId;
    final currentRegistered = _serverDebug['current_device_registered'] == true;
    final hasServiceAccount = _serverDebug['has_service_account'] == true;
    final inQuietHours = _serverDebug['in_quiet_hours'] == true;
    final isIos = diagnostics.nativePlatform == 'ios' || Platform.isIOS;
    final items = <_CheckItem>[
      _CheckItem(
        ok: diagnostics.available,
        label: diagnostics.available
            ? _t(context, 'Firebase 已初始化', 'Firebase initialized')
            : _t(context, 'Firebase 初始化失败', 'Firebase initialization failed'),
      ),
      _CheckItem(
        ok:
            diagnostics.authorizationStatus == 'authorized' ||
            diagnostics.authorizationStatus == 'provisional',
        label:
            '${_t(context, '通知授权', 'Notification authorization')}: ${diagnostics.authorizationStatus.isEmpty ? '-' : diagnostics.authorizationStatus}',
      ),
    ];
    if (isIos) {
      items.add(
        _CheckItem(
          ok: !diagnostics.isSimulator,
          warning: diagnostics.isSimulator,
          label: diagnostics.isSimulator
              ? _t(
                  context,
                  '当前是模拟器，远程推送需要 iOS 真机',
                  'Simulator detected. Remote push requires a physical iPhone.',
                )
              : _t(context, '当前是 iOS 真机', 'Running on a physical iPhone'),
        ),
      );
      items.add(
        _CheckItem(
          ok:
              diagnostics.apsEnvironment == 'development' ||
              diagnostics.apsEnvironment == 'production',
          label:
              '${_t(context, 'APNs 环境', 'APNs environment')}: ${diagnostics.apsEnvironment.isEmpty ? '-' : diagnostics.apsEnvironment}',
        ),
      );
      items.add(
        _CheckItem(
          ok: diagnostics.native['hasRemoteNotificationBackgroundMode'] == true,
          label:
              diagnostics.native['hasRemoteNotificationBackgroundMode'] == true
              ? _t(
                  context,
                  '已开启 remote-notification 后台模式',
                  'remote-notification background mode is enabled',
                )
              : _t(
                  context,
                  'Info.plist 缺少 remote-notification 后台模式',
                  'Info.plist is missing the remote-notification background mode',
                ),
        ),
      );
      items.add(
        _CheckItem(
          ok: diagnostics.isRegisteredForRemoteNotifications,
          label: diagnostics.isRegisteredForRemoteNotifications
              ? _t(context, '已向系统注册远程通知', 'Registered for remote notifications')
              : _t(
                  context,
                  '尚未向系统注册远程通知',
                  'Not registered for remote notifications',
                ),
        ),
      );
      items.add(
        _CheckItem(
          ok: diagnostics.hasApnsToken,
          label: diagnostics.hasApnsToken
              ? _t(context, 'APNs Token 已获取', 'APNs token available')
              : _t(
                  context,
                  'APNs Token 为空，FCM Token 不会签发',
                  'APNs token missing; FCM token will not be issued',
                ),
        ),
      );
    }
    items.add(
      _CheckItem(
        ok: diagnostics.hasFcmToken,
        label: diagnostics.hasFcmToken
            ? _t(
                context,
                'FCM Token 已获取（${diagnostics.fcmToken!.length}）',
                'FCM token available (${diagnostics.fcmToken!.length})',
              )
            : _t(context, 'FCM Token 为空', 'FCM token missing'),
      ),
    );
    if (_isLoggedIn) {
      items.add(
        _CheckItem(
          ok: serverEnabled || (appConfig?.firebaseEnabled ?? false),
          label: serverEnabled || (appConfig?.firebaseEnabled ?? false)
              ? _t(
                  context,
                  '服务器已启用 Firebase 推送',
                  'Server Firebase push is enabled',
                )
              : _t(
                  context,
                  '服务器未启用 Firebase 推送',
                  'Server Firebase push is disabled',
                ),
        ),
      );
      items.add(
        _CheckItem(
          ok: projectMatches,
          label: projectMatches
              ? _t(
                  context,
                  '客户端与服务器 Project ID 一致',
                  'Client and server Project IDs match',
                )
              : _t(
                  context,
                  'Project ID 不一致：client=${diagnostics.projectId.isEmpty ? '-' : diagnostics.projectId} / server=${serverProjectId.isEmpty ? '-' : serverProjectId}',
                  'Project ID mismatch: client=${diagnostics.projectId.isEmpty ? '-' : diagnostics.projectId} / server=${serverProjectId.isEmpty ? '-' : serverProjectId}',
                ),
        ),
      );
      items.add(
        _CheckItem(
          ok: hasServiceAccount,
          label: hasServiceAccount
              ? _t(context, '服务器已加载服务账号', 'Server service account is loaded')
              : _t(context, '服务器未加载服务账号', 'Server service account is missing'),
        ),
      );
      items.add(
        _CheckItem(
          ok: currentRegistered,
          label: currentRegistered
              ? _t(context, '当前设备已在服务器登记', 'Current device is registered')
              : _t(context, '当前设备尚未在服务器登记', 'Current device is not registered'),
        ),
      );
      items.add(
        _CheckItem(
          ok: !inQuietHours,
          warning: inQuietHours,
          label: inQuietHours
              ? _t(
                  context,
                  '当前处于免打扰时段，业务推送会被抑制',
                  'Quiet hours are active; business pushes are suppressed',
                )
              : _t(context, '当前不在免打扰时段', 'Outside quiet hours'),
        ),
      );
    } else {
      items.add(
        _CheckItem(
          ok: false,
          warning: true,
          label: _t(
            context,
            '未登录，无法核对服务器登记和发送测试推送',
            'Sign in to inspect server registration and send a test push',
          ),
        ),
      );
    }
    return items;
  }

  String _serverResultText(BuildContext context) {
    final results = (_serverDebug['results'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .toList(growable: false);
    if (results.isEmpty && (_serverDebug['error'] as String? ?? '').isEmpty) {
      return '';
    }
    if (results.isEmpty) {
      return '${_t(context, '服务器', 'Server')}: ${_serverDebug['error']}';
    }
    final lines = results.map((item) {
      final success = item['success'] == true;
      final platform = item['platform'] ?? '-';
      final status = item['status_code'] ?? '-';
      final error = (item['error'] as String?)?.trim() ?? '';
      final code = (item['fcm_error_code'] as String?)?.trim() ?? '';
      final suffix = success
          ? 'HTTP $status'
          : [error, code].where((value) => value.isNotEmpty).join(' / ');
      return '$platform: $suffix';
    });
    return lines.join('\n');
  }

  Widget _chip(_FirebasePanelPalette palette, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.mutedBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: palette.secondaryText),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckItem {
  const _CheckItem({
    required this.ok,
    required this.label,
    this.warning = false,
  });

  final bool ok;
  final bool warning;
  final String label;
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.palette, required this.item});

  final _FirebasePanelPalette palette;
  final _CheckItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.ok
        ? palette.success
        : item.warning
        ? palette.warning
        : palette.danger;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          item.ok
              ? Icons.check_circle_rounded
              : item.warning
              ? Icons.warning_amber_rounded
              : Icons.cancel_rounded,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.primaryText,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({
    required this.palette,
    required this.title,
    required this.value,
    required this.onCopy,
    this.error,
  });

  final _FirebasePanelPalette palette;
  final String title;
  final String? value;
  final String? error;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final display = value == null || value!.isEmpty
        ? (error == null || error!.isEmpty ? '-' : error!)
        : _maskToken(value!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: palette.mutedBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  display,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.primaryText,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            tooltip: _t(context, '复制', 'Copy'),
            icon: Icon(Icons.copy_rounded, color: palette.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.palette, required this.event});

  final _FirebasePanelPalette palette;
  final FirebasePushEvent event;

  @override
  Widget build(BuildContext context) {
    final time = _formatDateTime(event.receivedAt);
    final title = event.title?.trim().isNotEmpty == true
        ? event.title!
        : event.isDeveloperTest
        ? _t(context, '开发者测试推送', 'Developer test push')
        : _t(context, '远程消息', 'Remote message');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: palette.mutedBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title · ${event.source} · $time',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((event.body ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              event.body!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.secondaryText,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.palette, required this.text});

  final _FirebasePanelPalette palette;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.mutedBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: palette.secondaryText,
          height: 1.5,
        ),
      ),
    );
  }
}

class _FirebasePanelPalette {
  const _FirebasePanelPalette({
    required this.cardBackground,
    required this.mutedBackground,
    required this.border,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.primaryText,
    required this.secondaryText,
  });

  final Color cardBackground;
  final Color mutedBackground;
  final Color border;
  final Color accent;
  final Color success;
  final Color warning;
  final Color danger;
  final Color primaryText;
  final Color secondaryText;

  static _FirebasePanelPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _FirebasePanelPalette(
        cardBackground: Color(0xFF1C2028),
        mutedBackground: Color(0xFF252A33),
        border: Color(0xFF313744),
        accent: Color(0xFFFFB4A8),
        success: Color(0xFF77D6A3),
        warning: Color(0xFFFFAE4D),
        danger: Color(0xFFFF8A8A),
        primaryText: Color(0xFFF7F3F1),
        secondaryText: Color(0xFFB0B5BF),
      );
    }
    return const _FirebasePanelPalette(
      cardBackground: Colors.white,
      mutedBackground: Color(0xFFF7F7FA),
      border: Color(0xFFE7E8EE),
      accent: Color(0xFFFF9585),
      success: Color(0xFF3FA971),
      warning: Color(0xFFFFAE4D),
      danger: Color(0xFFE56464),
      primaryText: Color(0xFF303236),
      secondaryText: Color(0xFF7D828A),
    );
  }
}

String _maskToken(String value) {
  if (value.length <= 16) {
    return '${value.length} chars';
  }
  return '${value.substring(0, 8)}...${value.substring(value.length - 6)} (${value.length})';
}

String _shortId(String value) {
  if (value.length <= 10) {
    return value;
  }
  return '${value.substring(0, 6)}...${value.substring(value.length - 4)}';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  return '$month-$day $hour:$minute:$second';
}

String _errorText(BuildContext context, Object error) {
  final text = error.toString().trim();
  if (text.contains('message: ')) {
    return text
        .replaceFirst(RegExp(r'^.*message: '), '')
        .replaceFirst(RegExp(r', traceId: .*$'), '');
  }
  return text.isEmpty
      ? _t(context, '操作失败，请稍后重试', 'Request failed. Please try again.')
      : text;
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(
        context,
      ).languageCode.toLowerCase().startsWith('zh')
      ? zh
      : en;
}
