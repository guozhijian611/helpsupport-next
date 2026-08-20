import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:helpsupport_app/core/cache/cached_remote_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/member_text_localizer.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/ui/app_tab_shell_metrics.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_models.dart';
import '../../doctor/presentation/doctor_me_screen.dart';
import '../application/me_content_controller.dart';
import '../data/me_content_models.dart';
import '../../plan/application/plan_controller.dart';
import '../../plan/data/plan_models.dart';
import 'honor_badges_support.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  static const _pageBackground = Color(0xFFF4F5F9);
  static const _primaryText = Color(0xFF303236);
  static const _mutedText = Color(0xFF96999F);
  static const _accent = Color(0xFFFF9585);
  static const _blue = Color(0xFF5A81DA);
  static const _orange = Color(0xFFFFAE4D);
  static const _purple = Color(0xFF986FF5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _MePalette.of(context);
    final metrics = AppTabShellMetrics.of(context);
    final authState = ref.watch(authControllerProvider);
    final session = switch (authState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (session?.currentRole == 'doctor') {
      return const DoctorMeScreen();
    }
    final currentMemberId = int.tryParse(session?.memberId ?? '') ?? 0;
    final apiClient = ref.watch(apiClientProvider);
    final profile = _MeProfile.fromSession(session, apiClient.resolveUrl);
    final badges = switch (ref.watch(memberBadgesProvider)) {
      AsyncData(:final value) => value.list,
      _ => const <MemberBadge>[],
    };
    final pointLogs = ref.watch(pointLogsProvider);
    final honorBalance = switch (pointLogs) {
      AsyncData(:final value) => value.balance,
      _ => _intValue(session?.member['points_balance']),
    };
    final honorMember = switch (pointLogs) {
      AsyncData(:final value) => honorMemberPayload(session?.member, value.member),
      _ => session?.member,
    };
    final honorSummary = buildHonorSummary(
      context,
      balance: honorBalance,
      badgeCount: latestDistinctBadges(badges).length,
      member: honorMember,
    );
    final plans = switch (ref.watch(currentPlansProvider)) {
      AsyncData(:final value) => value,
      _ => const <TreatmentPlan>[],
    };
    final tasks = switch (ref.watch(dailyTasksProvider)) {
      AsyncData(:final value) => value.list,
      _ => const <DailyTask>[],
    };
    final finishedTasks = tasks.where((task) => task.isDone).length;
    final pendingTasks = tasks.where((task) => !task.isDone).length;
    final currentPlanTitle = plans.isEmpty
        ? context.l10n.meNoTask
        : plans.first.title;
    final monthPlanValue = pendingTasks > 0
        ? _t(context, '待完成 $pendingTasks 项', '$pendingTasks pending')
        : currentPlanTitle;
    final scrollPadding = metrics
        .edgeInsets(22, 18, 22, 0)
        .copyWith(
          bottom: metrics.floatingTabBarInset(context, extraSpacing: 28),
        );

    return ColoredBox(
      color: palette.pageBackground,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: scrollPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(
                    profile: profile,
                    onProfileTap: currentMemberId > 0
                        ? () => context.push(
                            '/community/profile/$currentMemberId',
                          )
                        : null,
                  ),
                  SizedBox(height: metrics.size(18)),
                  _SummaryGrid(
                    cards: [
                      _SummaryCardData(
                        title: context.l10n.meMonthPlan,
                        value: monthPlanValue,
                        icon: Icons.graphic_eq_rounded,
                        color: _accent,
                      ),
                      _SummaryCardData(
                        title: context.l10n.meKeyTrigger,
                        value: profile.triggerSummary.isEmpty
                            ? _t(context, '待补充', 'To complete')
                            : profile.triggerSummary,
                        icon: Icons.hub_rounded,
                        color: _orange,
                      ),
                      _SummaryCardData(
                        title: context.l10n.meRecoveryGoal,
                        value: profile.recoveryGoal.isEmpty
                            ? _t(
                                context,
                                '已完成 $finishedTasks 项',
                                '$finishedTasks finished',
                              )
                            : profile.recoveryGoal,
                        icon: Icons.track_changes_rounded,
                        color: _blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  _HonorPreview(
                    summary: honorSummary,
                    onTap: () => context.push('/me/honors'),
                  ),
                  const SizedBox(height: 20),
                  const _BenefitStrip(),
                  const SizedBox(height: 24),
                  const _QuickActionsPanel(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MeProfile {
  const _MeProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.avatarUrl,
    required this.triggerSummary,
    required this.recoveryGoal,
  });

  final String name;
  final String age;
  final String gender;
  final String avatarUrl;
  final String triggerSummary;
  final String recoveryGoal;

  factory _MeProfile.fromSession(
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
    ]);
    final gender = normalizeGenderKey(
      _firstText([profile['gender'], member['gender']], fallback: '男'),
    );
    final age = _firstText([profile['age'], member['age']]);
    final birthday = _firstText([profile['birthday'], member['birthday']]);
    final avatar = _firstText([member['avatar']]);
    final triggers = _stringListValue(profile['trigger_tags']);
    final recoveryGoal = _firstText([
      profile['recovery_goal'],
      member['recovery_goal'],
    ]);

    return _MeProfile(
      name: name.isEmpty ? _fallbackDisplayName(session) : name,
      age: age.isEmpty ? _ageFromBirthday(birthday) : age,
      gender: gender,
      avatarUrl: avatar.isEmpty ? '' : resolveUrl(avatar),
      triggerSummary: triggers.take(2).join(' '),
      recoveryGoal: recoveryGoal,
    );
  }

  static String _fallbackDisplayName(AuthSession? session) {
    final memberId = session?.memberId.trim() ?? '';
    if (memberId.isNotEmpty) {
      return 'ID $memberId';
    }
    return 'Member';
  }

  static String _firstText(List<Object?> values, {String fallback = ''}) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty && text != 'null') {
        return text;
      }
    }
    return fallback;
  }

  static String _ageFromBirthday(String birthday) {
    final date = DateTime.tryParse(birthday);
    if (date == null) {
      return '';
    }
    final now = DateTime.now();
    var age = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      age -= 1;
    }
    return math.max(age, 0).toString();
  }

  static List<String> _stringListValue(Object? value) {
    if (value is List) {
      return value
          .map((item) => (item ?? '').toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String && value.trim().isNotEmpty) {
      final normalized = value.trim();
      if (normalized.startsWith('[') && normalized.endsWith(']')) {
        try {
          final decoded = jsonDecode(normalized);
          if (decoded is List) {
            return decoded
                .map((item) => (item ?? '').toString().trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false);
          }
        } on FormatException {
          // Fall through to comma splitting for legacy manually-entered values.
        }
      }
      return normalized
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, this.onProfileTap});

  final _MeProfile profile;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final palette = _MePalette.of(context);
    final metrics = AppTabShellMetrics.of(context);
    return SizedBox(
      height: metrics.size(AppTabShellMetrics.headerBlockHeight),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: onProfileTap,
                child: Row(
                  children: [
                    _MemberAvatar(
                      avatarUrl: profile.avatarUrl,
                      size: metrics.size(AppTabShellMetrics.headerAvatarSize),
                    ),
                    SizedBox(width: metrics.size(12)),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.primaryText,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: metrics.size(8)),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: metrics.size(12),
                            runSpacing: metrics.size(6),
                            children: [
                              if (profile.age.isNotEmpty)
                                _MetaText(
                                  label: context.l10n.meAgeLabel,
                                  value: profile.age,
                                ),
                              _GenderPill(gender: profile.gender),
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
          SizedBox(width: metrics.size(12)),
          _RoundIconButton(
            icon: Icons.settings_outlined,
            onTap: () => context.push('/me/settings'),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.avatarUrl,
    this.size = AppTabShellMetrics.headerAvatarSize,
  });

  final String avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isEmpty) {
      return _RobotAvatar(size: size);
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CachedRemoteImage(
          avatarUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _RobotAvatar(size: size),
        ),
      ),
    );
  }
}

