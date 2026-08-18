import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../core/config/build_info.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import 'developer_firebase_panel.dart';

class AboutDeveloperScreen extends ConsumerStatefulWidget {
  const AboutDeveloperScreen({super.key});

  @override
  ConsumerState<AboutDeveloperScreen> createState() =>
      _AboutDeveloperScreenState();
}

class _AboutDeveloperScreenState extends ConsumerState<AboutDeveloperScreen> {
  final _imagePicker = ImagePicker();
  final _microphoneRecorder = AudioRecorder();

  bool _sendingNotification = false;
  bool _permissionRefreshing = true;
  bool _cameraInitializing = false;
  bool _microphoneBusy = false;
  bool _microphoneRecording = false;
  bool _flashEnabled = false;
  bool _usingFrontCamera = false;
  double _microphoneAmplitude = -60;
  double _microphonePeakAmplitude = -60;
  DateTime? _lastNotificationAt;
  String? _lastNotificationSnapshot;
  String? _notificationDiagnosticsText;
  DateTime? _lastPermissionCheckAt;
  DateTime? _microphoneRecordingStartedAt;
  Duration? _lastMicrophoneDuration;
  XFile? _pickedImage;
  PlatformFile? _pickedFile;
  String? _pickedDirectoryPath;
  String? _lastMicrophoneRecordingPath;
  String? _cameraError;
  CameraController? _cameraController;
  StreamSubscription<Amplitude>? _microphoneAmplitudeSubscription;
  List<CameraDescription> _availableCameras = const [];
  Map<Permission, PermissionStatus> _permissionStatuses =
      const <Permission, PermissionStatus>{};
  final _firebasePanelKey = GlobalKey<DeveloperFirebasePanelState>();

  @override
  void initState() {
    super.initState();
    unawaited(_loadPermissionStatuses());
    unawaited(_recordInfo('developer.screen', 'Opened developer tools'));
  }

  @override
  void dispose() {
    unawaited(_disposeMicrophoneTest());
    unawaited(_disposeCamera());
    super.dispose();
  }

  Future<void> _refreshNotificationDiagnostics() async {
    final notificationService = ref.read(localNotificationServiceProvider);
    final diagnostics = await notificationService
        .readDeveloperNotificationDiagnostics();
    if (!mounted || diagnostics == null) {
      return;
    }
    final pendingCount = (diagnostics['pendingCount'] as num?)?.toInt() ?? 0;
    final deliveredCount =
        (diagnostics['deliveredCount'] as num?)?.toInt() ?? 0;
    setState(() {
      _lastNotificationSnapshot = _t(
        context,
        '待发送 $pendingCount 条，通知中心中 $deliveredCount 条',
        'Pending $pendingCount, delivered $deliveredCount',
      );
      _notificationDiagnosticsText = _formatNotificationDiagnostics(
        diagnostics,
      );
    });
  }

  Future<void> _loadPermissionStatuses() async {
    setState(() => _permissionRefreshing = true);
    final permissionService = ref.read(permissionServiceProvider);
    final statuses = <Permission, PermissionStatus>{
      Permission.notification: await permissionService.notificationStatus(),
      Permission.photos: await permissionService.mediaLibraryStatus(),
      Permission.camera: await permissionService.cameraStatus(),
      Permission.microphone: await permissionService.microphoneStatus(),
    };
    if (!mounted) {
      return;
    }
    setState(() {
      _permissionStatuses = statuses;
      _lastPermissionCheckAt = DateTime.now();
      _permissionRefreshing = false;
    });
  }

  Future<void> _refreshDeveloperTools() async {
    await Future.wait([
      _loadPermissionStatuses(),
      _firebasePanelKey.currentState?.refresh() ?? Future<void>.value(),
    ]);
  }

  Future<void> _requestAllPermissions() async {
    final permissionService = ref.read(permissionServiceProvider);
    try {
      await permissionService.requestNotifications();
      await ref.read(localNotificationServiceProvider).requestPermissions();
      await permissionService.requestMediaLibrary();
      await permissionService.requestVideoCallPermissions();
      await _recordInfo('developer.permissions', 'Requested core permissions');
    } on Object catch (error) {
      await _recordError(
        'developer.permissions',
        'Requesting core permissions failed',
        error,
      );
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    } finally {
      if (mounted) {
        await _loadPermissionStatuses();
      }
    }
  }

  Future<void> _handlePermissionAction(Permission permission) async {
    final permissionService = ref.read(permissionServiceProvider);
    final permissionCode = _permissionCode(permission);
    try {
      switch (permission) {
        case Permission.notification:
          await permissionService.requestNotifications();
          await ref.read(localNotificationServiceProvider).requestPermissions();
          break;
        case Permission.photos:
          await permissionService.requestMediaLibrary();
          break;
        case Permission.camera:
          await permissionService.requestCamera();
          break;
        case Permission.microphone:
          await permissionService.requestMicrophone();
          break;
        default:
          break;
      }
      await _recordInfo(
        'developer.permission.$permissionCode',
        'Requested permission',
      );
    } on Object catch (error) {
      await _recordError(
        'developer.permission.$permissionCode',
        'Permission request failed',
        error,
      );
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    } finally {
      if (mounted) {
        await _loadPermissionStatuses();
      }
    }
  }

