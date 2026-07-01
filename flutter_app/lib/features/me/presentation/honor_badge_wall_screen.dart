import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/cached_remote_image.dart';
import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/providers/app_providers.dart';
import '../application/me_content_controller.dart';
import '../data/me_content_models.dart';
import 'honor_badges_support.dart';

class HonorBadgeWallScreen extends ConsumerWidget {
  const HonorBadgeWallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _BadgeWallPalette.of(context);
    final apiClient = ref.watch(apiClientProvider);
    final badgesState = ref.watch(memberBadgeWallProvider);
    final badges = switch (badgesState) {
      AsyncData(:final value) => latestDistinctBadges(value.list),
      _ => const <MemberBadge>[],
    };

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        centerTitle: true,
        title: Text(context.l10n.meHonorBadgeWallTitle),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(memberBadgeWallProvider);
            await ref.read(memberBadgeWallProvider.future);
          },
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: _BadgeWallSummary(count: badges.length),
                ),
              ),
              if (badgesState.isLoading && badges.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (badges.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      context.l10n.meHonorNoBadges,
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _BadgeWallCard(
                        badge: badges[index],
                        resolveUrl: apiClient.resolveUrl,
                      );
                    }, childCount: badges.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeWallSummary extends StatelessWidget {
  const _BadgeWallSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = _BadgeWallPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9585), Color(0xFFFFC59A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.meHonorBadgeWallTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.meHonorBadgeCount(count),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.secondaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

class _BadgeWallCard extends StatelessWidget {
  const _BadgeWallCard({required this.badge, required this.resolveUrl});

  final MemberBadge badge;
  final String Function(String value) resolveUrl;

  @override
  Widget build(BuildContext context) {
    final palette = _BadgeWallPalette.of(context);
    final ruleText = _badgeRuleText(context, badge);
    final iconUrl = badge.badgeIcon.trim().isEmpty
        ? ''
        : resolveUrl(badge.badgeIcon);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BadgeIcon(iconUrl: iconUrl),
            const SizedBox(height: 14),
            Text(
              badge.badgeName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
            if (ruleText.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                ruleText,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              context.l10n.meHonorBadgeAwardedAt(_formatDate(badge.awardTime)),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.iconUrl});

  final String iconUrl;

  @override
  Widget build(BuildContext context) {
    final palette = _BadgeWallPalette.of(context);
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.medalBackground,
        border: Border.all(
          color: const Color(0xFFFF9585).withValues(alpha: 0.42),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: iconUrl.trim().isEmpty
            ? const Icon(
                Icons.military_tech_rounded,
                color: Color(0xFFFF9585),
                size: 38,
              )
            : CachedRemoteImage(
                iconUrl,
                fit: BoxFit.cover,
                placeholder: ColoredBox(color: palette.medalBackground),
                errorWidget: const Icon(
                  Icons.military_tech_rounded,
                  color: Color(0xFFFF9585),
                  size: 38,
                ),
              ),
      ),
    );
  }
}

String _badgeRuleText(BuildContext context, MemberBadge badge) {
  final description = badge.badgeDescription.trim();
  if (description.isNotEmpty) {
    return description;
  }
  final value = badge.ruleTriggerValue;
  return switch (badge.ruleTriggerType) {
    'task_count' => context.l10n.meHonorRuleTaskCount(value),
    'checkin_streak' => context.l10n.meHonorRuleCheckinStreak(value),
    'journal_count' => context.l10n.meHonorRuleJournalCount(value),
    'material_learn' => context.l10n.meHonorRuleMaterialLearn(value),
    'appointment_done' => context.l10n.meHonorRuleAppointmentDone(value),
    'manual' => context.l10n.meHonorRuleManual,
    _ => '',
  };
}

String _formatDate(String value) {
  final trimmed = value.trim();
  if (trimmed.length >= 10) {
    return trimmed.substring(0, 10);
  }
  return trimmed;
}

class _BadgeWallPalette {
  const _BadgeWallPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.medalBackground,
    required this.borderColor,
    required this.primaryText,
    required this.secondaryText,
  });

  static _BadgeWallPalette of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _BadgeWallPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      medalBackground: isDark
          ? const Color(0xFF3B2A2A)
          : const Color(0xFFFFF0EC),
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFECE7E4),
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color medalBackground;
  final Color borderColor;
  final Color primaryText;
  final Color secondaryText;
}