class _RobotAvatar extends StatelessWidget {
  const _RobotAvatar({this.size = AppTabShellMetrics.headerAvatarSize});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RobotAvatarPainter()),
    );
  }
}

class _RobotAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final scale = size.width / 56;

    RRect rr(double x, double y, double w, double h, double r) {
      return RRect.fromRectAndRadius(
        Rect.fromLTWH(x * scale, y * scale, w * scale, h * scale),
        Radius.circular(r * scale),
      );
    }

    paint.color = const Color(0xFF8E8E93);
    canvas.drawOval(
      Rect.fromLTWH(8 * scale, 44 * scale, 40 * scale, 8 * scale),
      paint,
    );

    paint.color = const Color(0xFFD6D6D9);
    canvas.drawRRect(rr(12, 18, 32, 28, 10), paint);
    canvas.drawRRect(rr(16, 42, 24, 8, 4), paint);

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..color = const Color(0xFF77777D);
    canvas.drawRRect(rr(12, 18, 32, 28, 10), paint);

    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF303236);
    canvas.drawRRect(rr(17, 26, 22, 12, 4), paint);

    paint.color = const Color(0xFFFFB14E);
    canvas.drawCircle(Offset(24 * scale, 32 * scale), 2.4 * scale, paint);
    canvas.drawCircle(Offset(32 * scale, 32 * scale), 2.4 * scale, paint);

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * scale
      ..color = const Color(0xFFFF9585);
    canvas.drawArc(
      Rect.fromLTWH(24 * scale, 33 * scale, 8 * scale, 4 * scale),
      0,
      math.pi,
      false,
      paint,
    );

    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFB8B8BD);
    canvas.drawRRect(rr(20, 9, 16, 10, 4), paint);
    paint.color = const Color(0xFFFF9585);
    canvas.drawCircle(Offset(28 * scale, 7 * scale), 3 * scale, paint);

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..color = const Color(0xFF8E8E93);
    canvas.drawLine(
      Offset(13 * scale, 39 * scale),
      Offset(5 * scale, 43 * scale),
      paint,
    );
    canvas.drawLine(
      Offset(43 * scale, 39 * scale),
      Offset(51 * scale, 43 * scale),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = _MePalette.of(context);
    return RichText(
      textScaler: MediaQuery.textScalerOf(context),
      text: TextSpan(
        style: const TextStyle(fontSize: 15, height: 1.15),
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

class _GenderPill extends StatelessWidget {
  const _GenderPill({required this.gender});

  final String gender;

  @override
  Widget build(BuildContext context) {
    final palette = _MePalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: palette.pillBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MetaText(
            label: context.l10n.meGenderLabel,
            value: localizedGender(context, gender),
          ),
          const SizedBox(width: 6),
          Transform.rotate(
            angle: -math.pi / 2,
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: MeScreen._blue,
              size: 16,
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
    final palette = _MePalette.of(context);
    final metrics = AppTabShellMetrics.of(context);
    final buttonSize = metrics.size(AppTabShellMetrics.actionButtonSize);
    return Material(
      color: palette.iconButtonBackground,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Icon(icon, size: metrics.size(20), color: palette.primaryText),
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.cards});

  final List<_SummaryCardData> cards;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < cards.length; index += 1) ...[
          if (index > 0) const SizedBox(width: 10),
          Expanded(child: _SummaryCard(data: cards[index])),
        ],
      ],
    );
  }
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryCardData data;

  @override
  Widget build(BuildContext context) {
    final palette = _MePalette.of(context);
    final metrics = AppTabShellMetrics.of(context);
    return Container(
      height: metrics.size(104),
      padding: metrics.edgeInsets(16, 16, 12, 16),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.mutedText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
              SizedBox(width: metrics.size(8)),
              CircleAvatar(
                radius: metrics.size(16),
                backgroundColor: data.color,
                child: Icon(
                  data.icon,
                  color: Colors.white,
                  size: metrics.size(20),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HonorPreview extends StatelessWidget {
  const _HonorPreview({required this.summary, required this.onTap});

  final HonorSummaryData summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 174,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: summary.currentLevel.gradientColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _HonorCardPainter()),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.meCurrentLevel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Lv.${summary.currentLevel.level} ${summary.currentLevel.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppTabShellMetrics.sectionTitleFontSize,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          honorPointsLabel(
                            context,
                            summary.currentLevel,
                            summary.balance,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          honorHintText(context, summary, summary.currentIndex),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 14,
                    child: _HonorProgressBar(
                      progress: summary.currentProgress,
                      knobColor: summary.currentLevel.progressDotColor,
                    ),
                  ),
                  Positioned(
                    top: 18,
                    right: 18,
                    child: _Medal(color: summary.currentLevel.medalColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HonorCardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    paint.color = Colors.white.withValues(alpha: 0.08);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.15,
        -size.height * 0.25,
        size.width,
        size.height,
      ),
      paint,
    );
    paint.color = Colors.white.withValues(alpha: 0.06);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.45,
        -size.height * 0.2,
        size.width * 0.7,
        size.height * 1.2,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Medal extends StatelessWidget {
  const _Medal({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 108,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 32,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
          ),
          Positioned(
            top: 20,
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.72),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '★',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HonorProgressBar extends StatelessWidget {
  const _HonorProgressBar({required this.progress, required this.knobColor});

  final double progress;
  final Color knobColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.max(0, constraints.maxWidth - 30);
          final left = width * progress.clamp(0, 1).toDouble();
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Positioned(
                left: left,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: knobColor,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BenefitStrip extends StatelessWidget {
  const _BenefitStrip();

  @override
  Widget build(BuildContext context) {
    final palette = _MePalette.of(context);
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: palette.softCardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BenefitItem(
              icon: Icons.medical_services_outlined,
              iconColor: MeScreen._accent,
              title: context.l10n.meMemoirBenefitTitle,
              description: context.l10n.meMemoirBenefitDesc,
              route: '/me/memoirs',
            ),
          ),
          Container(width: 1, height: 40, color: palette.divider),
          Expanded(
            child: _BenefitItem(
              icon: Icons.local_hospital_outlined,
              iconColor: MeScreen._blue,
              title: context.l10n.meFreeDoctorTitle,
              description: context.l10n.meFreeDoctorDesc,
              route: '/appointments/doctors',
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.route,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? route;

  @override
  Widget build(BuildContext context) {
    final palette = _MePalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        final route = this.route;
        if (route == null) {
          context.showCenteredNotice(context.l10n.featureComingSoon);
          return;
        }
        context.push(route);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel();

  @override
  Widget build(BuildContext context) {
    final palette = _MePalette.of(context);
    final metrics = AppTabShellMetrics.of(context);
    final actions = [
      _QuickActionData(
        title: context.l10n.meFollowing,
        icon: Icons.favorite_rounded,
        color: MeScreen._accent,
        route: '/community/relations/following/0',
      ),
      _QuickActionData(
        title: context.l10n.meCollection,
        icon: Icons.star_rounded,
        color: MeScreen._orange,
        route: '/materials?type=education&source=collections',
      ),
      _QuickActionData(
        title: context.l10n.meMyMedals,
        icon: Icons.workspace_premium_rounded,
        color: MeScreen._purple,
        route: '/me/honors/badges',
      ),
      _QuickActionData(
        title: context.l10n.meHistory,
        icon: Icons.schedule_rounded,
        color: MeScreen._blue,
        route: '/materials?type=education&source=history',
      ),
      _QuickActionData(
        title: context.l10n.meMemoir,
        icon: Icons.near_me_rounded,
        color: MeScreen._purple,
        route: '/me/memoirs',
      ),
      _QuickActionData(
        title: context.l10n.meJournal,
        icon: Icons.notes_rounded,
        color: MeScreen._blue,
        route: '/me/journals',
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.meCommonFunctions,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: AppTabShellMetrics.sectionTitleFontSize,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: metrics.size(30)),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 82,
              mainAxisSpacing: 26,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              return _QuickActionTile(action: actions[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
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

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickActionData action;

  @override
  Widget build(BuildContext context) {
    final palette = _MePalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        final route = action.route;
        if (route == null) {
          context.showCenteredNotice(context.l10n.featureComingSoon);
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
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse((value ?? '').toString()) ?? fallback;
}

class _MePalette {
  const _MePalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.softCardBackground,
    required this.primaryText,
    required this.mutedText,
    required this.pillBackground,
    required this.iconButtonBackground,
    required this.divider,
  });

  static _MePalette of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _MePalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      softCardBackground: isDark
          ? scheme.surfaceContainerHigh
          : const Color(0xFFF4F7FD),
      primaryText: scheme.onSurface,
      mutedText: scheme.onSurfaceVariant,
      pillBackground: isDark
          ? scheme.surfaceContainerHighest
          : const Color(0xFFF0F4FF),
      iconButtonBackground: isDark
          ? scheme.surfaceContainerHighest
          : Colors.white.withValues(alpha: 0.82),
      divider: scheme.outlineVariant,
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color softCardBackground;
  final Color primaryText;
  final Color mutedText;
  final Color pillBackground;
  final Color iconButtonBackground;
  final Color divider;
}
