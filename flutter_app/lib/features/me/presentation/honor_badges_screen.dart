import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/member_text_localizer.dart';
import '../../../core/cache/cached_remote_image.dart';
import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_models.dart';
import '../application/me_content_controller.dart';
import '../data/me_content_models.dart';
import 'honor_badges_support.dart';

class HonorBadgesScreen extends ConsumerWidget {
  const HonorBadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _HonorPalette.of(context);
    final authState = ref.watch(authControllerProvider);
    final session = switch (authState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final apiClient = ref.watch(apiClientProvider);
    final profile = _HonorProfile.fromSession(session, apiClient.resolveUrl);
    final badgesState = ref.watch(memberBadgesProvider);
    final pointsState = ref.watch(pointLogsProvider);
    final balance = switch (pointsState) {
      AsyncData(:final value) => value.balance,
      _ => _intValue(session?.member['points_balance']),
    };
    final badges = switch (badgesState) {
      AsyncData(:final value) => value.list,
      _ => const <MemberBadge>[],
    };
    final latestBadges = latestDistinctBadges(
      badges,
    ).take(4).toList(growable: false);
    final summary = buildHonorSummary(
      context,
      balance: balance,
      badgeCount: latestDistinctBadges(badges).length,
      member: session?.member,
    );

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        centerTitle: true,
        title: Text(context.l10n.meHonorBadgesTitle),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(memberBadgesProvider);
            ref.invalidate(pointLogsProvider);
            await Future.wait([
              ref.read(memberBadgesProvider.future),
              ref.read(pointLogsProvider.future),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              _HonorProfileHeader(profile: profile),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoPill(
                    icon: Icons.workspace_premium_rounded,
                    text: context.l10n.meHonorBadgeCount(summary.badgeCount),
                    onTap: () => context.push('/me/honors/badges'),
                  ),
                  _InfoPill(
                    icon: Icons.stars_rounded,
                    text: context.l10n.meHonorPointsBalance(summary.balance),
                    onTap: () => context.push('/me/honors/points'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              for (
                var index = 0;
                index < summary.levels.length;
                index += 1
              ) ...[
                _HonorLevelCard(
                  level: summary.levels[index],
                  summary: summary,
                  index: index,
                ),
                const SizedBox(height: 18),
              ],
              _RecentBadgesPanel(
                badges: latestBadges,
                loading: badgesState.isLoading,
                onViewAll: () => context.push('/me/honors/badges'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HonorProfile {
  const _HonorProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.avatarUrl,
  });

  final String name;
  final String age;
  final String gender;
  final String avatarUrl;

  factory _HonorProfile.fromSession(
    AuthSession? session,
    String Function(String value) resolveUrl,
  ) {
    final profile = session?.profile ?? const <String, dynamic>{};
    final member = session?.member ?? const <String, dynamic>{};
    final avatar = _firstText([member['avatar']]);
    return _HonorProfile(
      name: _firstText([
        profile['nickname'],
        profile['display_name'],
        member['nickname'],
        member['username'],
        member['mobile'],
      ], fallback: 'Alexandrina'),
      age: _firstText([profile['age'], member['age']], fallback: '24'),
      gender: normalizeGenderKey(
        _firstText([profile['gender'], member['gender']], fallback: '男'),
      ),
      avatarUrl: avatar.isEmpty ? '' : resolveUrl(avatar),
    );
  }
}

class _HonorProfileHeader extends StatelessWidget {
  const _HonorProfileHeader({required this.profile});

  final _HonorProfile profile;

  @override
  Widget build(BuildContext context) {
    final palette = _HonorPalette.of(context);
    return Row(
      children: [
        _HonorAvatar(avatarUrl: profile.avatarUrl),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${context.l10n.meAgeLabel}  ${profile.age}      ${context.l10n.meGenderLabel}  ${localizedGender(context, profile.gender)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.secondaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => context.push('/me/settings'),
          style: IconButton.styleFrom(
            backgroundColor: palette.cardBackground,
            foregroundColor: palette.primaryText,
            minimumSize: const Size.square(52),
          ),
          icon: const Icon(Icons.settings_rounded),
        ),
      ],
    );
  }
}

class _HonorAvatar extends StatelessWidget {
  const _HonorAvatar({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    final palette = _HonorPalette.of(context);
    if (avatarUrl.trim().isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 56,
          height: 56,
          child: CachedRemoteImage(
            avatarUrl,
            fit: BoxFit.cover,
            placeholder: ColoredBox(color: palette.cardBackground),
            errorWidget: ColoredBox(
              color: palette.cardBackground,
              child: Icon(Icons.person_rounded, color: palette.secondaryText),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: palette.cardBackground,
      child: Icon(
        Icons.person_rounded,
        color: palette.secondaryText.withValues(alpha: 0.78),
        size: 28,
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text, this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _HonorPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF5A81DA)),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: palette.secondaryText,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HonorLevelCard extends StatelessWidget {
  const _HonorLevelCard({
    required this.level,
    required this.summary,
    required this.index,
  });

  final HonorLevelSpec level;
  final HonorSummaryData summary;
  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: level.gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _HonorLevelPainter())),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    honorLevelStatus(context, summary, index),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Lv.${level.level} ${level.title}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    honorPointsLabel(context, level, summary.balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    honorHintText(context, summary, index),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _HonorTrack(
                    progress: honorLevelProgress(summary.balance, level),
                    dotColor: level.progressDotColor,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: _LevelMedal(color: level.medalColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _HonorLevelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    paint.color = Colors.white.withValues(alpha: 0.08);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * -0.26,
        size.width * 1.1,
        size.height * 1.06,
      ),
      paint,
    );
    paint.color = Colors.white.withValues(alpha: 0.07);
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.72, size.height * 0.5),
        radius: size.width * 0.58,
      ),
      math.pi * 0.9,
      math.pi * 0.85,
      false,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    paint.color = Colors.white.withValues(alpha: 0.05);
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.62, size.height * 0.72),
        radius: size.width * 0.62,
      ),
      math.pi * 1.1,
      math.pi * 0.9,
      false,
      paint..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HonorTrack extends StatelessWidget {
  const _HonorTrack({required this.progress, required this.dotColor});

  final double progress;
  final Color dotColor;

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
                  color: Colors.white.withValues(alpha: 0.9),
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
                    color: dotColor,
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

class _LevelMedal extends StatelessWidget {
  const _LevelMedal({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: Container(
              width: 34,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.72),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '★',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentBadgesPanel extends StatelessWidget {
  const _RecentBadgesPanel({
    required this.badges,
    required this.loading,
    required this.onViewAll,
  });

  final List<MemberBadge> badges;
  final bool loading;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final palette = _HonorPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.meHonorRecentBadges,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: Text(context.l10n.meHonorViewAll),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (loading && badges.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (badges.isEmpty)
            Text(
              context.l10n.meHonorNoBadges,
              style: TextStyle(
                color: palette.secondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final badge in badges)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: palette.badgeChipBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          badge.badgeName,
                          style: TextStyle(
                            color: palette.primaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(badge.awardTime),
                          style: TextStyle(
                            color: palette.secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

String _formatDate(String value) {
  final trimmed = value.trim();
  if (trimmed.length >= 10) {
    return trimmed.substring(0, 10);
  }
  return trimmed;
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

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse((value ?? '').toString()) ?? fallback;
}

class _HonorPalette {
  const _HonorPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.badgeChipBackground,
    required this.primaryText,
    required this.secondaryText,
  });

  static _HonorPalette of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _HonorPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      badgeChipBackground: isDark
          ? scheme.surfaceContainerHigh
          : const Color(0xFFF6F8FD),
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color badgeChipBackground;
  final Color primaryText;
  final Color secondaryText;
}
