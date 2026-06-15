import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_models.dart';

class DoctorMeScreen extends ConsumerWidget {
  const DoctorMeScreen({super.key});

  static const _pageBackground = Color(0xFFF4F5F9);
  static const _primaryText = Color(0xFF303236);
  static const _mutedText = Color(0xFF96999F);
  static const _accent = Color(0xFFFF9585);
  static const _blue = Color(0xFF5A81DA);
  static const _orange = Color(0xFFFFAE4D);
  static const _privacy = Color(0xFFA4C3CC);
  static const _purple = Color(0xFF986FF5);
  static const _green = Color(0xFF7BC96F);
  static const _patientBlue = Color(0xFF94C2F8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _DoctorMePalette.of(context);
    final authState = ref.watch(authControllerProvider);
    final session = switch (authState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final currentMemberId = int.tryParse(session?.memberId ?? '') ?? 0;
    final apiClient = ref.watch(apiClientProvider);
    final profile = _DoctorMeProfile.fromSession(session, apiClient.resolveUrl);

    final actions = [
      _DoctorActionData(
        title: _t(context, '我的关注', 'Following'),
        icon: Icons.favorite_rounded,
        color: _accent,
        route: '/community/relations/following/0',
      ),
      _DoctorActionData(
        title: _t(context, '我的收藏', 'Collections'),
        icon: Icons.star_rounded,
        color: _orange,
        route: '/materials?type=education&source=collections',
      ),
      _DoctorActionData(
        title: _t(context, '历史记录', 'History'),
        icon: Icons.schedule_rounded,
        color: _blue,
        route: '/materials?type=education&source=history',
      ),
      _DoctorActionData(
        title: _t(context, '隐私设置', 'Privacy'),
        icon: Icons.lock_rounded,
        color: _privacy,
        route: '/me/settings/privacy',
      ),
      _DoctorActionData(
        title: _t(context, '治疗计划', 'Plan'),
        icon: Icons.bookmark_rounded,
        color: const Color(0xFF7E7FF0),
        route: '/doctor/plan',
      ),
      _DoctorActionData(
        title: _t(context, '任务模板', 'Templates'),
        icon: Icons.library_books_rounded,
        color: _purple,
        route: '/doctor/task-templates',
      ),
      _DoctorActionData(
        title: _t(context, '我的患者', 'Patients'),
        icon: Icons.groups_2_rounded,
        color: _patientBlue,
        route: '/doctor/patients',
      ),
      _DoctorActionData(
        title: _t(context, '评估量表', 'Scales'),
        icon: Icons.fact_check_rounded,
        color: _green,
        route: '/doctor/assessment-scales',
      ),
    ];

    return ColoredBox(
      color: palette.pageBackground,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: currentMemberId > 0
                          ? () => context.push(
                              '/community/profile/$currentMemberId',
                            )
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            _DoctorAvatar(avatarUrl: profile.avatarUrl),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          profile.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: palette.primaryText,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.badge_rounded,
                                        color: _blue,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 18,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      _MetaText(
                                        label: _t(context, '年龄', 'Age'),
                                        value: profile.age,
                                      ),
                                      _MetaText(
                                        label: _t(context, '性别', 'Gender'),
                                        value: profile.gender,
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
                  ),
                ),
                const SizedBox(width: 12),
                _RoundIconButton(
                  icon: Icons.settings_outlined,
                  onTap: () => context.push('/me/settings'),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
              decoration: BoxDecoration(
                color: palette.cardBackground,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(context, '常用功能', 'Common actions'),
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 34),
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: actions.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisExtent: 82,
                          mainAxisSpacing: 26,
                          crossAxisSpacing: 10,
                        ),
                    itemBuilder: (context, index) =>
                        _DoctorActionTile(action: actions[index]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorMeProfile {
  const _DoctorMeProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.avatarUrl,
  });

  final String name;
  final String age;
  final String gender;
  final String avatarUrl;

  factory _DoctorMeProfile.fromSession(
    AuthSession? session,
    String Function(String value) resolveUrl,
  ) {
    final profile = session?.profile ?? const <String, dynamic>{};
    final member = session?.member ?? const <String, dynamic>{};
    final name = _firstText([
      profile['nickname'],
      profile['display_name'],
      member['nickname'],
      member['username'],
      member['mobile'],
    ], fallback: 'Doctor');
    final birthday = _firstText([profile['birthday'], member['birthday']]);
    final age = _firstText([
      profile['age'],
      member['age'],
    ], fallback: _ageFromBirthday(birthday));
    final gender = _normalizeGender(
      _firstText([profile['gender'], member['gender']], fallback: '男'),
    );
    final avatar = _firstText([member['avatar']]);

    return _DoctorMeProfile(
      name: name,
      age: age.isEmpty ? '--' : age,
      gender: gender,
      avatarUrl: avatar.isEmpty ? '' : resolveUrl(avatar),
    );
  }
}

class _DoctorActionData {
  const _DoctorActionData({
    required this.title,
    required this.icon,
    required this.color,
    this.route,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String? route;
}

class _DoctorActionTile extends StatelessWidget {
  const _DoctorActionTile({required this.action});

  final _DoctorActionData action;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorMePalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        final route = action.route;
        if (route == null) {
          context.showCenteredNotice(
            _t(context, '该入口暂未开放', 'This action is not available yet'),
          );
          return;
        }
        context.push(route);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(action.icon, color: action.color, size: 34),
          const SizedBox(height: 18),
          Text(
            action.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorMePalette.of(context);
    if (avatarUrl.isEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: palette.avatarBackground,
        child: const Icon(Icons.person_rounded, color: DoctorMeScreen._blue),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: 56,
        height: 56,
        child: Image.network(
          avatarUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => CircleAvatar(
            radius: 28,
            backgroundColor: palette.avatarBackground,
            child: const Icon(
              Icons.person_rounded,
              color: DoctorMeScreen._blue,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorMePalette.of(context);
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 17, height: 1.2),
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              color: palette.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const TextSpan(text: '  '),
          TextSpan(
            text: value,
            style: TextStyle(
              color: palette.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorMePalette.of(context);
    return Material(
      color: palette.iconButtonBackground,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 58,
          height: 58,
          child: Icon(icon, size: 20, color: palette.primaryText),
        ),
      ),
    );
  }
}

String _firstText(List<Object?> values, {String fallback = ''}) {
  for (final value in values) {
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty && text != 'null') {
      return text;
    }
  }
  return fallback;
}

String _normalizeGender(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized == 'female' || normalized == '2' || normalized == '女') {
    return '女';
  }
  if (normalized == 'private' || normalized == '0' || normalized == '保密') {
    return '保密';
  }
  return '男';
}

String _ageFromBirthday(String birthday) {
  final date = DateTime.tryParse(birthday);
  if (date == null) {
    return '--';
  }
  final now = DateTime.now();
  var age = now.year - date.year;
  if (now.month < date.month ||
      (now.month == date.month && now.day < date.day)) {
    age -= 1;
  }
  return age < 0 ? '--' : '$age';
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

class _DoctorMePalette {
  const _DoctorMePalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.primaryText,
    required this.mutedText,
    required this.iconButtonBackground,
    required this.avatarBackground,
  });

  static _DoctorMePalette of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _DoctorMePalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      primaryText: scheme.onSurface,
      mutedText: scheme.onSurfaceVariant,
      iconButtonBackground: isDark
          ? scheme.surfaceContainerHighest
          : Colors.white.withValues(alpha: 0.82),
      avatarBackground: isDark
          ? scheme.surfaceContainerHighest
          : const Color(0xFFF0F4FF),
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color primaryText;
  final Color mutedText;
  final Color iconButtonBackground;
  final Color avatarBackground;
}
