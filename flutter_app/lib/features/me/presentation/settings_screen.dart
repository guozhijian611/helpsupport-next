import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/i18n/app_locale_controller.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/settings/app_display_preferences.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_protocol.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggingOut = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(_t(context, '设置', 'Settings'))),
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
                    '头像、昵称、性别、生日、康复目标',
                    'Avatar, name, gender, birthday, recovery goal',
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
                  value: '1.0.0',
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
                  onTap: () => _comingSoon(context),
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
  static const _privacyPrefix = 'settings.privacy.';
  static const _notificationPrefix = 'settings.notification.';

  _PrivacyVisibility _communityVisibility = _PrivacyVisibility.mutual;
  bool _anonymousPosting = true;
  bool _hideRecoveryStage = false;
  bool _showFollowingList = false;
  bool _showSignature = true;
  bool _syncDiarySummary = true;
  bool _autoClearAttachments = false;
  bool _confirmBeforeExport = true;
  bool _planReminders = true;
  bool _appointmentUpdates = true;
  bool _communityReplies = true;
  bool _journalReminders = false;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _communityVisibility = _PrivacyVisibility.fromStorage(
      prefs.getString('${_privacyPrefix}community_visibility'),
    );
    _anonymousPosting =
        prefs.getBool('${_privacyPrefix}anonymous_posting') ?? true;
    _hideRecoveryStage =
        prefs.getBool('${_privacyPrefix}hide_recovery_stage') ?? false;
    _showFollowingList =
        prefs.getBool('${_privacyPrefix}show_following_list') ?? false;
    _showSignature = prefs.getBool('${_privacyPrefix}show_signature') ?? true;
    _syncDiarySummary =
        prefs.getBool('${_privacyPrefix}sync_diary_summary') ?? true;
    _autoClearAttachments =
        prefs.getBool('${_privacyPrefix}auto_clear_attachments') ?? false;
    _confirmBeforeExport =
        prefs.getBool('${_privacyPrefix}confirm_before_export') ?? true;
    _planReminders =
        prefs.getBool('${_notificationPrefix}plan_reminders') ?? true;
    _appointmentUpdates =
        prefs.getBool('${_notificationPrefix}appointment_updates') ?? true;
    _communityReplies =
        prefs.getBool('${_notificationPrefix}community_replies') ?? true;
    _journalReminders =
        prefs.getBool('${_notificationPrefix}journal_reminders') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.section.title(context))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: switch (widget.section) {
            SettingsSectionType.profile => _profileChildren(context),
            SettingsSectionType.security => _securityChildren(context),
            SettingsSectionType.privacy => _privacyChildren(context),
            SettingsSectionType.system => _systemChildren(context),
            SettingsSectionType.notifications => _notificationChildren(context),
            SettingsSectionType.about => _aboutChildren(context),
            SettingsSectionType.permissions => _permissionChildren(context),
          },
        ),
      ),
    );
  }

  List<Widget> _profileChildren(BuildContext context) {
    return [
      _SettingsGroup(
        children: [
          _SettingsNavRow(
            title: _t(context, '头像', 'Avatar'),
            value: _t(context, '当前头像', 'Current'),
            onTap: () => _comingSoon(context),
          ),
          _SettingsNavRow(
            title: _t(context, '昵称', 'Nickname'),
            value: 'u35911516',
            onTap: () => _comingSoon(context),
          ),
          _SettingsNavRow(
            title: _t(context, '性别与生日', 'Gender and birthday'),
            value: _t(context, '男 / 18', 'Male / 18'),
            onTap: () => _comingSoon(context),
          ),
          _SettingsNavRow(
            title: _t(context, '手机号', 'Phone number'),
            value: _t(context, '未绑定', 'Not linked'),
            onTap: () => _comingSoon(context),
          ),
        ],
      ),
      _SettingsGroup(
        title: _t(context, '康复信息', 'Recovery'),
        children: [
          _SettingsNavRow(
            title: _t(context, '康复目标', 'Recovery goal'),
            value: _t(context, '0', '0'),
            onTap: () => _comingSoon(context),
          ),
          _SettingsNavRow(
            title: _t(context, '重点触发', 'Key triggers'),
            value: _t(context, '待补充', 'To complete'),
            onTap: () => _comingSoon(context),
          ),
          _SettingsNavRow(
            title: _t(context, '专属回忆录资料', 'Memory profile'),
            onTap: () => _comingSoon(context),
          ),
        ],
      ),
    ];
  }

  List<Widget> _securityChildren(BuildContext context) {
    return [
      _SettingsGroup(
        children: [
          _SettingsNavRow(
            title: _t(context, '修改密码', 'Change password'),
            onTap: () => _comingSoon(context),
          ),
          _SettingsNavRow(
            title: _t(context, '绑定手机号', 'Linked phone'),
            value: _t(context, '未绑定', 'Not linked'),
            onTap: () => _comingSoon(context),
          ),
          _SettingsNavRow(
            title: _t(context, '第三方账号', 'Connected accounts'),
            value: _t(context, '未绑定', 'None'),
            onTap: () => _comingSoon(context),
          ),
          _SettingsNavRow(
            title: _t(context, '登录设备', 'Login devices'),
            onTap: () => _comingSoon(context),
          ),
          _SettingsNavRow(
            title: _t(context, '单点登录状态', 'Single sign-on status'),
            value: _t(context, '已启用', 'Enabled'),
            onTap: () => _comingSoon(context),
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
            title: _t(context, '自动清理附件缓存', 'Auto-clear attachment cache'),
            subtitle: _t(
              context,
              '定期删除未使用的临时图片和视频缩略图',
              'Delete unused temporary media thumbnails',
            ),
            value: _autoClearAttachments,
            onChanged: (value) => _setPrivacyBool(
              'auto_clear_attachments',
              value,
              (next) => _autoClearAttachments = next,
            ),
          ),
          _SettingsNavRow(
            title: _t(context, '本地数据与缓存', 'Local data and cache'),
            value: _t(context, '检查', 'Check'),
            onTap: () => context.showCenteredNotice(
              _t(context, '已检查本地缓存', 'Local cache checked'),
            ),
          ),
        ],
      ),
    ];
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
        children: [
          _SettingsNavRow(
            title: _t(context, '通知', 'Notifications'),
            value: _t(context, '系统设置', 'System'),
            onTap: _requestNotifications,
          ),
          _SettingsNavRow(
            title: _t(context, '相册', 'Photos'),
            value: _t(context, '按需申请', 'On request'),
            onTap: () => _comingSoon(context),
          ),
          _SettingsNavRow(
            title: _t(context, '相机', 'Camera'),
            value: _t(context, '按需申请', 'On request'),
            onTap: () => _comingSoon(context),
          ),
          _SettingsNavRow(
            title: _t(context, '麦克风', 'Microphone'),
            value: _t(context, '按需申请', 'On request'),
            onTap: () => _comingSoon(context),
          ),
          _SettingsNavRow(
            title: _t(context, '本地文件访问', 'Local files'),
            value: _t(context, '按需申请', 'On request'),
            onTap: () => _comingSoon(context),
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
            value: 'HelpSupport',
            showChevron: false,
          ),
          _SettingsNavRow(
            title: _t(context, '版本号', 'Version'),
            value: '1.0.0',
            showChevron: false,
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
              applicationName: 'HelpSupport',
              applicationVersion: '1.0.0',
            ),
          ),
          _SettingsNavRow(
            title: _t(context, '诊断信息', 'Diagnostics'),
            onTap: () => _comingSoon(context),
          ),
        ],
      ),
    ];
  }

  Future<void> _selectCommunityVisibility() async {
    final selected = await _showChoiceSheet<_PrivacyVisibility>(
      context: context,
      title: _t(context, '社区展示范围', 'Community visibility'),
      currentValue: _communityVisibility,
      items: [
        _ChoiceSheetItem(
          _PrivacyVisibility.private,
          _t(context, '仅自己', 'Private'),
        ),
        _ChoiceSheetItem(
          _PrivacyVisibility.mutual,
          _t(context, '互相关注', 'Mutual'),
        ),
        _ChoiceSheetItem(
          _PrivacyVisibility.public,
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
          .read(sharedPreferencesProvider)
          .setString(
            '${_privacyPrefix}community_visibility',
            selected.storageValue,
          ),
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
    if (selected == null) {
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
    if (selected == null) {
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
    if (selected == null) {
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
    unawaited(
      ref.read(sharedPreferencesProvider).setBool('$_privacyPrefix$key', value),
    );
  }

  void _setNotificationBool(
    String key,
    bool value,
    void Function(bool value) update,
  ) {
    setState(() => update(value));
    unawaited(
      ref
          .read(sharedPreferencesProvider)
          .setBool('$_notificationPrefix$key', value),
    );
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
  }

  void _comingSoon(BuildContext context) {
    context.showCenteredNotice(
      _t(
        context,
        '该设置入口已预留，后续接入接口后开放。',
        'This setting is reserved and will open after the API is connected.',
      ),
    );
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

enum _PrivacyVisibility {
  private('private'),
  mutual('mutual'),
  public('public');

  const _PrivacyVisibility(this.storageValue);

  final String storageValue;

  static _PrivacyVisibility fromStorage(String? value) {
    return switch (value) {
      'private' => private,
      'public' => public,
      _ => mutual,
    };
  }

  String label(BuildContext context) {
    return switch (this) {
      private => _t(context, '仅自己', 'Private'),
      mutual => _t(context, '互相关注', 'Mutual'),
      public => _t(context, '公开', 'Public'),
    };
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
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            child: Column(
              children: [
                for (var index = 0; index < children.length; index += 1) ...[
                  children[index],
                  if (index != children.length - 1)
                    Divider(
                      height: 1,
                      indent: 52,
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.65,
                      ),
                    ),
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
                  color: theme.colorScheme.onSurfaceVariant,
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
    this.onTap,
    this.danger = false,
    this.showChevron = true,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final bool danger;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = danger
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Padding(
          padding: EdgeInsets.fromLTRB(icon == null ? 16 : 14, 10, 12, 10),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 22,
                  color: danger ? theme.colorScheme.error : secondaryColor,
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
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 12),
                Flexible(
                  flex: 0,
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: secondaryColor,
                    ),
                  ),
                ),
              ],
              if (showChevron && onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: secondaryColor),
              ],
            ],
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 58),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
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
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
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
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.55,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    for (var index = 0; index < items.length; index += 1) ...[
                      _ChoiceSheetRow<T>(
                        item: items[index],
                        selected: items[index].value == currentValue,
                      ),
                      if (index != items.length - 1)
                        Divider(
                          height: 1,
                          indent: 16,
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.65,
                          ),
                        ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).pop(item.value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Expanded(child: Text(item.label, style: theme.textTheme.bodyLarge)),
            if (selected)
              Icon(Icons.check_rounded, color: theme.colorScheme.primary),
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
      title: Text(_t(context, '退出登录', 'Sign out')),
      content: Text(
        _t(context, '确定要退出当前账号吗？', 'Sign out of the current account?'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(_t(context, '取消', 'Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(_t(context, '退出', 'Sign out')),
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

void _comingSoon(BuildContext context) {
  context.showCenteredNotice(
    _t(
      context,
      '该设置入口已预留，后续接入接口后开放。',
      'This setting is reserved and will open after the API is connected.',
    ),
  );
}

String _themeModeLabel(BuildContext context, ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => _t(context, '跟随系统', 'System'),
    ThemeMode.light => _t(context, '浅色', 'Light'),
    ThemeMode.dark => _t(context, '深色', 'Dark'),
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

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