  Future<void> _sendLocalNotification() async {
    if (_sendingNotification) {
      return;
    }
    setState(() => _sendingNotification = true);
    final permissionService = ref.read(permissionServiceProvider);
    final notificationService = ref.read(localNotificationServiceProvider);
    try {
      final currentStatus = await permissionService.notificationStatus();
      if (!_isPermissionUsable(currentStatus)) {
        await permissionService.requestNotifications();
        await notificationService.requestPermissions();
      }
      final refreshedStatus = await permissionService.notificationStatus();
      if (!_isPermissionUsable(refreshedStatus)) {
        if (mounted) {
          context.showCenteredNotice(
            _t(
              context,
              '通知权限未开启，请先授权后再测试本地通知',
              'Notification permission is required before testing local notifications.',
            ),
          );
        }
        await _recordInfo(
          'developer.notification',
          'Skipped local notification test because permission is unavailable',
        );
        return;
      }
      final result = await notificationService.scheduleDeveloperTestNotification(
        title: _t(context, 'HelpSupport 开发者测试', 'HelpSupport developer test'),
        body: _t(
          context,
          '3 秒后投递本地通知，请切到桌面或锁屏查看横幅',
          'A local notification will be delivered in 3 seconds. Switch to the Home Screen or lock the device to check the banner.',
        ),
      );
      if (!mounted) {
        return;
      }
      final scheduledAt = result.scheduledAt ?? DateTime.now();
      setState(() {
        _lastNotificationAt = scheduledAt;
        _lastNotificationSnapshot = _t(
          context,
          '待发送 ${result.pendingCount} 条，通知中心中 ${result.deliveredCount} 条',
          'Pending ${result.pendingCount}, delivered ${result.deliveredCount}',
        );
        _notificationDiagnosticsText = result.diagnostics == null
            ? null
            : _formatNotificationDiagnostics(
                result.diagnostics!,
                timeZoneIdentifier: result.timeZoneIdentifier,
              );
      });
      context.showCenteredNotice(
        _t(
          context,
          '已安排 3 秒后发送，请立即返回桌面或锁屏查看，也可下拉通知中心确认',
          'Scheduled for 3 seconds later. Return to the Home Screen or lock the device, or open Notification Center to verify it.',
        ),
      );
      await _recordInfo(
        'developer.notification',
        'Scheduled developer local notification',
        details: <String, Object?>{
          'notification_id': result.id,
          'scheduled_at': scheduledAt.toIso8601String(),
          'pending_count': result.pendingCount,
          'delivered_count': result.deliveredCount,
          'time_zone_identifier': result.timeZoneIdentifier,
          'diagnostics': result.diagnostics,
        },
      );
      unawaited(
        Future<void>.delayed(const Duration(seconds: 4), () async {
          await _refreshNotificationDiagnostics();
        }),
      );
    } on Object catch (error) {
      await _recordError(
        'developer.notification',
        'Sending local notification failed',
        error,
      );
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    } finally {
      if (mounted) {
        setState(() => _sendingNotification = false);
        await _loadPermissionStatuses();
      }
    }
  }

  Future<void> _showForegroundNotification() async {
    if (_sendingNotification) {
      return;
    }
    setState(() => _sendingNotification = true);
    final permissionService = ref.read(permissionServiceProvider);
    final notificationService = ref.read(localNotificationServiceProvider);
    try {
      final currentStatus = await permissionService.notificationStatus();
      if (!_isPermissionUsable(currentStatus)) {
        await permissionService.requestNotifications();
        await notificationService.requestPermissions();
      }
      final refreshedStatus = await permissionService.notificationStatus();
      if (!_isPermissionUsable(refreshedStatus)) {
        if (mounted) {
          context.showCenteredNotice(
            _t(
              context,
              '通知权限未开启，请先授权后再测试本地通知',
              'Notification permission is required before testing local notifications.',
            ),
          );
        }
        await _recordInfo(
          'developer.notification',
          'Skipped immediate local notification test because permission is unavailable',
        );
        return;
      }
      final result = await notificationService.showDeveloperTestNotificationNow(
        title: _t(
          context,
          'HelpSupport 前台通知测试',
          'HelpSupport foreground notification test',
        ),
        body: _t(
          context,
          '如果前台横幅链路正常，这条通知会立刻显示出来',
          'This notification should appear immediately if foreground presentation is working.',
        ),
      );
      if (!mounted) {
        return;
      }
      final shownAt = result.scheduledAt ?? DateTime.now();
      setState(() {
        _lastNotificationAt = shownAt;
        _lastNotificationSnapshot = _t(
          context,
          '待发送 ${result.pendingCount} 条，通知中心中 ${result.deliveredCount} 条',
          'Pending ${result.pendingCount}, delivered ${result.deliveredCount}',
        );
        _notificationDiagnosticsText = result.diagnostics == null
            ? null
            : _formatNotificationDiagnostics(
                result.diagnostics!,
                timeZoneIdentifier: result.timeZoneIdentifier,
              );
      });
      context.showCenteredNotice(
        _t(
          context,
          '已触发前台通知，请直接看当前页面顶部是否出现系统横幅',
          'Foreground notification sent. Check whether a system banner appears at the top immediately.',
        ),
      );
      await _recordInfo(
        'developer.notification',
        'Triggered immediate foreground local notification',
        details: <String, Object?>{
          'notification_id': result.id,
          'shown_at': shownAt.toIso8601String(),
          'pending_count': result.pendingCount,
          'delivered_count': result.deliveredCount,
          'time_zone_identifier': result.timeZoneIdentifier,
          'diagnostics': result.diagnostics,
        },
      );
      unawaited(
        Future<void>.delayed(const Duration(seconds: 1), () async {
          await _refreshNotificationDiagnostics();
        }),
      );
    } on Object catch (error) {
      await _recordError(
        'developer.notification',
        'Sending immediate foreground local notification failed',
        error,
      );
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    } finally {
      if (mounted) {
        setState(() => _sendingNotification = false);
        await _loadPermissionStatuses();
      }
    }
  }

