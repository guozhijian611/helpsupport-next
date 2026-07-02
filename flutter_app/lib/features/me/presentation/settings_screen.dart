import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:helpsupport_app/core/cache/cached_remote_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/cache/local_cache_manager.dart';
import '../../../core/config/build_info.dart';
import '../../../core/i18n/app_locale_controller.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/settings/app_display_preferences.dart';
import '../../../core/settings/privacy_preferences.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_protocol.dart';
import '../../plan/application/plan_controller.dart';
import '../../plan/data/plan_models.dart';
import '../data/settings_models.dart';
import '../data/settings_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggingOut = ref.watch(authControllerProvider).isLoading;
    final palette = _SettingsPalette.of(context);

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        title: Text(_t(context, '设置', 'Settings')),
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _SettingsGroup(
              title: _t(context, '账号', 'Account'),
              children: [
                _SettingsNavRow(
                  icon: Icons.person_outline_rounded,
                  title: _t(context, '个人资料设置', 'Profile settings'),
                  subtitle: _t(
                    context,
                    '头像、背景、昵称、签名',
                    'Avatar, cover, name, signature',
                  ),
                  onTap: () =>
                      _openDetail(context, SettingsSectionType.profile),
                ),
                _SettingsNavRow(
                  icon: Icons.verified_user_outlined,
                  title: _t(context, '账号安全', 'Account security'),
                  subtitle: _t(
                    context,
                    '密码、绑定账号、登录设备、单点登录',
                    'Password, linked accounts, devices, single sign-on',
                  ),
                  onTap: () =>
                      _openDetail(context, SettingsSectionType.security),
                ),
              ],
            ),
            _SettingsGroup(
              title: _t(context, '隐私', 'Privacy'),
              children: [
                _SettingsNavRow(
                  icon: Icons.privacy_tip_outlined,
                  title: _t(context, '隐私设置', 'Privacy settings'),
                  subtitle: _t(
                    context,
                    '社区展示、匿名发言、数据同步与导出',
                    'Visibility, anonymous posting, sync, and exports',
                  ),
                  onTap: () =>
                      _openDetail(context, SettingsSectionType.privacy),
                ),
                _SettingsNavRow(
                  icon: Icons.security_outlined,
                  title: _t(context, '权限管理', 'Permissions'),
                  subtitle: _t(
                    context,
                    '通知、相册、相机、麦克风、本地文件',
                    'Notifications, photos, camera, microphone, local files',
                  ),
                  onTap: () =>
                      _openDetail(context, SettingsSectionType.permissions),
                ),
              ],
            ),
            _SettingsGroup(
              title: _t(context, '通用', 'General'),
              children: [
                _SettingsNavRow(
                  icon: Icons.tune_rounded,
                  title: _t(context, '系统设置', 'System settings'),
                  subtitle: _t(
                    context,
                    '语言、暗黑模式、字体大小、缓存',
                    'Language, dark mode, font size, cache',
                  ),
                  onTap: () => _openDetail(context, SettingsSectionType.system),
                ),
                _SettingsNavRow(
                  icon: Icons.notifications_none_rounded,
                  title: _t(context, '通知设置', 'Notification settings'),
                  subtitle: _t(
                    context,
                    '治疗计划、预约、社区互动、日记提醒',
                    'Plans, appointments, community, journal reminders',
                  ),
                  onTap: () =>
                      _openDetail(context, SettingsSectionType.notifications),
                ),
              ],
            ),
            _SettingsGroup(
              title: _t(context, '关于', 'About'),
              children: [
                _SettingsNavRow(
                  icon: Icons.info_outline_rounded,
                  title: _t(context, '关于 APP', 'About app'),
                  value: BuildInfo.shortVersion,
                  onTap: () => _openDetail(context, SettingsSectionType.about),
                ),
                _SettingsNavRow(
                  icon: Icons.description_outlined,
                  title: _t(context, '用户协议', 'Terms of use'),
                  onTap: () => context.push(
                    '/protocol/${AuthProtocolType.terms.routeValue}',
                  ),
                ),
                _SettingsNavRow(
                  icon: Icons.shield_outlined,
                  title: _t(context, '隐私协议', 'Privacy policy'),
                  onTap: () => context.push(
                    '/protocol/${AuthProtocolType.privacy.routeValue}',
                  ),
                ),
                _SettingsNavRow(
                  icon: Icons.support_agent_outlined,
                  title: _t(context, '帮助与反馈', 'Help and feedback'),
                  onTap: () => context.push('/me/help'),
                ),
              ],
            ),
            _SettingsGroup(
              title: _t(context, '账号操作', 'Account actions'),
              children: [
                _SettingsNavRow(
                  icon: Icons.logout_rounded,
                  title: isLoggingOut
                      ? _t(context, '正在退出...', 'Signing out...')
                      : _t(context, '退出登录', 'Sign out'),
                  danger: true,
                  showChevron: false,
                  onTap: isLoggingOut
                      ? null
                      : () => _confirmLogout(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsDetailScreen extends ConsumerStatefulWidget {
  const SettingsDetailScreen({required this.section, super.key});

  final SettingsSectionType section;

  @override
  ConsumerState<SettingsDetailScreen> createState() =>
      _SettingsDetailScreenState();
}

class _SettingsDetailScreenState extends ConsumerState<SettingsDetailScreen> {
  static const _developerTapTarget = 9;
  static const _notificationPrefix = 'settings.notification.';
  static const _autoClearAttachmentsLastRunAtKey =
      'settings.privacy.auto_clear_attachments_last_run_at';
  static const _scheduledTaskNotificationIdsKey =
      '${_notificationPrefix}scheduled_task_notification_ids';
  static const _taskNotificationIdBase = 220000000;
  static const _journalReminderHour = 21;
  static const _journalReminderMinute = 0;
  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _imagePicker = ImagePicker();
  final _localCacheManager = const LocalCacheManager();

  CommunityVisibility _communityVisibility = CommunityVisibility.mutual;
  bool _anonymousPosting = true;
  bool _hideRecoveryStage = false;
  bool _showFollowingList = false;
  bool _showFollowersList = false;
  bool _showSignature = true;
  bool _syncDiarySummary = true;
  bool _autoClearAttachments = false;
  bool _confirmBeforeExport = true;
  bool _planReminders = true;
  bool _appointmentUpdates = true;
  bool _communityReplies = true;
  bool _journalReminders = false;
  bool _privacySaving = false;
  bool _notificationSaving = false;
  bool _permissionRefreshing = false;
  bool _remoteLoading = false;
  bool _avatarUploading = false;
  bool _profileBackgroundUploading = false;
  bool _cacheInspecting = false;
  bool _cacheClearing = false;
  Set<LocalCacheCategory> _selectedCacheCategories = {
    for (final category in LocalCacheCategory.values) category,
  };
  double? _avatarUploadProgress;
  double? _profileBackgroundUploadProgress;
  String? _remoteError;
  int _developerTapCount = 0;
  DateTime? _lastDeveloperTapAt;
  Timer? _developerTapResetTimer;
  MeProfileBundle? _profileBundle;
  SecurityOverview? _securityOverview;
  PushPreferenceSettings? _pushPreference;
  LocalCacheSnapshot? _localCacheSnapshot;
  Permission? _permissionRequesting;
  final Map<Permission, PermissionStatus> _permissionStatuses = {};

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    final privacy = ref.read(privacyPreferencesProvider);
    _communityVisibility = privacy.communityVisibility;
    _anonymousPosting = privacy.anonymousPosting;
    _hideRecoveryStage = privacy.hideRecoveryStage;
    _showFollowingList = privacy.showFollowingList;
    _showFollowersList = privacy.showFollowersList;
    _showSignature = privacy.showSignature;
    _syncDiarySummary = privacy.syncDiarySummary;
    _autoClearAttachments = privacy.autoClearAttachments;
    _confirmBeforeExport = privacy.confirmBeforeExport;
    _planReminders =
        prefs.getBool('${_notificationPrefix}plan_reminders') ?? true;
    _appointmentUpdates =
        prefs.getBool('${_notificationPrefix}appointment_updates') ?? true;
    _communityReplies =
        prefs.getBool('${_notificationPrefix}community_replies') ?? true;
    _journalReminders =
        prefs.getBool('${_notificationPrefix}journal_reminders') ?? false;
    if (_needsRemoteData) {
      unawaited(_loadRemoteSection());
    }
    if (widget.section == SettingsSectionType.privacy) {
      unawaited(_loadPrivacyPreferences());
    }
    if (widget.section == SettingsSectionType.permissions) {
      unawaited(_refreshPermissionStatuses());
    }
    if (widget.section == SettingsSectionType.system) {
      unawaited(_refreshLocalCacheSnapshot());
      if (_autoClearAttachments) {
        unawaited(_runAutoAttachmentCleanup());
      }
    }
  }

  bool get _needsRemoteData =>
      widget.section == SettingsSectionType.profile ||
      widget.section == SettingsSectionType.security ||
      widget.section == SettingsSectionType.notifications;

  @override
  void dispose() {
    _developerTapResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.section == SettingsSectionType.privacy) {
      return _buildPrivacyDetailScaffold(context);
    }
    final palette = _SettingsPalette.of(context);

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        title: Text(widget.section.title(context)),
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: switch (widget.section) {
            SettingsSectionType.profile => _profileSectionContent(context),
            SettingsSectionType.security => _securitySectionContent(context),
            SettingsSectionType.privacy => _privacyChildren(context),
            SettingsSectionType.system => _systemChildren(context),
            SettingsSectionType.notifications => _notificationSectionContent(
              context,
            ),
            SettingsSectionType.about => _aboutChildren(context),
            SettingsSectionType.permissions => _permissionChildren(context),
          },
        ),
      ),
    );
  }

  Widget _buildPrivacyDetailScaffold(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        title: Text(widget.section.title(context)),
        centerTitle: true,
        backgroundColor: palette.cardBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          TextButton(
            onPressed: _privacySaving ? null : _savePrivacySettings,
            child: _privacySaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : Text(
                    _t(context, '保存', 'Save'),
                    style: TextStyle(
                      color: palette.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _CompactPrivacyRow(
              title: _t(context, '社区可见范围', 'Community visibility'),
              value: _compactCommunityVisibilityLabel(context),
              onTap: _selectCompactCommunityVisibility,
            ),
            const SizedBox(height: 16),
            _CompactPrivacyRow(
              title: _t(
                context,
                '日记是否可被模型摘要参与进度面板',
                'Allow journal summaries in progress panel',
              ),
              value: _compactDiarySummaryLabel(context),
              onTap: _selectCompactDiarySummary,
            ),
            const SizedBox(height: 18),
            _SettingsGroup(
              title: _t(context, '更多隐私偏好', 'More privacy options'),
              footer: _t(
                context,
                '日记正文默认只保存在设备端。开启同步时只生成结构化摘要，不上传原文内容。',
                'Journal text stays on device by default. Sync only sends structured summaries, not raw entries.',
              ),
              children: [
                _SettingsSwitchRow(
                  title: _t(context, '匿名发言', 'Anonymous posting'),
                  subtitle: _t(
                    context,
                    '发帖和评论时默认隐藏昵称与头像',
                    'Hide nickname and avatar by default',
                  ),
                  value: _anonymousPosting,
                  onChanged: (value) =>
                      setState(() => _anonymousPosting = value),
                ),
                _SettingsSwitchRow(
                  title: _t(context, '隐藏治疗阶段', 'Hide treatment stage'),
                  subtitle: _t(
                    context,
                    '不在主页和社区卡片里显示当前阶段',
                    'Do not show current stage on public cards',
                  ),
                  value: _hideRecoveryStage,
                  onChanged: (value) =>
                      setState(() => _hideRecoveryStage = value),
                ),
                _SettingsSwitchRow(
                  title: _t(context, '允许查看关注列表', 'Show following list'),
                  subtitle: _t(
                    context,
                    '关闭后他人无法看到你的关注关系',
                    'Hide follow relationships from others',
                  ),
                  value: _showFollowingList,
                  onChanged: (value) =>
                      setState(() => _showFollowingList = value),
                ),
                _SettingsSwitchRow(
                  title: _t(context, '允许查看粉丝列表', 'Show followers list'),
                  subtitle: _t(
                    context,
                    '关闭后他人无法看到你的粉丝关系',
                    'Hide follower relationships from others',
                  ),
                  value: _showFollowersList,
                  onChanged: (value) =>
                      setState(() => _showFollowersList = value),
                ),
                _SettingsSwitchRow(
                  title: _t(context, '展示个性签名', 'Show signature'),
                  subtitle: _t(
                    context,
                    '主页和互动卡片里展示签名内容',
                    'Show signature on profile and cards',
                  ),
                  value: _showSignature,
                  onChanged: (value) => setState(() => _showSignature = value),
                ),
                _SettingsSwitchRow(
                  title: _t(context, '导出前二次确认', 'Confirm before export'),
                  subtitle: _t(
                    context,
                    '导出记录、截图和摘要前先确认一次',
                    'Ask again before exporting records or summaries',
                  ),
                  value: _confirmBeforeExport,
                  onChanged: (value) =>
                      setState(() => _confirmBeforeExport = value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _profileSectionContent(BuildContext context) {
    if (_remoteLoading && _profileBundle == null) {
      return [_stateSection(context, loading: true)];
    }
    if (_remoteError != null && _profileBundle == null) {
      return [_stateSection(context, error: _remoteError)];
    }
    final bundle = _profileBundle;
    if (bundle == null) {
      return [
        _stateSection(
          context,
          error: _t(context, '资料加载失败', 'Failed to load profile'),
        ),
      ];
    }
    return _profileChildren(context, bundle);
  }

  List<Widget> _securitySectionContent(BuildContext context) {
    if (_remoteLoading && _securityOverview == null) {
      return [_stateSection(context, loading: true)];
    }
    if (_remoteError != null && _securityOverview == null) {
      return [_stateSection(context, error: _remoteError)];
    }
    final overview = _securityOverview;
    if (overview == null) {
      return [
        _stateSection(
          context,
          error: _t(context, '账号安全加载失败', 'Failed to load security overview'),
        ),
      ];
    }
    return _securityChildren(context, overview);
  }

  List<Widget> _notificationSectionContent(BuildContext context) {
    if (_remoteLoading && _pushPreference == null) {
      return [_stateSection(context, loading: true)];
    }
    if (_remoteError != null && _pushPreference == null) {
      return [_stateSection(context, error: _remoteError)];
    }

    return _notificationChildren(context);
  }

  Widget _stateSection(
    BuildContext context, {
    bool loading = false,
    String? error,
  }) {
    final palette = _SettingsPalette.of(context);
    final theme = Theme.of(context);
    return _SettingsGroup(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              if (loading) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _t(context, '正在加载...', 'Loading...'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Text(
                    error ?? _t(context, '加载失败', 'Load failed'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _loadRemoteSection(),
                  child: Text(_t(context, '重试', 'Retry')),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _loadRemoteSection() async {
    if (!_needsRemoteData) {
      return;
    }
    setState(() {
      _remoteLoading = true;
      _remoteError = null;
    });
    try {
      if (widget.section == SettingsSectionType.profile) {
        final bundle = await ref
            .read(meSettingsRepositoryProvider)
            .fetchProfile();
        if (!mounted) {
          return;
        }
        setState(() {
          _profileBundle = bundle;
        });
      } else if (widget.section == SettingsSectionType.security) {
        final overview = await ref
            .read(meSettingsRepositoryProvider)
            .fetchSecurityOverview();
        if (!mounted) {
          return;
        }
        setState(() {
          _securityOverview = overview;
        });
      } else if (widget.section == SettingsSectionType.notifications) {
        final preference = await ref
            .read(meSettingsRepositoryProvider)
            .fetchPushPreference();
        if (!mounted) {
          return;
        }
        _applyPushPreference(preference, syncLocalStorage: true);
        unawaited(
          _syncLocalNotificationSchedule(preference).catchError((_) {}),
        );
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _remoteError = _errorText(context, error);
      });
    } finally {
      if (mounted) {
        setState(() => _remoteLoading = false);
      }
    }
  }

  Future<void> _loadPrivacyPreferences() async {
    try {
      final privacy = await ref
          .read(meSettingsRepositoryProvider)
          .fetchPrivacyPreferences();
      await ref.read(privacyPreferencesProvider.notifier).save(privacy);
      if (!mounted) {
        return;
      }
      setState(() {
        _communityVisibility = privacy.communityVisibility;
        _anonymousPosting = privacy.anonymousPosting;
        _hideRecoveryStage = privacy.hideRecoveryStage;
        _showFollowingList = privacy.showFollowingList;
        _showFollowersList = privacy.showFollowersList;
        _showSignature = privacy.showSignature;
        _syncDiarySummary = privacy.syncDiarySummary;
        _autoClearAttachments = privacy.autoClearAttachments;
        _confirmBeforeExport = privacy.confirmBeforeExport;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(_errorText(context, error));
    }
  }

  List<Widget> _profileChildren(BuildContext context, MeProfileBundle bundle) {
    final mobile = bundle.mobile.isEmpty
        ? _t(context, '未绑定', 'Not linked')
        : _maskMobile(bundle.mobile);
    final email = bundle.email.isEmpty
        ? _t(context, '未绑定', 'Not linked')
        : _maskEmail(bundle.email);
    final avatarValue = bundle.avatarUrl.isEmpty
        ? _t(context, '默认头像', 'Default')
        : _t(context, '已设置', 'Set');
    final avatarSubtitle = _avatarUploading
        ? _avatarUploadingText(context, _avatarUploadProgress)
        : avatarValue;
    final backgroundValue = bundle.profileBackground.isEmpty
        ? _t(context, '默认背景', 'Default')
        : _t(context, '已设置', 'Set');
    final backgroundSubtitle = _profileBackgroundUploading
        ? _profileBackgroundUploadingText(
            context,
            _profileBackgroundUploadProgress,
          )
        : backgroundValue;
    final genderValue = _genderLabel(bundle.gender, context);
    final birthdayValue = bundle.birthday.isEmpty
        ? _t(context, '未设置', 'Not set')
        : bundle.birthday;

    return [
      _SettingsGroup(
        children: [
          _SettingsNavRow(
            title: _t(context, '头像', 'Avatar'),
            subtitle: avatarSubtitle,
            trailing: _AvatarPreview(
              url: bundle.avatarUrl,
              isUploading: _avatarUploading,
              progress: _avatarUploadProgress,
            ),
            onTap: _avatarUploading
                ? null
                : () => _previewAvatar(bundle.avatarUrl),
          ),
          _SettingsNavRow(
            title: _t(context, '主页背景', 'Profile background'),
            subtitle: backgroundSubtitle,
            trailing: _ProfileBackgroundPreview(
              url: bundle.profileBackground,
              isUploading: _profileBackgroundUploading,
              progress: _profileBackgroundUploadProgress,
            ),
            onTap: _profileBackgroundUploading
                ? null
                : () => _previewProfileBackground(bundle.profileBackground),
          ),
          _SettingsNavRow(
            title: _t(context, '昵称', 'Nickname'),
            value: bundle.nickname,
            onTap: () => _editNickname(bundle),
          ),
          _SettingsNavRow(
            title: _t(context, '个性签名', 'Signature'),
            value: _summaryOrFallback(
              bundle.bio,
              context,
              emptyZh: '待补充',
              emptyEn: 'To complete',
            ),
            onTap: () => _editBio(bundle),
          ),
          _SettingsNavRow(
            title: _t(context, '性别', 'Gender'),
            value: genderValue,
            onTap: () => _editGender(bundle),
          ),
          _SettingsNavRow(
            title: _t(context, '生日', 'Birthday'),
            value: birthdayValue,
            onTap: () => _editBirthday(bundle),
          ),
          _SettingsNavRow(
            title: _t(context, '手机号', 'Phone number'),
            value: mobile,
            onTap: () => _bindMobile(),
          ),
          _SettingsNavRow(
            title: _t(context, '邮箱', 'Email'),
            value: email,
            onTap: () => _bindEmail(),
          ),
        ],
      ),
      if (!bundle.isDoctor)
        _SettingsGroup(
          title: _t(context, '康复信息', 'Recovery'),
          children: [
            _SettingsNavRow(
              title: _t(context, '康复目标', 'Recovery goal'),
              value: _summaryOrFallback(
                bundle.recoveryGoal,
                context,
                emptyZh: '待医生配置',
                emptyEn: 'Pending doctor setup',
              ),
            ),
            _SettingsNavRow(
              title: _t(context, '重点触发', 'Key triggers'),
              value: bundle.triggerTags.isEmpty
                  ? _t(context, '待医生配置', 'Pending doctor setup')
                  : bundle.triggerTags.join(' / '),
            ),
          ],
        ),
    ];
  }

  List<Widget> _securityChildren(
    BuildContext context,
    SecurityOverview overview,
  ) {
    return [
      _SettingsGroup(
        children: [
          _SettingsNavRow(
            title: _t(context, '邮箱', 'Email'),
            value: overview.member.email.isEmpty
                ? _t(context, '未绑定', 'Not linked')
                : _maskEmail(overview.member.email),
            onTap: () => _bindEmail(),
          ),
          _SettingsNavRow(
            title: overview.member.hasPassword
                ? _t(context, '修改密码', 'Change password')
                : _t(context, '设置密码', 'Set password'),
            onTap: () => _changePassword(),
          ),
          _SettingsNavRow(
            title: _t(context, '手机号', 'Phone number'),
            value: overview.member.mobile.isEmpty
                ? _t(context, '未绑定', 'Not linked')
                : _maskMobile(overview.member.mobile),
            onTap: () => _bindMobile(),
          ),
          _SettingsNavRow(
            title: _t(context, '第三方账号', 'Connected accounts'),
            value: _thirdPartyAccountSummary(overview, context),
            onTap: () => _showLinkedAccounts(overview),
          ),
          _SettingsNavRow(
            title: _t(context, '登录设备', 'Login devices'),
            value:
                '${overview.activeDeviceCount}${_t(context, '台在线', ' online')}',
            onTap: () => _showLoginDevices(overview),
          ),
          _SettingsNavRow(
            title: _t(context, '单点登录状态', 'Single sign-on status'),
            value: overview.ssoEnabled
                ? _t(context, '已启用', 'Enabled')
                : _t(context, '未启用', 'Disabled'),
            onTap: () => _handleLogoutOtherDevices(overview),
          ),
        ],
      ),
    ];
  }

  List<Widget> _privacyChildren(BuildContext context) {
    return [
      _SettingsGroup(
        footer: _t(
          context,
          '日记正文默认只保存在设备端。开启同步时只生成结构化摘要，不上传原文内容。',
          'Journal text stays on device by default. Sync only sends structured summaries, not raw entries.',
        ),
        children: [
          _SettingsNavRow(
            title: _t(context, '社区展示范围', 'Community visibility'),
            value: _communityVisibility.label(context),
            onTap: _selectCommunityVisibility,
          ),
          _SettingsSwitchRow(
            title: _t(context, '匿名发言', 'Anonymous posting'),
            subtitle: _t(
              context,
              '发帖和评论时默认隐藏昵称与头像',
              'Hide nickname and avatar by default',
            ),
            value: _anonymousPosting,
            onChanged: (value) => _setPrivacyBool(
              'anonymous_posting',
              value,
              (next) => _anonymousPosting = next,
            ),
          ),
          _SettingsSwitchRow(
            title: _t(context, '隐藏治疗阶段', 'Hide treatment stage'),
            subtitle: _t(
              context,
              '不在主页和社区卡片里显示当前阶段',
              'Do not show current stage on public cards',
            ),
            value: _hideRecoveryStage,
            onChanged: (value) => _setPrivacyBool(
              'hide_recovery_stage',
              value,
              (next) => _hideRecoveryStage = next,
            ),
          ),
          _SettingsSwitchRow(
            title: _t(context, '允许查看关注列表', 'Show following list'),
            subtitle: _t(
              context,
              '关闭后他人无法看到你的关注关系',
              'Hide follow relationships from others',
            ),
            value: _showFollowingList,
            onChanged: (value) => _setPrivacyBool(
              'show_following_list',
              value,
              (next) => _showFollowingList = next,
            ),
          ),
          _SettingsSwitchRow(
            title: _t(context, '允许查看粉丝列表', 'Show followers list'),
            subtitle: _t(
              context,
              '关闭后他人无法看到你的粉丝关系',
              'Hide follower relationships from others',
            ),
            value: _showFollowersList,
            onChanged: (value) => _setPrivacyBool(
              'show_followers_list',
              value,
              (next) => _showFollowersList = next,
            ),
          ),
          _SettingsSwitchRow(
            title: _t(context, '展示个性签名', 'Show signature'),
            subtitle: _t(
              context,
              '主页和互动卡片里展示签名内容',
              'Show signature on profile and cards',
            ),
            value: _showSignature,
            onChanged: (value) => _setPrivacyBool(
              'show_signature',
              value,
              (next) => _showSignature = next,
            ),
          ),
          _SettingsSwitchRow(
            title: _t(context, '同步日记摘要', 'Sync journal summaries'),
            subtitle: _t(
              context,
              '只同步非原文摘要，用于阶段回顾',
              'Sync non-verbatim summaries for reviews',
            ),
            value: _syncDiarySummary,
            onChanged: (value) => _setPrivacyBool(
              'sync_diary_summary',
              value,
              (next) => _syncDiarySummary = next,
            ),
          ),
          _SettingsSwitchRow(
            title: _t(context, '导出前二次确认', 'Confirm before export'),
            subtitle: _t(
              context,
              '导出记录、截图和摘要前先确认一次',
              'Ask again before exporting records or summaries',
            ),
            value: _confirmBeforeExport,
            onChanged: (value) => _setPrivacyBool(
              'confirm_before_export',
              value,
              (next) => _confirmBeforeExport = next,
            ),
          ),
        ],
      ),
    ];
  }

  String _compactCommunityVisibilityLabel(BuildContext context) {
    return switch (_communityVisibility) {
      CommunityVisibility.private => _t(context, '仅自己可见', 'Private'),
      CommunityVisibility.mutual => _t(context, '互相关注', 'Mutual'),
      CommunityVisibility.public => _t(context, '公开', 'Public'),
    };
  }

  String _compactDiarySummaryLabel(BuildContext context) {
    return _syncDiarySummary
        ? _t(context, '默认允许', 'Allowed')
        : _t(context, '不允许', 'Disabled');
  }

  Future<void> _selectCompactCommunityVisibility() async {
    final selected = await _showChoiceSheet<CommunityVisibility>(
      context: context,
      title: _t(context, '社区可见范围', 'Community visibility'),
      currentValue: _communityVisibility,
      items: [
        _ChoiceSheetItem(
          CommunityVisibility.private,
          _t(context, '仅自己可见', 'Private'),
        ),
        _ChoiceSheetItem(
          CommunityVisibility.mutual,
          _t(context, '互相关注', 'Mutual'),
        ),
        _ChoiceSheetItem(
          CommunityVisibility.public,
          _t(context, '公开', 'Public'),
        ),
      ],
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() => _communityVisibility = selected);
  }

  Future<void> _selectCompactDiarySummary() async {
    final selected = await _showChoiceSheet<bool>(
      context: context,
      title: _t(
        context,
        '日记是否可被模型摘要参与进度面板',
        'Allow journal summaries in progress panel',
      ),
      currentValue: _syncDiarySummary,
      items: [
        _ChoiceSheetItem(true, _t(context, '默认允许', 'Allowed')),
        _ChoiceSheetItem(false, _t(context, '不允许', 'Disabled')),
      ],
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() => _syncDiarySummary = selected);
  }

  List<Widget> _systemChildren(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final currentLanguage =
        locale?.languageCode ?? Localizations.localeOf(context).languageCode;
    final themeMode = ref.watch(appThemeModeProvider);
    final textScale = ref.watch(appTextScaleProvider);

    return [
      _SettingsGroup(
        children: [
          _SettingsNavRow(
            title: _t(context, '语言', 'Language'),
            value: currentLanguage == 'zh' ? '简体中文' : 'English',
            onTap: _selectLanguage,
          ),
          _SettingsNavRow(
            title: _t(context, '暗黑模式', 'Dark mode'),
            value: _themeModeLabel(context, themeMode),
            onTap: _selectThemeMode,
          ),
          _SettingsNavRow(
            title: _t(context, '字体大小', 'Font size'),
            value: _textScaleLabel(context, textScale),
            onTap: _selectTextScale,
          ),
          _SettingsSwitchRow(
            title: _t(context, '自动清理过期缓存', 'Auto-clear expired cache'),
            subtitle: _t(
              context,
              '每天最多一次，清理 7 天前未使用的远程图片、素材和临时媒体缓存',
              'At most daily, clears remote image, material, and temporary media cache unused for 7 days',
            ),
            value: _autoClearAttachments,
            onChanged: _setAutoClearAttachments,
          ),
          _SettingsNavRow(
            title: _t(context, '本地数据与缓存', 'Local data and cache'),
            subtitle: _t(
              context,
              '仅清理可重新生成或重新下载的缓存',
              'Only clears cache that can be regenerated or downloaded again',
            ),
            value: _localCacheValueLabel(context),
            onTap: _showLocalCacheSheet,
          ),
        ],
      ),
    ];
  }

  String _localCacheValueLabel(BuildContext context) {
    if (_cacheInspecting) {
      return _t(context, '计算中', 'Checking');
    }
    if (_cacheClearing) {
      return _t(context, '清理中', 'Clearing');
    }
    final snapshot = _localCacheSnapshot;
    if (snapshot == null) {
      return _t(context, '查看', 'View');
    }
    if (snapshot.isEmpty) {
      return _t(context, '无缓存', 'No cache');
    }
    return _formatCacheSize(snapshot.totalBytes);
  }

  List<Widget> _notificationChildren(BuildContext context) {
    return [
      _SettingsGroup(
        footer: _t(
          context,
          '治疗任务和日记提醒走本地通知；社区、预约和系统公告走服务端推送。',
          'Treatment and journal reminders use local notifications; community, appointment, and system alerts use push.',
        ),
        children: [
          _SettingsNavRow(
            title: _t(context, '通知权限', 'Notification permission'),
            value: _t(context, '开启', 'Enable'),
            onTap: _requestNotifications,
          ),
          _SettingsSwitchRow(
            title: _t(context, '治疗计划提醒', 'Treatment plan reminders'),
            subtitle: _t(
              context,
              '任务开始前提醒和未完成补提醒',
              'Remind before tasks and follow up if incomplete',
            ),
            value: _planReminders,
            onChanged: (value) => _setNotificationBool(
              'plan_reminders',
              value,
              (next) => _planReminders = next,
            ),
          ),
          _SettingsSwitchRow(
            title: _t(context, '预约状态通知', 'Appointment updates'),
            subtitle: _t(
              context,
              '医生确认、改期、取消和开始前提醒',
              'Confirmations, reschedules, cancellations, and reminders',
            ),
            value: _appointmentUpdates,
            onChanged: (value) => _setNotificationBool(
              'appointment_updates',
              value,
              (next) => _appointmentUpdates = next,
            ),
          ),
          _SettingsSwitchRow(
            title: _t(context, '社区互动通知', 'Community interaction alerts'),
            subtitle: _t(
              context,
              '评论回复、关注、收藏和审核结果',
              'Replies, follows, saves, and review results',
            ),
            value: _communityReplies,
            onChanged: (value) => _setNotificationBool(
              'community_replies',
              value,
              (next) => _communityReplies = next,
            ),
          ),
          _SettingsSwitchRow(
            title: _t(context, '日记提醒', 'Journal reminders'),
            subtitle: _t(
              context,
              '每天固定时间提醒记录当天状态',
              'Daily reminder to record current status',
            ),
            value: _journalReminders,
            onChanged: (value) => _setNotificationBool(
              'journal_reminders',
              value,
              (next) => _journalReminders = next,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _permissionChildren(BuildContext context) {
    return [
      _SettingsGroup(
        footer: _t(
          context,
          '点击相册、相机、麦克风会调用系统授权；本地文件访问由系统文件选择器按次授权。',
          'Tap Photos, Camera, or Microphone to request system permission. Local file access is granted per action through the system file picker.',
        ),
        children: [
          _SettingsNavRow(
            title: _t(context, '通知', 'Notifications'),
            value: _permissionValueLabel(
              context,
              _permissionStatuses[Permission.notification],
            ),
            onTap: () => _requestRuntimePermission(Permission.notification),
          ),
          _SettingsNavRow(
            title: _t(context, '相册', 'Photos'),
            value: _permissionValueLabel(
              context,
              _permissionStatuses[Permission.photos],
            ),
            onTap: () => _requestRuntimePermission(Permission.photos),
          ),
          _SettingsNavRow(
            title: _t(context, '相机', 'Camera'),
            value: _permissionValueLabel(
              context,
              _permissionStatuses[Permission.camera],
            ),
            onTap: () => _requestRuntimePermission(Permission.camera),
          ),
          _SettingsNavRow(
            title: _t(context, '麦克风', 'Microphone'),
            value: _permissionValueLabel(
              context,
              _permissionStatuses[Permission.microphone],
            ),
            onTap: () => _requestRuntimePermission(Permission.microphone),
          ),
          _SettingsNavRow(
            title: _t(context, '本地文件访问', 'Local files'),
            value: _t(context, '系统选择器', 'System picker'),
            onTap: _explainLocalFileAccess,
          ),
        ],
      ),
    ];
  }

  List<Widget> _aboutChildren(BuildContext context) {
    return [
      _SettingsGroup(
        children: [
          _SettingsNavRow(
            title: _t(context, '应用名称', 'App name'),
            value: BuildInfo.appName,
            showChevron: false,
          ),
          _SettingsNavRow(
            title: _t(context, '版本号', 'Version'),
            value: BuildInfo.shortVersion,
            showChevron: false,
            onTap: () => _openDeveloperTools(context),
          ),
          _SettingsNavRow(
            title: _t(context, '用户协议', 'Terms of use'),
            onTap: () =>
                context.push('/protocol/${AuthProtocolType.terms.routeValue}'),
          ),
          _SettingsNavRow(
            title: _t(context, '隐私协议', 'Privacy policy'),
            onTap: () => context.push(
              '/protocol/${AuthProtocolType.privacy.routeValue}',
            ),
          ),
          _SettingsNavRow(
            title: _t(context, '开源许可', 'Open source licenses'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: BuildInfo.appName,
              applicationVersion: BuildInfo.appVersion,
            ),
          ),
        ],
      ),
    ];
  }

  void _openDeveloperTools(BuildContext context) {
    final now = DateTime.now();
    if (_lastDeveloperTapAt == null ||
        now.difference(_lastDeveloperTapAt!) > const Duration(seconds: 2)) {
      _developerTapCount = 0;
    }
    _lastDeveloperTapAt = now;
    _developerTapCount += 1;
    final remaining = _developerTapTarget - _developerTapCount;
    _developerTapResetTimer?.cancel();
    _developerTapResetTimer = Timer(const Duration(seconds: 2), () {
      _developerTapCount = 0;
      _lastDeveloperTapAt = null;
    });

    if (remaining <= 0) {
      _developerTapCount = 0;
      _lastDeveloperTapAt = null;
      _developerTapResetTimer?.cancel();
      context.showCenteredNotice(
        _t(context, '已进入开发者界面', 'Developer tools unlocked'),
      );
      context.push('/me/settings/about/developer');
      return;
    }

    if (remaining <= 4) {
      context.showCenteredNotice(
        _t(
          context,
          '再点击 $remaining 次进入开发者界面',
          'Tap $remaining more times to open developer tools',
        ),
      );
    }
  }

  Future<void> _savePrivacySettings() async {
    if (_privacySaving) {
      return;
    }
    setState(() => _privacySaving = true);
    try {
      final saved = await ref
          .read(meSettingsRepositoryProvider)
          .savePrivacyPreferences(_currentPrivacyPreferences());
      await ref.read(privacyPreferencesProvider.notifier).save(saved);
      if (!mounted) {
        return;
      }
      setState(() {
        _communityVisibility = saved.communityVisibility;
        _anonymousPosting = saved.anonymousPosting;
        _hideRecoveryStage = saved.hideRecoveryStage;
        _showFollowingList = saved.showFollowingList;
        _showFollowersList = saved.showFollowersList;
        _showSignature = saved.showSignature;
        _syncDiarySummary = saved.syncDiarySummary;
        _autoClearAttachments = saved.autoClearAttachments;
        _confirmBeforeExport = saved.confirmBeforeExport;
      });
      context.showCenteredNotice(
        _t(context, '隐私设置已保存', 'Privacy settings saved'),
      );
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    } finally {
      if (mounted) {
        setState(() => _privacySaving = false);
      }
    }
  }

  PrivacyPreferences _currentPrivacyPreferences() {
    return PrivacyPreferences(
      communityVisibility: _communityVisibility,
      anonymousPosting: _anonymousPosting,
      hideRecoveryStage: _hideRecoveryStage,
      showFollowingList: _showFollowingList,
      showFollowersList: _showFollowersList,
      showSignature: _showSignature,
      syncDiarySummary: _syncDiarySummary,
      autoClearAttachments: _autoClearAttachments,
      confirmBeforeExport: _confirmBeforeExport,
    );
  }

  Future<void> _selectCommunityVisibility() async {
    final selected = await _showChoiceSheet<CommunityVisibility>(
      context: context,
      title: _t(context, '社区展示范围', 'Community visibility'),
      currentValue: _communityVisibility,
      items: [
        _ChoiceSheetItem(
          CommunityVisibility.private,
          _t(context, '仅自己可见', 'Private'),
        ),
        _ChoiceSheetItem(
          CommunityVisibility.mutual,
          _t(context, '互相关注', 'Mutual'),
        ),
        _ChoiceSheetItem(
          CommunityVisibility.public,
          _t(context, '公开', 'Public'),
        ),
      ],
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() => _communityVisibility = selected);
    unawaited(
      ref
          .read(privacyPreferencesProvider.notifier)
          .setCommunityVisibility(selected),
    );
  }

  Future<void> _selectLanguage() async {
    final locale = ref.read(appLocaleProvider);
    final currentLanguage =
        locale?.languageCode ?? Localizations.localeOf(context).languageCode;
    final selected = await _showChoiceSheet<String>(
      context: context,
      title: _t(context, '语言', 'Language'),
      currentValue: currentLanguage == 'zh' ? 'zh' : 'en',
      items: const [
        _ChoiceSheetItem('zh', '简体中文'),
        _ChoiceSheetItem('en', 'English'),
      ],
    );
    if (selected == null || !mounted) {
      return;
    }
    unawaited(ref.read(appLocaleProvider.notifier).setLocale(Locale(selected)));
  }

  Future<void> _selectThemeMode() async {
    final selected = await _showChoiceSheet<ThemeMode>(
      context: context,
      title: _t(context, '暗黑模式', 'Dark mode'),
      currentValue: ref.read(appThemeModeProvider),
      items: [
        _ChoiceSheetItem(
          ThemeMode.system,
          _t(context, '跟随系统', 'Follow system'),
        ),
        _ChoiceSheetItem(ThemeMode.light, _t(context, '浅色', 'Light')),
        _ChoiceSheetItem(ThemeMode.dark, _t(context, '深色', 'Dark')),
      ],
    );
    if (selected == null || !mounted) {
      return;
    }
    unawaited(ref.read(appThemeModeProvider.notifier).setMode(selected));
  }

  Future<void> _selectTextScale() async {
    final selected = await _showChoiceSheet<double>(
      context: context,
      title: _t(context, '字体大小', 'Font size'),
      currentValue: ref.read(appTextScaleProvider),
      items: [
        _ChoiceSheetItem(
          AppTextScaleController.small,
          _t(context, '小', 'Small'),
        ),
        _ChoiceSheetItem(
          AppTextScaleController.standard,
          _t(context, '标准', 'Default'),
        ),
        _ChoiceSheetItem(
          AppTextScaleController.large,
          _t(context, '大', 'Large'),
        ),
      ],
    );
    if (selected == null || !mounted) {
      return;
    }
    unawaited(ref.read(appTextScaleProvider.notifier).setScale(selected));
  }

  void _setPrivacyBool(
    String key,
    bool value,
    void Function(bool value) update,
  ) {
    setState(() => update(value));
    unawaited(switch (key) {
      'anonymous_posting' =>
        ref
            .read(privacyPreferencesProvider.notifier)
            .setAnonymousPosting(value),
      'hide_recovery_stage' =>
        ref
            .read(privacyPreferencesProvider.notifier)
            .setHideRecoveryStage(value),
      'show_following_list' =>
        ref
            .read(privacyPreferencesProvider.notifier)
            .setShowFollowingList(value),
      'show_followers_list' =>
        ref
            .read(privacyPreferencesProvider.notifier)
            .setShowFollowersList(value),
      'show_signature' =>
        ref.read(privacyPreferencesProvider.notifier).setShowSignature(value),
      'sync_diary_summary' =>
        ref
            .read(privacyPreferencesProvider.notifier)
            .setSyncDiarySummary(value),
      'confirm_before_export' =>
        ref
            .read(privacyPreferencesProvider.notifier)
            .setConfirmBeforeExport(value),
      _ => Future<void>.value(),
    });
  }

  void _setAutoClearAttachments(bool value) {
    setState(() => _autoClearAttachments = value);
    unawaited(
      () async {
        await ref
            .read(privacyPreferencesProvider.notifier)
            .setAutoClearAttachments(value);
        final saved = await ref
            .read(meSettingsRepositoryProvider)
            .savePrivacyPreferences(ref.read(privacyPreferencesProvider));
        await ref.read(privacyPreferencesProvider.notifier).save(saved);
        if (value) {
          await _runAutoAttachmentCleanup(force: true, showNotice: true);
        }
      }().catchError((error) {
        if (mounted) {
          context.showCenteredNotice(_errorText(context, error));
        }
      }),
    );
  }

  Future<void> _refreshLocalCacheSnapshot() async {
    if (_cacheInspecting) {
      return;
    }
    setState(() => _cacheInspecting = true);
    try {
      final snapshot = await _localCacheManager.inspect();
      if (!mounted) {
        return;
      }
      setState(() => _localCacheSnapshot = snapshot);
    } on Object {
      if (mounted) {
        context.showCenteredNotice(
          _t(context, '本地缓存检查失败', 'Local cache check failed'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cacheInspecting = false);
      }
    }
  }

  Future<void> _runAutoAttachmentCleanup({
    bool force = false,
    bool showNotice = false,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final lastRunAt = DateTime.tryParse(
      prefs.getString(_autoClearAttachmentsLastRunAtKey) ?? '',
    );
    if (!force &&
        lastRunAt != null &&
        DateTime.now().difference(lastRunAt) <
            LocalCacheManager.autoClearInterval) {
      return;
    }

    try {
      final result = await _localCacheManager.clear(
        olderThan: LocalCacheManager.autoClearAge,
        categories: LocalCacheCategory.values.toSet(),
      );
      await prefs.setString(
        _autoClearAttachmentsLastRunAtKey,
        DateTime.now().toIso8601String(),
      );
      if (!mounted) {
        return;
      }
      setState(() => _localCacheSnapshot = result.remaining);
      if (showNotice) {
        context.showCenteredNotice(
          result.deletedFileCount == 0
              ? _t(context, '已开启，暂无过期缓存', 'Enabled. No expired cache found')
              : _t(context, '已清理过期缓存 ', 'Expired cache cleared ') +
                    _formatCacheSize(result.deletedBytes),
        );
      }
    } on Object {
      if (showNotice && mounted) {
        context.showCenteredNotice(
          _t(context, '自动清理执行失败', 'Auto-clear failed'),
        );
      }
    }
  }

  Future<void> _showLocalCacheSheet() async {
    await _refreshLocalCacheSnapshot();
    if (!mounted) {
      return;
    }
    final snapshot = _localCacheSnapshot ?? LocalCacheSnapshot.empty();
    var selected = {
      for (final category in _selectedCacheCategories)
        if (!snapshot.category(category).isEmpty) category,
    };
    if (selected.isEmpty) {
      selected = {
        for (final category in LocalCacheCategory.values)
          if (!snapshot.category(category).isEmpty) category,
      };
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final selectedBytes = selected.fold<int>(
              0,
              (total, category) =>
                  total + snapshot.category(category).totalBytes,
            );
            final selectedFiles = selected.fold<int>(
              0,
              (total, category) =>
                  total + snapshot.category(category).fileCount,
            );
            return AlertDialog(
              title: Text(_t(dialogContext, '本地数据与缓存', 'Local data and cache')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(dialogContext, '可清理缓存：', 'Cleanable cache: ') +
                          _formatCacheSize(snapshot.totalBytes),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _t(dialogContext, '缓存文件：', 'Cache files: ') +
                          _formatCacheFileCount(
                            dialogContext,
                            snapshot.fileCount,
                          ),
                    ),
                    const SizedBox(height: 16),
                    for (final category in LocalCacheCategory.values) ...[
                      _CacheCategoryCheckbox(
                        title: _cacheCategoryTitle(dialogContext, category),
                        subtitle: _cacheCategoryDescription(
                          dialogContext,
                          category,
                        ),
                        value: selected.contains(category),
                        enabled: !snapshot.category(category).isEmpty,
                        fileCount: snapshot.category(category).fileCount,
                        sizeLabel: _formatCacheSize(
                          snapshot.category(category).totalBytes,
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              selected.add(category);
                            } else {
                              selected.remove(category);
                            }
                          });
                        },
                      ),
                      if (category != LocalCacheCategory.values.last)
                        const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      _t(dialogContext, '本次将清理：', 'Selected to clear: ') +
                          _formatCacheSize(selectedBytes),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _t(
                        dialogContext,
                        '自动清理：开启后每天最多执行一次，清理 7 天前未修改的上述缓存。',
                        'Auto-clear: when enabled, runs at most once per day and clears the cache above if it has not changed for 7 days.',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _t(
                        dialogContext,
                        '不会删除登录态、账号资料、偏好设置或已提交的服务端数据。',
                        'Sign-in state, profile, preferences, and submitted server data are not deleted.',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(_t(dialogContext, '取消', 'Cancel')),
                ),
                FilledButton(
                  onPressed: selectedFiles == 0 || _cacheClearing
                      ? null
                      : () => Navigator.of(dialogContext).pop(true),
                  child: Text(_t(dialogContext, '清理所选', 'Clear selected')),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed == true && mounted) {
      setState(() => _selectedCacheCategories = selected);
      await _clearLocalCache(categories: selected);
    }
  }

  Future<void> _clearLocalCache({
    required Set<LocalCacheCategory> categories,
  }) async {
    if (_cacheClearing) {
      return;
    }
    setState(() => _cacheClearing = true);
    try {
      final result = await _localCacheManager.clear(categories: categories);
      if (!mounted) {
        return;
      }
      setState(() => _localCacheSnapshot = result.remaining);
      context.showCenteredNotice(
        result.deletedFileCount == 0
            ? _t(context, '暂无可清理缓存', 'No cleanable cache')
            : _t(context, '已清理缓存 ', 'Cache cleared ') +
                  _formatCacheSize(result.deletedBytes),
      );
    } on Object {
      if (mounted) {
        context.showCenteredNotice(
          _t(context, '缓存清理失败', 'Cache cleanup failed'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cacheClearing = false);
      }
    }
  }

  void _setNotificationBool(
    String key,
    bool value,
    void Function(bool value) update,
  ) {
    if (_notificationSaving) {
      return;
    }

    final previousValue = switch (key) {
      'plan_reminders' => _planReminders,
      'appointment_updates' => _appointmentUpdates,
      'community_replies' => _communityReplies,
      'journal_reminders' => _journalReminders,
      _ => value,
    };
    setState(() => update(value));
    unawaited(_saveNotificationPreference(key, value, previousValue, update));
  }

  Future<void> _saveNotificationPreference(
    String key,
    bool value,
    bool previousValue,
    void Function(bool value) update,
  ) async {
    setState(() => _notificationSaving = true);
    try {
      final preference = await ref
          .read(meSettingsRepositoryProvider)
          .savePushPreference(_notificationPayloadFor(key, value));
      if (!mounted) {
        return;
      }
      _applyPushPreference(preference, syncLocalStorage: true);
      var localScheduleSynced = true;
      try {
        await _syncLocalNotificationSchedule(preference);
      } on Object {
        localScheduleSynced = false;
      }
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(
        localScheduleSynced
            ? _t(context, '通知设置已同步', 'Notification settings synced')
            : _t(
                context,
                '通知设置已保存，本地提醒同步失败',
                'Notification settings saved. Local reminder sync failed.',
              ),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => update(previousValue));
      context.showCenteredNotice(_errorText(context, error));
    } finally {
      if (mounted) {
        setState(() => _notificationSaving = false);
      }
    }
  }

  Map<String, dynamic> _notificationPayloadFor(String key, bool value) {
    final currentTask = key == 'plan_reminders' ? value : _planReminders;
    final currentAppointment = key == 'appointment_updates'
        ? value
        : _appointmentUpdates;
    final currentCommunity = key == 'community_replies'
        ? value
        : _communityReplies;
    final currentJournal = key == 'journal_reminders'
        ? value
        : _journalReminders;
    final overallEnabled =
        currentTask || currentAppointment || currentCommunity || currentJournal;

    return {
      'is_push_enabled': overallEnabled ? 1 : 2,
      switch (key) {
        'plan_reminders' => 'is_task_reminder_enabled',
        'appointment_updates' => 'is_appointment_enabled',
        'community_replies' => 'is_community_enabled',
        'journal_reminders' => 'is_local_companion_enabled',
        _ => 'is_push_enabled',
      }: value
          ? 1
          : 2,
    };
  }

  void _applyPushPreference(
    PushPreferenceSettings preference, {
    bool syncLocalStorage = false,
  }) {
    setState(() {
      _pushPreference = preference;
      _planReminders = preference.isTaskReminderEnabled;
      _appointmentUpdates = preference.isAppointmentEnabled;
      _communityReplies = preference.isCommunityEnabled;
      _journalReminders = preference.isLocalCompanionEnabled;
    });

    if (!syncLocalStorage) {
      return;
    }
    unawaited(_storeNotificationPrefs(preference));
  }

  Future<void> _storeNotificationPrefs(
    PushPreferenceSettings preference,
  ) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await Future.wait([
      prefs.setBool(
        '${_notificationPrefix}plan_reminders',
        preference.isTaskReminderEnabled,
      ),
      prefs.setBool(
        '${_notificationPrefix}appointment_updates',
        preference.isAppointmentEnabled,
      ),
      prefs.setBool(
        '${_notificationPrefix}community_replies',
        preference.isCommunityEnabled,
      ),
      prefs.setBool(
        '${_notificationPrefix}journal_reminders',
        preference.isLocalCompanionEnabled,
      ),
    ]);
  }

  Future<void> _syncLocalNotificationSchedule(
    PushPreferenceSettings preference,
  ) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final service = ref.read(localNotificationServiceProvider);
    final storedTaskIds =
        prefs
            .getStringList(_scheduledTaskNotificationIdsKey)
            ?.map((value) => int.tryParse(value))
            .whereType<int>()
            .toList(growable: false) ??
        const <int>[];

    if (!preference.isTaskReminderEnabled) {
      await service.cancelNotifications(storedTaskIds);
      await prefs.remove(_scheduledTaskNotificationIdsKey);
    } else {
      await service.requestPermissions();
      await service.cancelNotifications(storedTaskIds);
      final tasks = await ref
          .read(planRepositoryProvider)
          .fetchTasks(date: _dateFormat.format(DateTime.now()));
      final scheduledIds = <int>[];
      for (final task in tasks.list) {
        if (task.isDone || task.isSkipped) {
          continue;
        }
        final scheduledAt = _taskReminderTime(task);
        if (scheduledAt == null || !scheduledAt.isAfter(DateTime.now())) {
          continue;
        }
        final id = _taskNotificationId(task.id);
        final scheduled = await service.scheduleTreatmentTaskReminder(
          id: id,
          title: _t(context, '治疗任务提醒', 'Treatment task reminder'),
          body: task.title.isEmpty
              ? _t(context, '有一项治疗任务即将开始', 'A treatment task is starting soon')
              : task.title,
          scheduledDate: scheduledAt,
          payload: 'task-reminder:${task.id}',
        );
        if (scheduled) {
          scheduledIds.add(id);
        }
      }
      await prefs.setStringList(
        _scheduledTaskNotificationIdsKey,
        scheduledIds.map((id) => id.toString()).toList(growable: false),
      );
    }

    if (!preference.isLocalCompanionEnabled) {
      await service.cancelDailyJournalReminder();
      return;
    }

    await service.requestPermissions();
    await service.scheduleDailyJournalReminder(
      hour: _journalReminderHour,
      minute: _journalReminderMinute,
      title: _t(context, '日记提醒', 'Journal reminder'),
      body: _t(context, '记录一下今天的状态和感受', "Record today's status and mood."),
    );
  }

  DateTime? _taskReminderTime(DailyTask task) {
    final taskDate = DateTime.tryParse(task.taskDate);
    if (taskDate == null) {
      return null;
    }

    final reminderTime = _firstClockText(task.reminders);
    final clock = reminderTime ?? _clockText(task.startTime);
    if (clock == null) {
      return null;
    }

    final hour = int.tryParse(clock.group(1)!);
    final minute = int.tryParse(clock.group(2)!);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }

    return DateTime(taskDate.year, taskDate.month, taskDate.day, hour, minute);
  }

  RegExpMatch? _firstClockText(List<String> values) {
    for (final value in values) {
      final match = _clockText(value);
      if (match != null) {
        return match;
      }
    }
    return null;
  }

  RegExpMatch? _clockText(String value) {
    return RegExp(r'(\d{1,2}):(\d{2})').firstMatch(value.trim());
  }

  int _taskNotificationId(int taskId) {
    return _taskNotificationIdBase + taskId.remainder(100000);
  }

  Future<void> _requestNotifications() async {
    final localGranted = await ref
        .read(localNotificationServiceProvider)
        .requestPermissions();
    final permission = await ref
        .read(permissionServiceProvider)
        .requestNotifications();
    if (!mounted) {
      return;
    }
    final granted =
        localGranted == true ||
        permission == PermissionStatus.granted ||
        permission == PermissionStatus.provisional ||
        permission == PermissionStatus.limited;
    context.showCenteredNotice(
      granted
          ? _t(context, '通知权限已开启', 'Notification permission is enabled')
          : _t(
              context,
              '通知权限未开启，可在系统设置中打开',
              'Notification permission is not enabled. You can enable it in system settings.',
            ),
    );
    if (widget.section == SettingsSectionType.permissions) {
      setState(() {
        _permissionStatuses[Permission.notification] = granted
            ? PermissionStatus.granted
            : permission;
      });
    }
  }

  Future<void> _refreshPermissionStatuses() async {
    if (_permissionRefreshing) {
      return;
    }
    setState(() => _permissionRefreshing = true);
    try {
      final statuses = await Future.wait([
        _readPermissionStatus(Permission.notification),
        _readPermissionStatus(Permission.photos),
        _readPermissionStatus(Permission.camera),
        _readPermissionStatus(Permission.microphone),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _permissionStatuses
          ..[Permission.notification] = statuses[0]
          ..[Permission.photos] = statuses[1]
          ..[Permission.camera] = statuses[2]
          ..[Permission.microphone] = statuses[3];
      });
    } finally {
      if (mounted) {
        setState(() => _permissionRefreshing = false);
      }
    }
  }

  Future<void> _requestRuntimePermission(Permission permission) async {
    if (_permissionRequesting != null) {
      return;
    }
    setState(() => _permissionRequesting = permission);
    try {
      final current = await _readPermissionStatus(permission);
      PermissionStatus next = current;
      if (_shouldOpenSettingsForPermission(current)) {
        final opened = await openAppSettings();
        if (!mounted) {
          return;
        }
        context.showCenteredNotice(
          opened
              ? _t(
                  context,
                  '已打开系统设置，请在那里调整权限',
                  'System settings opened. Adjust the permission there.',
                )
              : _t(
                  context,
                  '无法打开系统设置，请手动前往系统设置调整权限',
                  'Unable to open settings. Please adjust the permission in system settings.',
                ),
        );
      } else {
        next = await _requestPermission(permission);
      }
      final fresh = _shouldOpenSettingsForPermission(current)
          ? await _readPermissionStatus(permission)
          : next;
      if (!mounted) {
        return;
      }
      setState(() => _permissionStatuses[permission] = fresh);
      if (!_shouldOpenSettingsForPermission(current)) {
        context.showCenteredNotice(_permissionResultMessage(context, fresh));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(_errorText(context, error));
    } finally {
      if (mounted) {
        setState(() => _permissionRequesting = null);
      }
    }
  }

  Future<PermissionStatus> _readPermissionStatus(Permission permission) {
    final service = ref.read(permissionServiceProvider);
    if (permission == Permission.notification) {
      return service.notificationStatus();
    }
    if (permission == Permission.photos) {
      return service.mediaLibraryStatus();
    }
    if (permission == Permission.camera) {
      return service.cameraStatus();
    }
    if (permission == Permission.microphone) {
      return service.microphoneStatus();
    }
    return permission.status;
  }

  Future<PermissionStatus> _requestPermission(Permission permission) async {
    final service = ref.read(permissionServiceProvider);
    if (permission == Permission.notification) {
      final localGranted = await ref
          .read(localNotificationServiceProvider)
          .requestPermissions();
      final status = await service.requestNotifications();
      if (localGranted == true && !_isRuntimePermissionUsable(status)) {
        return PermissionStatus.granted;
      }
      return status;
    }
    if (permission == Permission.photos) {
      return service.requestMediaLibrary();
    }
    if (permission == Permission.camera) {
      return service.requestCamera();
    }
    if (permission == Permission.microphone) {
      return service.requestMicrophone();
    }
    return permission.request();
  }

  void _explainLocalFileAccess() {
    context.showCenteredNotice(
      _t(
        context,
        '本地文件访问通过系统文件选择器按次授权，无需单独开启权限。',
        'Local file access is granted per action through the system file picker. No separate permission is required.',
      ),
    );
  }

  Future<void> _previewAvatar(String avatarUrl) async {
    if (_avatarUploading) {
      return;
    }
    final previewUrl = avatarUrl.isEmpty
        ? ''
        : ref.read(apiClientProvider).resolveUrl(avatarUrl);
    final dialogTitle = _t(context, '头像预览', 'Avatar preview');
    final changeAvatarLabel = _t(context, '更换头像', 'Change avatar');
    final shouldReplace = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        final palette = _SettingsPalette.of(dialogContext);
        final theme = Theme.of(dialogContext);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dialogTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: palette.primaryText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _AvatarPreviewSurface(url: previewUrl),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(changeAvatarLabel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) {
      return;
    }
    if (shouldReplace == true) {
      await _pickAvatar();
    }
  }

  Future<void> _pickAvatar() async {
    if (_avatarUploading) {
      return;
    }
    final permission = await ref
        .read(permissionServiceProvider)
        .requestMediaLibrary();
    final granted =
        permission == PermissionStatus.granted ||
        permission == PermissionStatus.limited;
    if (!granted) {
      if (mounted) {
        context.showCenteredNotice(
          _t(
            context,
            '需要开启相册权限后才能更换头像',
            'Photo permission is required to change your avatar',
          ),
        );
      }
      return;
    }

    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1440,
    );
    if (file == null) {
      return;
    }

    final progressNotifier = ValueNotifier<double?>(0);
    BuildContext? uploadDialogContext;
    Future<void>? uploadDialogFuture;
    if (mounted) {
      setState(() {
        _avatarUploading = true;
        _avatarUploadProgress = 0;
      });
      uploadDialogFuture = showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (dialogContext) {
          uploadDialogContext = dialogContext;
          return _ImageUploadProgressDialog(
            title: _t(context, '正在上传头像', 'Uploading avatar'),
            progress: progressNotifier,
          );
        },
      );
      unawaited(uploadDialogFuture);
      await WidgetsBinding.instance.endOfFrame;
    }

    try {
      final bundle = await ref
          .read(meSettingsRepositoryProvider)
          .uploadAvatar(
            file: file,
            onSendProgress: (sent, total) {
              if (total <= 0) {
                return;
              }
              final progress = (sent / total).clamp(0, 1).toDouble();
              progressNotifier.value = progress;
              if (mounted) {
                setState(() => _avatarUploadProgress = progress);
              }
            },
          );
      progressNotifier.value = 1;
      await ref.read(authControllerProvider.notifier).refreshCurrentSession();
      if (!mounted) {
        return;
      }
      setState(() {
        _profileBundle = bundle;
        _avatarUploadProgress = 1;
      });
      context.showCenteredNotice(_t(context, '头像已更新', 'Avatar updated'));
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    } finally {
      if (uploadDialogContext != null) {
        Navigator.of(uploadDialogContext!).pop();
      }
      if (uploadDialogFuture != null && uploadDialogContext != null) {
        await uploadDialogFuture;
      }
      progressNotifier.dispose();
      if (mounted) {
        setState(() {
          _avatarUploading = false;
          _avatarUploadProgress = null;
        });
      }
    }
  }

  Future<void> _previewProfileBackground(String backgroundUrl) async {
    if (_profileBackgroundUploading) {
      return;
    }
    final previewUrl = backgroundUrl.isEmpty
        ? ''
        : ref.read(apiClientProvider).resolveUrl(backgroundUrl);
    final action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        final palette = _SettingsPalette.of(dialogContext);
        final theme = Theme.of(dialogContext);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _t(context, '主页背景', 'Profile background'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: palette.primaryText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ProfileBackgroundPreviewSurface(url: previewUrl),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(dialogContext).pop('change'),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(_t(context, '更换背景', 'Change background')),
                  ),
                ),
                if (backgroundUrl.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(dialogContext).pop('clear'),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(
                        _t(context, '恢复默认背景', 'Restore default background'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) {
      return;
    }
    if (action == 'change') {
      await _pickProfileBackground();
    } else if (action == 'clear') {
      await _saveProfilePayload({
        'profile_background': '',
      }, successMessage: _t(context, '主页背景已恢复默认', 'Background restored'));
    }
  }

  Future<void> _pickProfileBackground() async {
    if (_profileBackgroundUploading) {
      return;
    }
    final permission = await ref
        .read(permissionServiceProvider)
        .requestMediaLibrary();
    final granted =
        permission == PermissionStatus.granted ||
        permission == PermissionStatus.limited;
    if (!granted) {
      if (mounted) {
        context.showCenteredNotice(
          _t(
            context,
            '需要开启相册权限后才能更换主页背景',
            'Photo permission is required to change your background',
          ),
        );
      }
      return;
    }

    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 1800,
    );
    if (file == null) {
      return;
    }

    final progressNotifier = ValueNotifier<double?>(0);
    BuildContext? uploadDialogContext;
    Future<void>? uploadDialogFuture;
    if (mounted) {
      setState(() {
        _profileBackgroundUploading = true;
        _profileBackgroundUploadProgress = 0;
      });
      uploadDialogFuture = showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (dialogContext) {
          uploadDialogContext = dialogContext;
          return _ImageUploadProgressDialog(
            title: _t(context, '正在上传背景', 'Uploading background'),
            progress: progressNotifier,
          );
        },
      );
      unawaited(uploadDialogFuture);
      await WidgetsBinding.instance.endOfFrame;
    }

    try {
      final bundle = await ref
          .read(meSettingsRepositoryProvider)
          .uploadProfileBackground(
            file: file,
            onSendProgress: (sent, total) {
              if (total <= 0) {
                return;
              }
              final progress = (sent / total).clamp(0, 1).toDouble();
              progressNotifier.value = progress;
              if (mounted) {
                setState(() => _profileBackgroundUploadProgress = progress);
              }
            },
          );
      progressNotifier.value = 1;
      if (!mounted) {
        return;
      }
      setState(() {
        _profileBundle = bundle;
        _profileBackgroundUploadProgress = 1;
      });
      context.showCenteredNotice(_t(context, '主页背景已更新', 'Background updated'));
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    } finally {
      if (uploadDialogContext != null) {
        Navigator.of(uploadDialogContext!).pop();
      }
      if (uploadDialogFuture != null && uploadDialogContext != null) {
        await uploadDialogFuture;
      }
      progressNotifier.dispose();
      if (mounted) {
        setState(() {
          _profileBackgroundUploading = false;
          _profileBackgroundUploadProgress = null;
        });
      }
    }
  }

  Future<void> _editNickname(MeProfileBundle bundle) async {
    final nextValue = await _showTextInputDialog(
      context: context,
      title: _t(context, '修改昵称', 'Edit nickname'),
      initialValue: bundle.nickname,
      hintText: _t(context, '请输入昵称', 'Enter nickname'),
    );
    if (!mounted) {
      return;
    }
    if (nextValue == null || nextValue.trim() == bundle.nickname.trim()) {
      return;
    }
    await _saveProfilePayload({
      'nickname': nextValue.trim(),
    }, successMessage: _t(context, '昵称已更新', 'Nickname updated'));
  }

  Future<void> _editGender(MeProfileBundle bundle) async {
    final currentGender = bundle.gender ?? 3;
    final selected = await _showChoiceSheet<int>(
      context: context,
      title: _t(context, '选择性别', 'Select gender'),
      currentValue: currentGender,
      items: [
        _ChoiceSheetItem(1, _t(context, '男', 'Male')),
        _ChoiceSheetItem(2, _t(context, '女', 'Female')),
        _ChoiceSheetItem(3, _t(context, '保密', 'Private')),
      ],
    );
    if (!mounted) {
      return;
    }
    if (selected == null || selected == currentGender) {
      return;
    }
    await _saveProfilePayload({
      'gender': selected,
    }, successMessage: _t(context, '性别已更新', 'Gender updated'));
  }

  Future<void> _editBirthday(MeProfileBundle bundle) async {
    final initialDate =
        DateTime.tryParse(bundle.birthday) ??
        DateTime(DateTime.now().year - 18, 1, 1);
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
    );
    if (!mounted) {
      return;
    }
    if (selected == null) {
      return;
    }
    final text = _dateFormat.format(selected);
    if (text == bundle.birthday) {
      return;
    }
    await _saveProfilePayload({
      'birthday': text,
    }, successMessage: _t(context, '生日已更新', 'Birthday updated'));
  }

  Future<void> _editBio(MeProfileBundle bundle) async {
    final nextValue = await _showTextInputDialog(
      context: context,
      title: _t(context, '编辑个性签名', 'Edit signature'),
      initialValue: bundle.bio,
      hintText: _t(
        context,
        '写一句想展示在个人主页上的签名',
        'Write a signature for your profile',
      ),
      maxLines: 5,
    );
    if (!mounted) {
      return;
    }
    if (nextValue == null || nextValue.trim() == bundle.bio.trim()) {
      return;
    }
    await _saveProfilePayload({
      'bio': nextValue.trim(),
    }, successMessage: _t(context, '个性签名已更新', 'Signature updated'));
  }

  Future<void> _bindMobile() async {
    final initialMobile = _securityOverview?.member.mobile.isNotEmpty == true
        ? _securityOverview!.member.mobile
        : (_profileBundle?.mobile ?? '');
    final hadMobile = initialMobile.trim().isNotEmpty;
    final mobile = await _showTextInputDialog(
      context: context,
      title: hadMobile
          ? _t(context, '更换手机号', 'Change phone number')
          : _t(context, '绑定手机号', 'Bind phone number'),
      initialValue: '',
      hintText: hadMobile
          ? _t(context, '请输入新手机号', 'Enter the new phone number')
          : _t(context, '请输入要绑定的手机号', 'Enter the phone number to link'),
      helperText: hadMobile
          ? _t(context, '当前手机号：', 'Current phone: ') +
                _maskMobile(initialMobile)
          : _t(
              context,
              '手机号将用于登录验证和账号安全通知。',
              'Your phone number will be used for sign-in verification and account security notices.',
            ),
      confirmLabel: _t(context, '发送验证码', 'Send code'),
      keyboardType: TextInputType.phone,
    );
    if (!mounted) {
      return;
    }
    if (mobile == null || mobile.trim().isEmpty) {
      return;
    }
    final normalizedMobile = mobile.trim();
    if (normalizedMobile == initialMobile.trim()) {
      context.showCenteredNotice(
        _t(context, '请输入新的手机号', 'Enter a new phone number'),
      );
      return;
    }

    try {
      final delivery = await ref
          .read(meSettingsRepositoryProvider)
          .sendMobileCode(mobile: normalizedMobile);
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(
        _t(context, '验证码已发送至', 'Code sent to ') + delivery.target,
      );
      final code = await _showTextInputDialog(
        context: context,
        title: _t(context, '输入验证码', 'Enter verification code'),
        initialValue: '',
        hintText: _t(context, '请输入短信验证码', 'Enter SMS verification code'),
        helperText: _t(context, '验证码已发送至：', 'Code sent to: ') + delivery.target,
        confirmLabel: hadMobile
            ? _t(context, '完成更换', 'Finish change')
            : _t(context, '完成绑定', 'Finish linking'),
        keyboardType: TextInputType.number,
      );
      if (!mounted) {
        return;
      }
      if (code == null || code.trim().isEmpty) {
        return;
      }
      await ref
          .read(meSettingsRepositoryProvider)
          .bindMobile(mobile: normalizedMobile, code: code.trim());
      await ref.read(authControllerProvider.notifier).refreshCurrentSession();
      await _loadRemoteSection();
      if (mounted) {
        context.showCenteredNotice(
          hadMobile
              ? _t(context, '手机号已更换', 'Phone number updated')
              : _t(context, '手机号已绑定', 'Phone number linked'),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    }
  }

  Future<void> _bindEmail() async {
    final initialEmail = _securityOverview?.member.email.isNotEmpty == true
        ? _securityOverview!.member.email
        : (_profileBundle?.email ?? '');
    final hadEmail = initialEmail.trim().isNotEmpty;
    final email = await _showTextInputDialog(
      context: context,
      title: hadEmail
          ? _t(context, '更换邮箱', 'Change email')
          : _t(context, '绑定邮箱', 'Bind email'),
      initialValue: '',
      hintText: hadEmail
          ? _t(context, '请输入新邮箱', 'Enter the new email')
          : _t(context, '请输入要绑定的邮箱', 'Enter the email to link'),
      helperText: hadEmail
          ? _t(context, '当前邮箱：', 'Current email: ') + _maskEmail(initialEmail)
          : _t(
              context,
              '邮箱将用于登录验证、找回密码和账号安全通知。',
              'Your email will be used for sign-in verification, password recovery, and account security notices.',
            ),
      confirmLabel: _t(context, '发送验证码', 'Send code'),
      keyboardType: TextInputType.emailAddress,
    );
    if (!mounted) {
      return;
    }
    if (email == null || email.trim().isEmpty) {
      return;
    }
    final normalizedEmail = email.trim();
    if (normalizedEmail.toLowerCase() == initialEmail.trim().toLowerCase()) {
      context.showCenteredNotice(_t(context, '请输入新的邮箱', 'Enter a new email'));
      return;
    }

    try {
      final delivery = await ref
          .read(meSettingsRepositoryProvider)
          .sendEmailCode(email: normalizedEmail);
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(
        _t(context, '验证码已发送至', 'Code sent to ') + delivery.target,
      );
      final code = await _showTextInputDialog(
        context: context,
        title: _t(context, '输入验证码', 'Enter verification code'),
        initialValue: '',
        hintText: _t(context, '请输入邮箱验证码', 'Enter email verification code'),
        helperText: _t(context, '验证码已发送至：', 'Code sent to: ') + delivery.target,
        confirmLabel: hadEmail
            ? _t(context, '完成更换', 'Finish change')
            : _t(context, '完成绑定', 'Finish linking'),
        keyboardType: TextInputType.number,
      );
      if (!mounted) {
        return;
      }
      if (code == null || code.trim().isEmpty) {
        return;
      }
      await ref
          .read(meSettingsRepositoryProvider)
          .bindEmail(email: normalizedEmail, code: code.trim());
      await ref.read(authControllerProvider.notifier).refreshCurrentSession();
      await _loadRemoteSection();
      if (mounted) {
        context.showCenteredNotice(
          hadEmail
              ? _t(context, '邮箱已更换', 'Email updated')
              : _t(context, '邮箱已绑定', 'Email linked'),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    }
  }

  Future<void> _changePassword() async {
    final hasPassword = _securityOverview?.member.hasPassword ?? false;
    String? oldPassword;
    if (hasPassword) {
      oldPassword = await _showTextInputDialog(
        context: context,
        title: _t(context, '输入当前密码', 'Enter current password'),
        initialValue: '',
        hintText: _t(context, '当前密码', 'Current password'),
        obscureText: true,
      );
      if (!mounted) {
        return;
      }
      if (oldPassword == null || oldPassword.isEmpty) {
        return;
      }
    }
    final newPassword = await _showTextInputDialog(
      context: context,
      title: hasPassword
          ? _t(context, '设置新密码', 'Set new password')
          : _t(context, '设置密码', 'Set password'),
      initialValue: '',
      hintText: _t(context, '至少 6 位', 'At least 6 characters'),
      obscureText: true,
    );
    if (!mounted) {
      return;
    }
    if (newPassword == null || newPassword.isEmpty) {
      return;
    }
    final confirmPassword = await _showTextInputDialog(
      context: context,
      title: _t(context, '确认新密码', 'Confirm new password'),
      initialValue: '',
      hintText: _t(context, '请再次输入新密码', 'Enter the new password again'),
      obscureText: true,
    );
    if (!mounted) {
      return;
    }
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return;
    }
    if (newPassword != confirmPassword) {
      context.showCenteredNotice(
        _t(context, '两次输入的新密码不一致', 'Passwords do not match'),
      );
      return;
    }

    try {
      await ref
          .read(meSettingsRepositoryProvider)
          .changePassword(oldPassword: oldPassword, newPassword: newPassword);
      await _loadRemoteSection();
      if (mounted) {
        context.showCenteredNotice(
          hasPassword
              ? _t(context, '密码已更新', 'Password updated')
              : _t(context, '密码已设置', 'Password set'),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    }
  }

  Future<void> _showLinkedAccounts(SecurityOverview overview) async {
    final accounts = overview.thirdPartyAccounts;
    final sheetTitle = _t(context, '第三方账号', 'Connected accounts');
    final emptyText = _t(
      context,
      '当前未绑定第三方账号',
      'No connected third-party accounts',
    );
    final connectedText = _t(context, '已绑定', 'Connected');
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _SettingsPalette.of(context).pageBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
      builder: (sheetContext) {
        final palette = _SettingsPalette.of(sheetContext);
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text(
                    sheetTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _SettingsGroup(
                  children: accounts.isEmpty
                      ? [_SettingsNavRow(title: emptyText, showChevron: false)]
                      : accounts
                            .map(
                              (item) => _SettingsNavRow(
                                title: _platformLabel(
                                  item.platformCode,
                                  sheetContext,
                                ),
                                value: item.bindTime.isEmpty
                                    ? connectedText
                                    : item.bindTime,
                                showChevron: false,
                              ),
                            )
                            .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLoginDevices(SecurityOverview overview) async {
    final sheetTitle = _t(context, '登录设备', 'Login devices');
    final currentDevicesTitle = _t(context, '当前设备', 'Current devices');
    final noDeviceRecordsText = _t(context, '暂无设备记录', 'No device records');
    final recentSignInsTitle = _t(context, '最近登录', 'Recent sign-ins');
    final noRecentSignInsText = _t(context, '暂无登录记录', 'No recent sign-ins');
    final lastActiveLabel = _t(context, '最近活跃', 'Last active');
    final onlineText = _t(context, '当前在线', 'Online');
    final offlineText = _t(context, '已下线', 'Offline');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _SettingsPalette.of(context).pageBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final palette = _SettingsPalette.of(sheetContext);
        final devices = overview.devices;
        final logins = overview.recentLogins;
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.78,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text(
                    sheetTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _SettingsGroup(
                  title: currentDevicesTitle,
                  children: devices.isEmpty
                      ? [
                          _SettingsNavRow(
                            title: noDeviceRecordsText,
                            showChevron: false,
                          ),
                        ]
                      : devices
                            .map(
                              (item) => _SettingsNavRow(
                                title:
                                    '${_platformLabel(item.platform, sheetContext)} ${item.appVersion.isEmpty ? '' : item.appVersion}'
                                        .trim(),
                                subtitle: item.lastActiveTime.isEmpty
                                    ? null
                                    : '$lastActiveLabel: ${item.lastActiveTime}',
                                value: item.isActive ? onlineText : offlineText,
                                showChevron: false,
                              ),
                            )
                            .toList(),
                ),
                _SettingsGroup(
                  title: recentSignInsTitle,
                  children: logins.isEmpty
                      ? [
                          _SettingsNavRow(
                            title: noRecentSignInsText,
                            showChevron: false,
                          ),
                        ]
                      : logins
                            .map(
                              (item) => _SettingsNavRow(
                                title: _platformLabel(
                                  item.platformCode,
                                  sheetContext,
                                ),
                                subtitle: item.userAgent.isEmpty
                                    ? null
                                    : item.userAgent,
                                value: item.createTime,
                                showChevron: false,
                              ),
                            )
                            .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogoutOtherDevices(SecurityOverview overview) async {
    if (overview.activeDeviceCount <= 1) {
      context.showCenteredNotice(
        _t(context, '当前没有其他在线设备', 'No other active devices'),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t(dialogContext, '下线其他设备', 'Sign out other devices')),
        content: Text(
          _t(
            dialogContext,
            '这会保留当前设备登录，并下线其余在线设备。',
            'This keeps the current device signed in and signs out the others.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_t(dialogContext, '取消', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_t(dialogContext, '确认', 'Confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final deviceService = ref.read(deviceRegistrationServiceProvider);
      final currentDeviceId = await deviceService.readCurrentDeviceId();
      final loggedOut = await ref
          .read(meSettingsRepositoryProvider)
          .logoutOtherDevices(
            currentDeviceId: currentDeviceId,
            platform: deviceService.currentPlatform(),
          );
      await _loadRemoteSection();
      if (mounted) {
        context.showCenteredNotice(
          '${_t(context, '已下线其他设备', 'Other devices signed out')} ($loggedOut)',
        );
      }
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    }
  }

  Future<void> _saveProfilePayload(
    Map<String, dynamic> payload, {
    required String successMessage,
  }) async {
    try {
      final bundle = await ref
          .read(meSettingsRepositoryProvider)
          .saveProfile(payload);
      await ref.read(authControllerProvider.notifier).refreshCurrentSession();
      if (!mounted) {
        return;
      }
      setState(() {
        _profileBundle = bundle;
      });
      context.showCenteredNotice(successMessage);
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(_errorText(context, error));
      }
    }
  }

  String _genderLabel(int? gender, BuildContext context) {
    return switch (gender) {
      1 => _t(context, '男', 'Male'),
      2 => _t(context, '女', 'Female'),
      3 => _t(context, '保密', 'Private'),
      _ => _t(context, '未设置', 'Not set'),
    };
  }

  String _thirdPartyAccountSummary(
    SecurityOverview overview,
    BuildContext context,
  ) {
    final accounts = overview.thirdPartyAccounts;
    if (accounts.isEmpty) {
      return _t(context, '未绑定', 'None');
    }
    return accounts
        .map((item) => _platformLabel(item.platformCode, context))
        .join(' / ');
  }

  String _platformLabel(String platformCode, BuildContext context) {
    return switch (platformCode.toUpperCase()) {
      'GOOGLE' => 'Google',
      'APPLE' => 'Apple',
      'EMAIL' => _t(context, '邮箱', 'Email'),
      'MOBILE' => _t(context, '手机号', 'Phone'),
      'IOS' => 'iOS',
      'ANDROID' => 'Android',
      _ => platformCode.isEmpty ? _t(context, '未知', 'Unknown') : platformCode,
    };
  }

  String _summaryOrFallback(
    String value,
    BuildContext context, {
    required String emptyZh,
    required String emptyEn,
  }) {
    final text = value.trim();
    if (text.isEmpty) {
      return _t(context, emptyZh, emptyEn);
    }
    return text;
  }

  String _maskMobile(String mobile) {
    if (mobile.length != 11) {
      return mobile;
    }
    return '${mobile.substring(0, 3)}****${mobile.substring(7)}';
  }

  String _maskEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex <= 1) {
      return email;
    }
    return '${email.substring(0, 1)}***${email.substring(atIndex - 1)}';
  }

  String _avatarUploadingText(BuildContext context, double? progress) {
    if (progress == null) {
      return _t(context, '正在上传头像...', 'Uploading avatar...');
    }
    final percent = (progress.clamp(0, 1) * 100).round();
    return _t(context, '正在上传 $percent%', 'Uploading $percent%');
  }

  String _profileBackgroundUploadingText(
    BuildContext context,
    double? progress,
  ) {
    if (progress == null) {
      return _t(context, '正在上传背景...', 'Uploading background...');
    }
    final percent = (progress.clamp(0, 1) * 100).round();
    return _t(context, '正在上传 $percent%', 'Uploading $percent%');
  }

  String _errorText(BuildContext context, Object error) {
    final text = error.toString();
    if (text.contains('message: ')) {
      return text
          .replaceFirst(RegExp(r'^.*message: '), '')
          .replaceFirst(RegExp(r', traceId: .*$'), '');
    }
    return text.isEmpty
        ? _t(context, '操作失败，请稍后重试', 'Request failed. Please try again.')
        : text;
  }
}

enum SettingsSectionType {
  profile('profile'),
  security('security'),
  privacy('privacy'),
  system('system'),
  notifications('notifications'),
  about('about'),
  permissions('permissions');

  const SettingsSectionType(this.routeValue);

  final String routeValue;

  static SettingsSectionType fromRouteValue(String? value) {
    return switch (value) {
      'profile' => profile,
      'security' => security,
      'privacy' => privacy,
      'system' => system,
      'notifications' => notifications,
      'about' => about,
      'permissions' => permissions,
      _ => system,
    };
  }

  String title(BuildContext context) {
    return switch (this) {
      profile => _t(context, '个人资料设置', 'Profile settings'),
      security => _t(context, '账号安全', 'Account security'),
      privacy => _t(context, '隐私设置', 'Privacy settings'),
      system => _t(context, '系统设置', 'System settings'),
      notifications => _t(context, '通知设置', 'Notification settings'),
      about => _t(context, '关于 APP', 'About app'),
      permissions => _t(context, '权限管理', 'Permissions'),
    };
  }
}

class _ImageUploadProgressDialog extends StatelessWidget {
  const _ImageUploadProgressDialog({
    required this.title,
    required this.progress,
  });

  final String title;
  final ValueListenable<double?> progress;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 34),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: ValueListenableBuilder<double?>(
          valueListenable: progress,
          builder: (context, value, _) {
            final normalized = value?.clamp(0, 1).toDouble();
            final percent = normalized == null
                ? ''
                : ' ${(normalized * 100).round()}%';
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: palette.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        color: palette.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title + percent,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: palette.primaryText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: normalized,
                    backgroundColor: palette.iconBackground,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _t(
                    context,
                    '请保持当前页面，上传完成后会自动关闭。',
                    'Keep this page open. It will close when the upload finishes.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.secondaryText,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AvatarPreview extends ConsumerWidget {
  const _AvatarPreview({
    required this.url,
    this.isUploading = false,
    this.progress,
  });

  final String url;
  final bool isUploading;
  final double? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _SettingsPalette.of(context);
    final resolved = url.isEmpty
        ? ''
        : ref.read(apiClientProvider).resolveUrl(url);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.iconBackground,
        shape: BoxShape.circle,
        border: Border.all(color: palette.cardBorder),
      ),
      child: ClipOval(
        child: SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            fit: StackFit.expand,
            children: [
              resolved.isEmpty
                  ? Icon(Icons.person_rounded, color: palette.accent, size: 22)
                  : CachedRemoteImage(
                      resolved,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.person_rounded,
                        color: palette.accent,
                        size: 22,
                      ),
                    ),
              if (isUploading) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      value: progress?.clamp(0, 1).toDouble(),
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBackgroundPreview extends ConsumerWidget {
  const _ProfileBackgroundPreview({
    required this.url,
    this.isUploading = false,
    this.progress,
  });

  final String url;
  final bool isUploading;
  final double? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _SettingsPalette.of(context);
    final resolved = url.isEmpty
        ? ''
        : ref.read(apiClientProvider).resolveUrl(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 40,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF113754), Color(0xFFFCB08E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: resolved.isEmpty
                  ? Icon(
                      Icons.landscape_rounded,
                      color: Colors.white.withValues(alpha: 0.84),
                      size: 20,
                    )
                  : CachedRemoteImage(
                      resolved,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.landscape_rounded,
                        color: Colors.white.withValues(alpha: 0.84),
                        size: 20,
                      ),
                    ),
            ),
            if (isUploading) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                ),
              ),
              Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    value: progress?.clamp(0, 1).toDouble(),
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: palette.cardBorder),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPreviewSurface extends StatelessWidget {
  const _AvatarPreviewSurface({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.pageBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: 220,
          height: 220,
          child: url.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_rounded, color: palette.accent, size: 72),
                    const SizedBox(height: 10),
                    Text(
                      _t(context, '当前还没有头像', 'No avatar yet'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : CachedRemoteImage(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(
                    child: Text(
                      _t(context, '头像加载失败', 'Failed to load avatar'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ProfileBackgroundPreviewSurface extends StatelessWidget {
  const _ProfileBackgroundPreviewSurface({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.pageBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF113754),
                      Color(0xFF375E7A),
                      Color(0xFFFCB08E),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              if (url.isNotEmpty)
                CachedRemoteImage(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(
                    child: Text(
                      _t(context, '背景加载失败', 'Failed to load background'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: Text(
                    _t(context, '当前使用默认背景', 'Default background is active'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsPalette {
  const _SettingsPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.cardBorder,
    required this.primaryText,
    required this.secondaryText,
    required this.valueText,
    required this.groupTitle,
    required this.divider,
    required this.chevron,
    required this.accent,
    required this.danger,
    required this.iconBackground,
    required this.iconColor,
    required this.switchInactiveThumb,
    required this.switchInactiveTrack,
    required this.switchActiveTrack,
    required this.cardShadow,
  });

  static const _lightAccent = Color(0xFFFF8D7F);

  static _SettingsPalette of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    if (isDark) {
      return _SettingsPalette(
        pageBackground: scheme.surface,
        cardBackground: scheme.surfaceContainerHigh,
        cardBorder: Colors.white.withValues(alpha: 0.06),
        primaryText: scheme.onSurface,
        secondaryText: scheme.onSurfaceVariant,
        valueText: scheme.onSurfaceVariant,
        groupTitle: scheme.onSurfaceVariant,
        divider: Colors.white.withValues(alpha: 0.08),
        chevron: scheme.onSurfaceVariant.withValues(alpha: 0.72),
        accent: const Color(0xFFFFB4A8),
        danger: scheme.error,
        iconBackground: scheme.surfaceContainerHighest,
        iconColor: scheme.onSurfaceVariant,
        switchInactiveThumb: scheme.onSurfaceVariant,
        switchInactiveTrack: scheme.surfaceContainerHighest,
        switchActiveTrack: const Color(0xFF5D3631),
        cardShadow: const [],
      );
    }

    return _SettingsPalette(
      pageBackground: const Color(0xFFF7F7FA),
      cardBackground: Colors.white,
      cardBorder: Colors.white,
      primaryText: const Color(0xFF303236),
      secondaryText: const Color(0xFFA5A9B0),
      valueText: const Color(0xFF7D828A),
      groupTitle: const Color(0xFF8A9098),
      divider: const Color(0xFFE4E7EC),
      chevron: const Color(0xFFB7BCC4),
      accent: _lightAccent,
      danger: scheme.error,
      iconBackground: const Color(0xFFF1F4F6),
      iconColor: const Color(0xFF9FBBC3),
      switchInactiveThumb: Colors.white,
      switchInactiveTrack: const Color(0xFFE7EAEE),
      switchActiveTrack: const Color(0xFFFFDCD7),
      cardShadow: const [],
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color cardBorder;
  final Color primaryText;
  final Color secondaryText;
  final Color valueText;
  final Color groupTitle;
  final Color divider;
  final Color chevron;
  final Color accent;
  final Color danger;
  final Color iconBackground;
  final Color iconColor;
  final Color switchInactiveThumb;
  final Color switchInactiveTrack;
  final Color switchActiveTrack;
  final List<BoxShadow> cardShadow;

  Color accentFor(IconData? icon) {
    return icon == null ? accent : iconColor;
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children, this.title, this.footer});

  final String? title;
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _SettingsPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                title!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: palette.groupTitle,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: palette.cardBorder),
              boxShadow: palette.cardShadow,
            ),
            child: Column(
              children: [
                for (var index = 0; index < children.length; index += 1) ...[
                  children[index],
                  if (index != children.length - 1)
                    Divider(height: 1, indent: 68, color: palette.divider),
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                footer!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.secondaryText,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsNavRow extends StatelessWidget {
  const _SettingsNavRow({
    required this.title,
    this.icon,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.showChevron = true,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _SettingsPalette.of(context);
    final accentColor = danger ? palette.danger : palette.accentFor(icon);
    final titleColor = danger ? palette.danger : palette.primaryText;
    final iconBackground = danger
        ? palette.danger.withValues(alpha: 0.10)
        : palette.iconBackground;
    final hasChevron = showChevron && onTap != null;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Padding(
          padding: EdgeInsets.fromLTRB(icon == null ? 18 : 16, 12, 14, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final valueWidth = value == null
                  ? 0.0
                  : (constraints.maxWidth * (icon == null ? 0.32 : 0.36))
                        .clamp(88.0, icon == null ? 126.0 : 154.0)
                        .toDouble();
              return Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, size: 21, color: accentColor),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.secondaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (value != null) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      width: valueWidth,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          value!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.valueText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                  if (hasChevron) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: palette.chevron),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _SettingsPalette.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 68),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: palette.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 58,
              child: Align(
                alignment: Alignment.centerRight,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: palette.accent,
                  activeTrackColor: palette.switchActiveTrack,
                  inactiveThumbColor: palette.switchInactiveThumb,
                  inactiveTrackColor: palette.switchInactiveTrack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CacheCategoryCheckbox extends StatelessWidget {
  const _CacheCategoryCheckbox({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.fileCount,
    required this.sizeLabel,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final int fileCount;
  final String sizeLabel;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _SettingsPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.cardBorder),
      ),
      child: CheckboxListTile(
        value: enabled && value,
        onChanged: enabled ? onChanged : null,
        activeColor: palette.accent,
        contentPadding: const EdgeInsetsDirectional.only(start: 8, end: 10),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: enabled ? palette.primaryText : palette.secondaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          [
            subtitle,
            '$sizeLabel / ${_formatCacheFileCount(context, fileCount)}',
          ].join('\n'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.secondaryText,
          ),
        ),
      ),
    );
  }
}

class _CompactPrivacyRow extends StatelessWidget {
  const _CompactPrivacyRow({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    return Material(
      color: palette.cardBackground,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: palette.secondaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                value,
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.chevron,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceSheetItem<T> {
  const _ChoiceSheetItem(this.value, this.label);

  final T value;
  final String label;
}

Future<T?> _showChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required T currentValue,
  required List<_ChoiceSheetItem<T>> items,
}) {
  final palette = _SettingsPalette.of(context);
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: palette.pageBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      final palette = _SettingsPalette.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: palette.cardBorder),
                  boxShadow: palette.cardShadow,
                ),
                child: Column(
                  children: [
                    for (var index = 0; index < items.length; index += 1) ...[
                      _ChoiceSheetRow<T>(
                        item: items[index],
                        selected: items[index].value == currentValue,
                      ),
                      if (index != items.length - 1)
                        Divider(height: 1, indent: 16, color: palette.divider),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<String?> _showTextInputDialog({
  required BuildContext context,
  required String title,
  required String initialValue,
  required String hintText,
  String? helperText,
  String? confirmLabel,
  int maxLines = 1,
  bool obscureText = false,
  TextInputType? keyboardType,
}) async {
  final palette = _SettingsPalette.of(context);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: palette.pageBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    showDragHandle: true,
    builder: (sheetContext) => _SettingsTextInputSheet(
      title: title,
      initialValue: initialValue,
      hintText: hintText,
      helperText: helperText,
      confirmLabel: confirmLabel,
      maxLines: maxLines,
      obscureText: obscureText,
      keyboardType: keyboardType,
    ),
  );
}

class _SettingsTextInputSheet extends StatefulWidget {
  const _SettingsTextInputSheet({
    required this.title,
    required this.initialValue,
    required this.hintText,
    required this.helperText,
    required this.confirmLabel,
    required this.maxLines,
    required this.obscureText,
    this.keyboardType,
  });

  final String title;
  final String initialValue;
  final String hintText;
  final String? helperText;
  final String? confirmLabel;
  final int maxLines;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  State<_SettingsTextInputSheet> createState() =>
      _SettingsTextInputSheetState();
}

class _SettingsTextInputSheetState extends State<_SettingsTextInputSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close([String? value]) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _SettingsPalette.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: palette.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.cardBackground,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLines: widget.obscureText ? 1 : widget.maxLines,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          if (widget.helperText != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                widget.helperText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.secondaryText,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _close(),
                  child: Text(_t(context, '取消', 'Cancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _close(_controller.text),
                  child: Text(
                    widget.confirmLabel ?? _t(context, '确定', 'Confirm'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _openDetail(BuildContext context, SettingsSectionType section) {
  context.push('/me/settings/${section.routeValue}');
}

class _ChoiceSheetRow<T> extends StatelessWidget {
  const _ChoiceSheetRow({required this.item, required this.selected});

  final _ChoiceSheetItem<T> item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _SettingsPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.of(context).pop(item.value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: selected ? palette.accent : palette.primaryText,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_rounded, color: palette.accent),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(_t(dialogContext, '退出登录', 'Sign out')),
      content: Text(
        _t(dialogContext, '确定要退出当前账号吗？', 'Sign out of the current account?'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(_t(dialogContext, '取消', 'Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(_t(dialogContext, '退出', 'Sign out')),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  await ref.read(authControllerProvider.notifier).logout();
  if (context.mounted) {
    context.go('/login');
  }
}

String _themeModeLabel(BuildContext context, ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => _t(context, '跟随系统', 'System'),
    ThemeMode.light => _t(context, '浅色', 'Light'),
    ThemeMode.dark => _t(context, '深色', 'Dark'),
  };
}

String _formatCacheSize(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex += 1;
  }
  if (unitIndex == 0) {
    return '${value.toStringAsFixed(0)} ${units[unitIndex]}';
  }
  return '${value.toStringAsFixed(value >= 10 ? 1 : 2)} ${units[unitIndex]}';
}

String _formatCacheFileCount(BuildContext context, int count) {
  return _t(context, '$count 个', '$count files');
}

String _cacheCategoryTitle(BuildContext context, LocalCacheCategory category) {
  return switch (category) {
    LocalCacheCategory.remoteImages => _t(
      context,
      '远程图片缓存',
      'Remote image cache',
    ),
    LocalCacheCategory.materialFiles => _t(
      context,
      '素材离线缓存',
      'Material offline cache',
    ),
    LocalCacheCategory.temporaryMedia => _t(
      context,
      '临时媒体缓存',
      'Temporary media cache',
    ),
  };
}

String _cacheCategoryDescription(
  BuildContext context,
  LocalCacheCategory category,
) {
  return switch (category) {
    LocalCacheCategory.remoteImages => _t(
      context,
      '头像、封面、社区图片等 HTTP 图片',
      'HTTP images such as avatars, covers, and community images',
    ),
    LocalCacheCategory.materialFiles => _t(
      context,
      '用户手动离线保存的音频、PDF、图片等素材',
      'Audio, PDF, image, and other material files saved offline',
    ),
    LocalCacheCategory.temporaryMedia => _t(
      context,
      '图片选择器产生的临时图片、缩略图和压缩文件',
      'Temporary images, thumbnails, and compressed files from media pickers',
    ),
  };
}

String _textScaleLabel(BuildContext context, double scale) {
  if (scale == AppTextScaleController.small) {
    return _t(context, '小', 'Small');
  }
  if (scale == AppTextScaleController.large) {
    return _t(context, '大', 'Large');
  }
  return _t(context, '标准', 'Default');
}

String _permissionValueLabel(BuildContext context, PermissionStatus? status) {
  if (status == null) {
    return _t(context, '读取中', 'Loading');
  }
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
      '已拒绝',
      'Denied permanently',
    ),
    PermissionStatus.provisional => _t(context, '临时授权', 'Provisional'),
  };
}

String _permissionResultMessage(BuildContext context, PermissionStatus status) {
  return _isRuntimePermissionUsable(status)
      ? _t(context, '权限已开启', 'Permission is enabled')
      : _t(
          context,
          '权限未开启，可在系统设置中打开',
          'Permission is not enabled. You can enable it in system settings.',
        );
}

bool _isRuntimePermissionUsable(PermissionStatus status) {
  return status.isGranted ||
      status == PermissionStatus.limited ||
      status == PermissionStatus.provisional;
}

bool _shouldOpenSettingsForPermission(PermissionStatus status) {
  return status == PermissionStatus.permanentlyDenied ||
      status == PermissionStatus.restricted;
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