  Future<void> _pickImage() async {
    final permissionService = ref.read(permissionServiceProvider);
    try {
      final currentStatus = await permissionService.mediaLibraryStatus();
      final status = _isPermissionUsable(currentStatus)
          ? currentStatus
          : await permissionService.requestMediaLibrary();
      await _loadPermissionStatuses();
      if (!_isPermissionUsable(status)) {
        if (mounted) {
          context.showCenteredNotice(
            _t(
              context,
              '需要开启相册权限后才能测试图片选择',
              'Photo permission is required before testing image picking.',
            ),
          );
        }
        return;
      }
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1800,
      );
      if (image == null || !mounted) {
        return;
      }
      setState(() => _pickedImage = image);
      context.showCenteredNotice(
        _t(context, '已选择测试图片', 'Image picked for testing'),
      );
      await _recordInfo(
        'developer.image_picker',
        'Picked image for developer test',
        details: {'path': image.path},
      );
    } on Object catch (error) {
      await _recordError(
        'developer.image_picker',
        'Picking image failed',
        error,
      );
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty || !mounted) {
        return;
      }
      setState(() => _pickedFile = result.files.single);
      context.showCenteredNotice(_t(context, '已选择本地文件', 'Local file picked'));
      await _recordInfo(
        'developer.file_picker',
        'Picked file for developer test',
        details: {'file': result.files.single.name},
      );
    } on Object catch (error) {
      await _recordError(
        'developer.file_picker',
        'Picking local file failed',
        error,
      );
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    }
  }

  Future<void> _pickDirectory() async {
    try {
      final directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath == null || !mounted) {
        return;
      }
      setState(() => _pickedDirectoryPath = directoryPath);
      context.showCenteredNotice(
        _t(context, '已选择本地文件夹', 'Local folder picked'),
      );
      await _recordInfo(
        'developer.directory_picker',
        'Picked local directory for developer test',
        details: {'directory': directoryPath},
      );
    } on Object catch (error) {
      await _recordError(
        'developer.directory_picker',
        'Picking local directory failed',
        error,
      );
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    }
  }

  Future<void> _toggleCameraPreview() async {
    if (_cameraController != null) {
      await _stopCameraPreview();
      return;
    }
    await _startCameraPreview(preferredDirection: CameraLensDirection.back);
  }

  Future<void> _startCameraPreview({
    required CameraLensDirection preferredDirection,
  }) async {
    if (_cameraInitializing) {
      return;
    }
    final permissionService = ref.read(permissionServiceProvider);
    setState(() {
      _cameraInitializing = true;
      _cameraError = null;
    });
    try {
      final currentStatus = await permissionService.cameraStatus();
      final status = currentStatus.isGranted
          ? currentStatus
          : await permissionService.requestCamera();
      await _loadPermissionStatuses();
      if (!status.isGranted) {
        final message = _t(
          context,
          '需要开启相机权限后才能测试摄像头',
          'Camera permission is required before testing the camera.',
        );
        if (!mounted) {
          return;
        }
        setState(() => _cameraError = message);
        context.showCenteredNotice(message);
        return;
      }

      final cameras = _availableCameras.isEmpty
          ? await availableCameras()
          : _availableCameras;
      if (cameras.isEmpty) {
        throw StateError(
          _t(context, '当前设备没有可用摄像头', 'No camera is available on this device.'),
        );
      }

      final selected =
          _pickCamera(cameras, preferredDirection) ?? cameras.first;
      final previousController = _cameraController;
      _cameraController = null;
      if (mounted) {
        setState(() => _flashEnabled = false);
      }
      if (previousController != null) {
        try {
          await previousController.setFlashMode(FlashMode.off);
        } on Object {
          // Ignore teardown failures when replacing the active camera.
        }
        await previousController.dispose();
      }
      final nextController = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await nextController.initialize();

      _cameraController = nextController;
      _availableCameras = cameras;

      if (mounted) {
        setState(() {
          _usingFrontCamera =
              selected.lensDirection == CameraLensDirection.front;
          _flashEnabled = false;
          _cameraError = null;
        });
      }

      await _recordInfo(
        'developer.camera',
        'Started camera preview',
        details: {
          'lens_direction': selected.lensDirection.name,
          'camera_name': selected.name,
        },
      );
    } on Object catch (error) {
      final text = error is CameraException
          ? _describeCameraException(context, error)
          : _errorText(context, error);
      await _recordError(
        'developer.camera',
        'Starting camera preview failed',
        error,
      );
      if (!mounted) {
        return;
      }
      setState(() => _cameraError = text);
      context.showCenteredNotice(text);
    } finally {
      if (mounted) {
        setState(() => _cameraInitializing = false);
      }
    }
  }

  Future<void> _stopCameraPreview() async {
    await _disposeCamera();
    if (!mounted) {
      return;
    }
    setState(() {
      _flashEnabled = false;
      _cameraError = null;
    });
    await _recordInfo('developer.camera', 'Stopped camera preview');
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null) {
      return;
    }
    try {
      final nextEnabled = !_flashEnabled;
      await controller.setFlashMode(
        nextEnabled ? FlashMode.torch : FlashMode.off,
      );
      if (!mounted) {
        return;
      }
      setState(() => _flashEnabled = nextEnabled);
      context.showCenteredNotice(
        nextEnabled
            ? _t(context, '闪光灯已开启', 'Flashlight enabled')
            : _t(context, '闪光灯已关闭', 'Flashlight disabled'),
      );
      await _recordInfo(
        'developer.flash',
        nextEnabled ? 'Enabled flashlight' : 'Disabled flashlight',
      );
    } on Object catch (error) {
      final text = error is CameraException
          ? _describeCameraException(context, error)
          : _errorText(context, error);
      await _recordError(
        'developer.flash',
        'Toggling flashlight failed',
        error,
      );
      if (mounted) {
        context.showCenteredNotice(text);
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2) {
      context.showCenteredNotice(
        _t(context, '当前设备没有可切换的镜头', 'No alternate camera is available.'),
      );
      return;
    }
    await _startCameraPreview(
      preferredDirection: _usingFrontCamera
          ? CameraLensDirection.back
          : CameraLensDirection.front,
    );
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<void> _toggleMicrophoneTest() async {
    if (_microphoneBusy) {
      return;
    }
    if (_microphoneRecording) {
      await _stopMicrophoneTest();
      return;
    }
    await _startMicrophoneTest();
  }

  Future<void> _startMicrophoneTest() async {
    final permissionService = ref.read(permissionServiceProvider);
    setState(() => _microphoneBusy = true);
    try {
      final currentStatus = await permissionService.microphoneStatus();
      final status = _isPermissionUsable(currentStatus)
          ? currentStatus
          : await permissionService.requestMicrophone();
      await _loadPermissionStatuses();
      if (!_isPermissionUsable(status)) {
        if (mounted) {
          context.showCenteredNotice(
            _t(
              context,
              '需要开启麦克风权限后才能测试录音',
              'Microphone permission is required before testing recording.',
            ),
          );
        }
        return;
      }

      final hasPermission = await _microphoneRecorder.hasPermission(
        request: false,
      );
      if (!hasPermission) {
        if (mounted) {
          context.showCenteredNotice(
            _t(
              context,
              '系统未授予麦克风访问权限，请在设置中确认',
              'Microphone access is unavailable. Check system settings.',
            ),
          );
        }
        return;
      }

      await _microphoneAmplitudeSubscription?.cancel();
      final tempDir = await getTemporaryDirectory();
      final audioPath =
          '${tempDir.path}/developer-mic-${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _microphoneRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: audioPath,
      );
      _microphoneAmplitudeSubscription = _microphoneRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 220))
          .listen((amplitude) {
            if (!mounted) {
              return;
            }
            setState(() {
              _microphoneAmplitude = amplitude.current;
              _microphonePeakAmplitude = math.max(
                _microphonePeakAmplitude,
                amplitude.max,
              );
            });
          });

      final startedAt = DateTime.now();
      if (!mounted) {
        return;
      }
      setState(() {
        _microphoneRecording = true;
        _microphoneRecordingStartedAt = startedAt;
        _microphoneAmplitude = -60;
        _microphonePeakAmplitude = -60;
      });
      context.showCenteredNotice(
        _t(
          context,
          '麦克风录音测试已开始，请对着设备说话',
          'Microphone recording test started. Speak into the device.',
        ),
      );
      await _recordInfo(
        'developer.microphone',
        'Started microphone recording test',
        details: {'path': audioPath},
      );
    } on Object catch (error) {
      await _recordError(
        'developer.microphone',
        'Starting microphone recording failed',
        error,
      );
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    } finally {
      if (mounted) {
        setState(() => _microphoneBusy = false);
      }
    }
  }

  Future<void> _stopMicrophoneTest() async {
    if (_microphoneBusy) {
      return;
    }
    setState(() => _microphoneBusy = true);
    try {
      final startedAt = _microphoneRecordingStartedAt;
      final recordingPath = await _microphoneRecorder.stop();
      await _microphoneAmplitudeSubscription?.cancel();
      _microphoneAmplitudeSubscription = null;
      final duration = startedAt == null
          ? Duration.zero
          : DateTime.now().difference(startedAt);
      if (!mounted) {
        return;
      }
      setState(() {
        _microphoneRecording = false;
        _microphoneRecordingStartedAt = null;
        _lastMicrophoneDuration = duration;
        _lastMicrophoneRecordingPath = recordingPath;
      });
      context.showCenteredNotice(
        _t(context, '麦克风录音测试已结束', 'Microphone recording test stopped.'),
      );
      await _recordInfo(
        'developer.microphone',
        'Stopped microphone recording test',
        details: {
          'path': recordingPath,
          'duration_ms': duration.inMilliseconds,
        },
      );
    } on Object catch (error) {
      await _recordError(
        'developer.microphone',
        'Stopping microphone recording failed',
        error,
      );
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    } finally {
      if (mounted) {
        setState(() => _microphoneBusy = false);
      }
    }
  }

  Future<void> _disposeMicrophoneTest() async {
    await _microphoneAmplitudeSubscription?.cancel();
    _microphoneAmplitudeSubscription = null;
    try {
      if (await _microphoneRecorder.isRecording()) {
        await _microphoneRecorder.cancel();
      }
    } on Object {
      // Ignore disposal-time recorder errors.
    }
    await _microphoneRecorder.dispose();
  }

  CameraDescription? _pickCamera(
    List<CameraDescription> cameras,
    CameraLensDirection direction,
  ) {
    for (final camera in cameras) {
      if (camera.lensDirection == direction) {
        return camera;
      }
    }
    return null;
  }

  Future<void> _recordInfo(String category, String message, {Object? details}) {
    return ref
        .read(diagnosticLogServiceProvider)
        .recordInfo(category: category, message: message, details: details);
  }

  Future<void> _recordError(String category, String message, Object error) {
    return ref
        .read(diagnosticLogServiceProvider)
        .recordError(
          category: category,
          message: message,
          details: {'error': error.toString()},
        );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _DeveloperPalette.of(context);
    final cameraController = _cameraController;

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        title: Text(_t(context, '开发者工具', 'Developer tools')),
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        actions: [
          IconButton(
            onPressed: _permissionRefreshing ? null : _refreshDeveloperTools,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: _t(context, '刷新状态', 'Refresh status'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDeveloperTools,
          color: palette.accent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _SectionCard(
                palette: palette,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: palette.accentSoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.developer_mode_rounded,
                            color: palette.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t(
                                  context,
                                  '隐藏测试入口',
                                  'Hidden verification toolbox',
                                ),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: palette.primaryText,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _t(
                                  context,
                                  '集中验证 AI、自诊断、Firebase 推送、通知、相机、闪光灯、图片/文件选择与权限状态。',
                                  'Validate AI, diagnostics, Firebase push, notifications, camera, flashlight, pickers, and permission state in one place.',
                                ),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: palette.secondaryText,
                                      height: 1.55,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetaChip(
                          palette: palette,
                          icon: Icons.info_outline_rounded,
                          label:
                              '${BuildInfo.appName} ${BuildInfo.shortVersion}',
                        ),
                        _MetaChip(
                          palette: palette,
                          icon: Icons.phone_iphone_rounded,
                          label: Platform.operatingSystem,
                        ),
                        _MetaChip(
                          palette: palette,
                          icon: Icons.schedule_rounded,
                          label: _lastPermissionCheckAt == null
                              ? _t(context, '待刷新', 'Pending refresh')
                              : _formatDateTime(_lastPermissionCheckAt!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionLabel(
                palette: palette,
                title: _t(context, '内置页面', 'Built-in pages'),
              ),
              const SizedBox(height: 10),
              _SectionCard(
                palette: palette,
                child: Column(
                  children: [
                    _LinkTile(
                      palette: palette,
                      icon: Icons.smart_toy_outlined,
                      title: _t(context, 'AI 运行测试', 'AI capability test'),
                      subtitle: _t(
                        context,
                        '继续使用现有本地模型自检页',
                        'Open the existing local AI self-test screen',
                      ),
                      onTap: () =>
                          context.push('/me/settings/about/ai-capability'),
                    ),
                    const SizedBox(height: 12),
                    _LinkTile(
                      palette: palette,
                      icon: Icons.medical_information_outlined,
                      title: _t(context, '诊断信息', 'Diagnostics'),
                      subtitle: _t(
                        context,
                        '查看本地诊断日志并手动上传',
                        'Inspect and upload local diagnostic logs',
                      ),
                      onTap: () =>
                          context.push('/me/settings/about/diagnostics'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              DeveloperFirebasePanel(key: _firebasePanelKey),
              const SizedBox(height: 18),
              _SectionLabel(
                palette: palette,
                title: _t(
                  context,
                  '通知、麦克风与媒体测试',
                  'Notifications, microphone, and media tests',
                ),
              ),
              const SizedBox(height: 10),
              _SectionCard(
                palette: palette,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(context, '本地通知测试', 'Local notification test'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: palette.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _t(
                        context,
                        '先用“立即前台横幅”确认当前页顶部能否立刻弹出系统横幅，再用“3 秒后系统通知”验证回桌面或锁屏后的投递链路；Android 未开放精确闹钟时会自动改用非精确定时。',
                        'Use the immediate foreground banner test first, then use the 3-second system notification test after leaving the app or locking the device; Android falls back to inexact scheduling when exact alarms are unavailable.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.secondaryText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: _sendingNotification
                              ? null
                              : _showForegroundNotification,
                          icon: _sendingNotification
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.notification_important_rounded,
                                ),
                          label: Text(
                            _t(
                              context,
                              '立即前台横幅',
                              'Immediate foreground banner',
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _sendingNotification
                              ? null
                              : _sendLocalNotification,
                          icon: _sendingNotification
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.notifications_active_rounded),
                          label: Text(
                            _t(
                              context,
                              '安排 3 秒后通知',
                              'Schedule 3-second notification',
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _refreshNotificationDiagnostics,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(
                            _t(context, '刷新通知状态', 'Refresh notification state'),
                          ),
                        ),
                        if (_lastNotificationAt != null)
                          _MetaChip(
                            palette: palette,
                            icon: Icons.check_circle_outline_rounded,
                            label:
                                '${_t(context, '上次计划', 'Last scheduled')} ${_formatDateTime(_lastNotificationAt!)}',
                          ),
                        if (_lastNotificationSnapshot != null)
                          _MetaChip(
                            palette: palette,
                            icon: Icons.mark_email_unread_outlined,
                            label: _lastNotificationSnapshot!,
                          ),
                      ],
                    ),
                    if (_notificationDiagnosticsText != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.mutedBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: palette.border),
                        ),
                        child: Text(
                          _notificationDiagnosticsText!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: palette.secondaryText,
                                height: 1.5,
                              ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Divider(color: palette.border),
                    const SizedBox(height: 18),
                    Text(
                      _t(context, '麦克风测试', 'Microphone test'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: palette.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _t(
                        context,
                        '开始一段本地录音并实时显示输入电平，停止后保存测试音频，验证麦克风权限和采集链路。',
                        'Record a short local clip with live input levels to verify microphone permission and capture.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.secondaryText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: _microphoneBusy
                              ? null
                              : _toggleMicrophoneTest,
                          icon: Icon(
                            _microphoneRecording
                                ? Icons.stop_circle_outlined
                                : Icons.mic_none_rounded,
                          ),
                          label: Text(
                            _microphoneRecording
                                ? _t(context, '停止录音测试', 'Stop recording')
                                : _t(context, '开始录音测试', 'Start recording'),
                          ),
                        ),
                        _MetaChip(
                          palette: palette,
                          icon: Icons.graphic_eq_rounded,
                          label: _microphoneRecording
                              ? _t(context, '录音中', 'Recording')
                              : _t(context, '待开始', 'Idle'),
                        ),
                        if (_lastMicrophoneDuration != null)
                          _MetaChip(
                            palette: palette,
                            icon: Icons.schedule_rounded,
                            label:
                                '${_t(context, '最近录音', 'Last clip')} ${_formatDuration(_lastMicrophoneDuration!)}',
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: palette.mutedBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: palette.border),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _microphoneRecording
                                      ? _t(
                                          context,
                                          '正在采集麦克风输入',
                                          'Capturing microphone input',
                                        )
                                      : _t(
                                          context,
                                          '录音测试结果',
                                          'Microphone test result',
                                        ),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: palette.primaryText,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              Text(
                                _microphoneRecording
                                    ? _formatDuration(
                                        _activeMicrophoneDuration(
                                          _microphoneRecordingStartedAt,
                                        ),
                                      )
                                    : _lastMicrophoneRecordingPath == null
                                    ? _t(context, '未录音', 'No clip')
                                    : _formatAmplitude(
                                        _microphonePeakAmplitude,
                                      ),
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: palette.accent,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 9,
                              value: _normalizedAmplitude(_microphoneAmplitude),
                              backgroundColor: palette.previewBackground,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                palette.accent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _microphoneRecording
                                ? _t(
                                    context,
                                    '当前电平 ${_formatAmplitude(_microphoneAmplitude)}，峰值 ${_formatAmplitude(_microphonePeakAmplitude)}',
                                    'Current level ${_formatAmplitude(_microphoneAmplitude)}, peak ${_formatAmplitude(_microphonePeakAmplitude)}',
                                  )
                                : _lastMicrophoneRecordingPath == null
                                ? _t(
                                    context,
                                    '还没有录制测试音频，开始录音后这里会显示实时电平。',
                                    'No test clip yet. Live levels will appear once recording starts.',
                                  )
                                : _lastMicrophoneRecordingPath!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: palette.secondaryText,
                                  height: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Divider(color: palette.border),
                    const SizedBox(height: 18),
                    Text(
                      _t(context, '图片选择测试', 'Image picker test'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: palette.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _t(
                        context,
                        '调用系统相册并回显已选图片，验证相册权限和图片选择流程。',
                        'Open the system photo picker and preview the selected image.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.secondaryText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(_t(context, '选择测试图片', 'Pick test image')),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder_open_rounded),
                          label: Text(_t(context, '选择本地文件', 'Pick local file')),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickDirectory,
                          icon: const Icon(Icons.folder_copy_outlined),
                          label: Text(
                            _t(context, '选择本地文件夹', 'Pick local folder'),
                          ),
                        ),
                      ],
                    ),
                    if (_pickedImage != null) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 1.28,
                          child: Image.file(
                            File(_pickedImage!.path),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _PreviewPlaceholder(
                              palette: palette,
                              icon: Icons.broken_image_outlined,
                              title: _t(
                                context,
                                '图片预览失败',
                                'Image preview unavailable',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _pickedImage!.path,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.secondaryText,
                        ),
                      ),
                    ],
                    if (_pickedFile != null) ...[
                      const SizedBox(height: 14),
                      _ResultBar(
                        palette: palette,
                        icon: Icons.insert_drive_file_outlined,
                        title: _pickedFile!.name,
                        subtitle:
                            '${_t(context, '大小', 'Size')}: ${_formatFileSize(_pickedFile!.size)}',
                      ),
                    ],
                    if (_pickedDirectoryPath != null) ...[
                      const SizedBox(height: 14),
                      _ResultBar(
                        palette: palette,
                        icon: Icons.folder_copy_outlined,
                        title: _t(context, '已选择文件夹', 'Selected folder'),
                        subtitle: _pickedDirectoryPath!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionLabel(
                palette: palette,
                title: _t(context, '摄像头与闪光灯', 'Camera and flashlight'),
              ),
              const SizedBox(height: 10),
              _SectionCard(
                palette: palette,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(context, '摄像头测试', 'Camera test'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: palette.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _t(
                        context,
                        '启动实时预览，验证摄像头权限、镜头切换和闪光灯控制。',
                        'Start a live preview to verify camera permission, lens switching, and flashlight control.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.secondaryText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: palette.previewBackground,
                        ),
                        child: AspectRatio(
                          aspectRatio: 1.2,
                          child:
                              cameraController != null &&
                                  cameraController.value.isInitialized
                              ? CameraPreview(cameraController)
                              : _PreviewPlaceholder(
                                  palette: palette,
                                  loading: _cameraInitializing,
                                  icon: Icons.videocam_off_rounded,
                                  title:
                                      _cameraError ??
                                      _t(
                                        context,
                                        '点击下方按钮启动摄像头测试',
                                        'Start the camera test with the buttons below',
                                      ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: _cameraInitializing
                              ? null
                              : _toggleCameraPreview,
                          icon: Icon(
                            cameraController == null
                                ? Icons.play_circle_outline_rounded
                                : Icons.stop_circle_outlined,
                          ),
                          label: Text(
                            cameraController == null
                                ? _t(context, '启动摄像头', 'Start camera')
                                : _t(context, '停止摄像头', 'Stop camera'),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              cameraController == null || _cameraInitializing
                              ? null
                              : _switchCamera,
                          icon: const Icon(Icons.cameraswitch_rounded),
                          label: Text(_t(context, '切换镜头', 'Switch lens')),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              cameraController == null || _cameraInitializing
                              ? null
                              : _toggleFlash,
                          icon: Icon(
                            _flashEnabled
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                          ),
                          label: Text(
                            _flashEnabled
                                ? _t(context, '关闭闪光灯', 'Disable flash')
                                : _t(context, '开启闪光灯', 'Enable flash'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetaChip(
                          palette: palette,
                          icon: Icons.camera_alt_outlined,
                          label: cameraController == null
                              ? _t(context, '未启动预览', 'Preview stopped')
                              : _usingFrontCamera
                              ? _t(context, '前置镜头', 'Front camera')
                              : _t(context, '后置镜头', 'Rear camera'),
                        ),
                        _MetaChip(
                          palette: palette,
                          icon: _flashEnabled
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          label: _flashEnabled
                              ? _t(context, '闪光灯开启', 'Flash on')
                              : _t(context, '闪光灯关闭', 'Flash off'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionLabel(
                palette: palette,
                title: _t(context, '权限测试', 'Permission checks'),
              ),
              const SizedBox(height: 10),
              _SectionCard(
                palette: palette,
                child: Column(
                  children: [
                    _PermissionTile(
                      palette: palette,
                      icon: Icons.notifications_none_rounded,
                      title: _t(context, '通知权限', 'Notification permission'),
                      subtitle: _t(
                        context,
                        '本地通知与推送提醒使用',
                        'Used by local notifications and push reminders',
                      ),
                      statusLabel: _permissionLabel(
                        context,
                        _statusOf(Permission.notification),
                      ),
                      statusColor: _permissionColor(
                        palette,
                        _statusOf(Permission.notification),
                      ),
                      actionLabel: _permissionActionLabel(
                        context,
                        _statusOf(Permission.notification),
                      ),
                      onAction: () =>
                          _handlePermissionAction(Permission.notification),
                      onSettings: () => openAppSettings(),
                    ),
                    const SizedBox(height: 12),
                    _PermissionTile(
                      palette: palette,
                      icon: Icons.photo_library_outlined,
                      title: _t(context, '相册权限', 'Photo permission'),
                      subtitle: _t(
                        context,
                        '社区发帖、头像、图片选择测试使用',
                        'Used by posts, avatar uploads, and image picker tests',
                      ),
                      statusLabel: _permissionLabel(
                        context,
                        _statusOf(Permission.photos),
                      ),
                      statusColor: _permissionColor(
                        palette,
                        _statusOf(Permission.photos),
                      ),
                      actionLabel: _permissionActionLabel(
                        context,
                        _statusOf(Permission.photos),
                      ),
                      onAction: () =>
                          _handlePermissionAction(Permission.photos),
                      onSettings: () => openAppSettings(),
                    ),
                    const SizedBox(height: 12),
                    _PermissionTile(
                      palette: palette,
                      icon: Icons.camera_alt_outlined,
                      title: _t(context, '相机权限', 'Camera permission'),
                      subtitle: _t(
                        context,
                        '视频问诊、医生认证、摄像头测试使用',
                        'Used by video calls, doctor verification, and camera tests',
                      ),
                      statusLabel: _permissionLabel(
                        context,
                        _statusOf(Permission.camera),
                      ),
                      statusColor: _permissionColor(
                        palette,
                        _statusOf(Permission.camera),
                      ),
                      actionLabel: _permissionActionLabel(
                        context,
                        _statusOf(Permission.camera),
                      ),
                      onAction: () =>
                          _handlePermissionAction(Permission.camera),
                      onSettings: () => openAppSettings(),
                    ),
                    const SizedBox(height: 12),
                    _PermissionTile(
                      palette: palette,
                      icon: Icons.mic_none_rounded,
                      title: _t(context, '麦克风权限', 'Microphone permission'),
                      subtitle: _t(
                        context,
                        '视频问诊和语音输入使用',
                        'Used by video calls and voice input',
                      ),
                      statusLabel: _permissionLabel(
                        context,
                        _statusOf(Permission.microphone),
                      ),
                      statusColor: _permissionColor(
                        palette,
                        _statusOf(Permission.microphone),
                      ),
                      actionLabel: _permissionActionLabel(
                        context,
                        _statusOf(Permission.microphone),
                      ),
                      onAction: () =>
                          _handlePermissionAction(Permission.microphone),
                      onSettings: () => openAppSettings(),
                    ),
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette.mutedBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: palette.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.folder_copy_outlined,
                              color: palette.secondaryText,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _t(
                                  context,
                                  '本地文件和文件夹访问通过系统文档选择器完成，iOS 不存在单独的“文件夹权限”运行时授权；请直接使用上面的文件/文件夹测试确认系统选择器链路。',
                                  'Local file and folder access uses the system document picker. iOS has no separate runtime folder permission; use the file and folder tests above.',
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: palette.secondaryText,
                                      height: 1.5,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: _permissionRefreshing
                              ? null
                              : _requestAllPermissions,
                          icon: const Icon(Icons.verified_user_outlined),
                          label: Text(
                            _t(context, '申请核心权限', 'Request core permissions'),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: openAppSettings,
                          icon: const Icon(Icons.settings_outlined),
                          label: Text(
                            _t(context, '打开系统设置', 'Open system settings'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PermissionStatus _statusOf(Permission permission) {
    return _permissionStatuses[permission] ?? PermissionStatus.denied;
  }
}

class _DeveloperPalette {
  const _DeveloperPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.mutedBackground,
    required this.previewBackground,
    required this.border,
    required this.accent,
    required this.accentSoft,
    required this.success,
    required this.warning,
    required this.danger,
    required this.primaryText,
    required this.secondaryText,
  });

  final Color pageBackground;
  final Color cardBackground;
  final Color mutedBackground;
  final Color previewBackground;
  final Color border;
  final Color accent;
  final Color accentSoft;
  final Color success;
  final Color warning;
  final Color danger;
  final Color primaryText;
  final Color secondaryText;

  static _DeveloperPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _DeveloperPalette(
        pageBackground: Color(0xFF13161B),
        cardBackground: Color(0xFF1C2028),
        mutedBackground: Color(0xFF252A33),
        previewBackground: Color(0xFF0E1116),
        border: Color(0xFF313744),
        accent: Color(0xFFFFB4A8),
        accentSoft: Color(0x33FFB4A8),
        success: Color(0xFF77D6A3),
        warning: Color(0xFFFFAE4D),
        danger: Color(0xFFFF8A8A),
        primaryText: Color(0xFFF7F3F1),
        secondaryText: Color(0xFFB0B5BF),
      );
    }
    return const _DeveloperPalette(
      pageBackground: Color(0xFFF4F5F9),
      cardBackground: Colors.white,
      mutedBackground: Color(0xFFF7F7FA),
      previewBackground: Color(0xFFF0F2F7),
      border: Color(0xFFE7E8EE),
      accent: Color(0xFFFF9585),
      accentSoft: Color(0x1AFF9585),
      success: Color(0xFF3FA971),
      warning: Color(0xFFFFAE4D),
      danger: Color(0xFFE56464),
      primaryText: Color(0xFF303236),
      secondaryText: Color(0xFF7D828A),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.palette, required this.title});

  final _DeveloperPalette palette;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: palette.secondaryText,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.palette, required this.child});

  final _DeveloperPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
        child: child,
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final _DeveloperPalette palette;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: palette.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: palette.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.secondaryText,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.secondaryText),
          ],
        ),
      ),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({
    required this.palette,
    required this.icon,
    required this.title,
    this.loading = false,
  });

  final _DeveloperPalette palette;
  final IconData icon;
  final String title;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              CircularProgressIndicator(color: palette.accent)
            else
              Icon(icon, color: palette.secondaryText, size: 38),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.secondaryText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.palette,
    required this.icon,
    required this.label,
  });

  final _DeveloperPalette palette;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
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
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: palette.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final _DeveloperPalette palette;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.mutedBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Icon(icon, color: palette.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    required this.actionLabel,
    required this.onAction,
    required this.onSettings,
  });

  final _DeveloperPalette palette;
  final IconData icon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: palette.mutedBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: palette.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.secondaryText,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.verified_outlined),
                label: Text(actionLabel),
              ),
              TextButton.icon(
                onPressed: onSettings,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(_t(context, '系统设置', 'System settings')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

bool _isPermissionUsable(PermissionStatus status) {
  return status.isGranted ||
      status == PermissionStatus.limited ||
      status == PermissionStatus.provisional;
}

String _permissionLabel(BuildContext context, PermissionStatus status) {
  if (status.isGranted) {
    return _t(context, '已授权', 'Granted');
  }
  return switch (status) {
    PermissionStatus.granted => _t(context, '已授权', 'Granted'),
    PermissionStatus.denied => _t(context, '未授权', 'Denied'),
    PermissionStatus.restricted => _t(context, '受限制', 'Restricted'),
    PermissionStatus.limited => _t(context, '部分授权', 'Limited'),
    PermissionStatus.permanentlyDenied => _t(
      context,
      '已永久拒绝',
      'Permanently denied',
    ),
    PermissionStatus.provisional => _t(context, '临时授权', 'Provisional'),
  };
}

String _permissionActionLabel(BuildContext context, PermissionStatus status) {
  if (_isPermissionUsable(status)) {
    return _t(context, '重新申请', 'Request again');
  }
  if (status == PermissionStatus.permanentlyDenied ||
      status == PermissionStatus.restricted) {
    return _t(context, '重新尝试', 'Try request');
  }
  return _t(context, '申请权限', 'Request permission');
}

Color _permissionColor(_DeveloperPalette palette, PermissionStatus status) {
  if (status.isGranted || status == PermissionStatus.limited) {
    return palette.success;
  }
  if (status == PermissionStatus.provisional) {
    return palette.warning;
  }
  return palette.danger;
}

String _permissionCode(Permission permission) {
  final text = permission.toString();
  final index = text.lastIndexOf('.');
  if (index == -1) {
    return text;
  }
  return text.substring(index + 1);
}

String _formatNotificationDiagnostics(
  Map<String, Object?> diagnostics, {
  String? timeZoneIdentifier,
}) {
  final platform = (diagnostics['platform'] as String?)?.toLowerCase();
  final resolvedTimeZone =
      timeZoneIdentifier ?? diagnostics['timeZoneIdentifier'] ?? '-';
  if (platform == 'android') {
    return 'Android: enabled=${diagnostics['notificationsEnabled'] ?? '-'}, exact=${diagnostics['canScheduleExactAlarms'] ?? '-'}, sdk=${diagnostics['sdkInt'] ?? '-'}, mode=${diagnostics['androidScheduleMode'] ?? '-'}, fallback=${diagnostics['fellBackFromExactAlarm'] ?? '-'}, tz=$resolvedTimeZone';
  }
  final pendingRequests =
      (diagnostics['pendingRequests'] as List<dynamic>? ?? const [])
          .cast<Map<dynamic, dynamic>>();
  final nextTriggerDate = pendingRequests.isEmpty
      ? null
      : pendingRequests.first['nextTriggerDate']?.toString();
  return 'iOS: auth=${diagnostics['authorizationStatus'] ?? '-'}, alert=${diagnostics['alertSetting'] ?? '-'}, lock=${diagnostics['lockScreenSetting'] ?? '-'}, center=${diagnostics['notificationCenterSetting'] ?? '-'}, style=${diagnostics['alertStyle'] ?? '-'}, tz=$resolvedTimeZone${nextTriggerDate == null ? '' : '\nnext=$nextTriggerDate'}';
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

String _formatFileSize(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var index = 0;
  while (size >= 1024 && index < units.length - 1) {
    size /= 1024;
    index += 1;
  }
  final text = index == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
  return '$text ${units[index]}';
}

double _normalizedAmplitude(double value) {
  const minDb = -60.0;
  final clamped = value.clamp(minDb, 0.0);
  return (clamped - minDb) / -minDb;
}

Duration _activeMicrophoneDuration(DateTime? startedAt) {
  if (startedAt == null) {
    return Duration.zero;
  }
  return DateTime.now().difference(startedAt);
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes.toString().padLeft(2, '0');
  final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _formatAmplitude(double value) {
  if (value <= -59.5) {
    return '-60 dB';
  }
  return '${value.toStringAsFixed(1)} dB';
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

String _describeCameraException(BuildContext context, CameraException error) {
  switch (error.code) {
    case 'CameraAccessDenied':
      return _t(
        context,
        '相机权限被拒绝，请在系统设置中允许 HelpSupport 访问相机',
        'Camera access was denied. Allow HelpSupport to access the camera in Settings.',
      );
    case 'AudioAccessDenied':
      return _t(
        context,
        '麦克风权限被拒绝，请在系统设置中允许 HelpSupport 访问麦克风',
        'Microphone access was denied. Allow HelpSupport to access the microphone in Settings.',
      );
    case 'CameraAccessRestricted':
    case 'AudioAccessRestricted':
      return _t(
        context,
        '系统限制了音视频权限，请检查设备限制设置',
        'System restrictions are preventing audio and video access.',
      );
    default:
      return error.description?.trim().isNotEmpty == true
          ? error.description!.trim()
          : error.code;
  }
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(
        context,
      ).languageCode.toLowerCase().startsWith('zh')
      ? zh
      : en;
}
