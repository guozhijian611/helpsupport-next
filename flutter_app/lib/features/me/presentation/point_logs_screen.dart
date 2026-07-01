import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../application/me_content_controller.dart';
import '../data/me_content_models.dart';

class PointLogsScreen extends ConsumerWidget {
  const PointLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _PointLogsPalette.of(context);
    final pointsState = ref.watch(pointLogListProvider);
    final page = switch (pointsState) {
      AsyncData(:final value) => value,
      _ => const PointLogPage(
        list: [],
        total: 0,
        page: 1,
        pageSize: 100,
        balance: 0,
      ),
    };

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        centerTitle: true,
        title: Text(context.l10n.meHonorPointListTitle),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pointLogListProvider);
            await ref.read(pointLogListProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              _PointBalanceCard(balance: page.balance, total: page.total),
              const SizedBox(height: 14),
              if (pointsState.isLoading && page.list.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (page.list.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 120),
                  child: Center(
                    child: Text(
                      context.l10n.meHonorNoPointLogs,
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                for (final item in page.list) ...[
                  _PointLogTile(item: item),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PointBalanceCard extends StatelessWidget {
  const _PointBalanceCard({required this.balance, required this.total});

  final int balance;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = _PointLogsPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9585), Color(0xFFFCB08E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Colors.white, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.meHonorPointsBalance(balance),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.meHonorPointLogTotal(total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.receipt_long_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}

class _PointLogTile extends StatelessWidget {
  const _PointLogTile({required this.item});

  final PointLogItem item;

  @override
  Widget build(BuildContext context) {
    final palette = _PointLogsPalette.of(context);
    final pointsColor = item.isIncome
        ? const Color(0xFFFF9585)
        : const Color(0xFF5A81DA);
    final title = _pointTitle(context, item);
    final subtitle = _pointSubtitle(context, item);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pointsColor.withValues(alpha: 0.12),
              ),
              child: Icon(
                item.isIncome
                    ? Icons.add_circle_rounded
                    : Icons.remove_circle_rounded,
                color: pointsColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
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
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatPoints(item.points),
                  style: TextStyle(
                    color: pointsColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.l10n.meHonorBalanceAfter(item.balanceAfter),
                  style: TextStyle(
                    color: palette.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _pointTitle(BuildContext context, PointLogItem item) {
  final title = item.title.trim();
  if (title.isNotEmpty) {
    return title;
  }
  final type = item.changeType.trim();
  if (type.isNotEmpty) {
    return type;
  }
  return context.l10n.meHonorPointChange;
}

String _pointSubtitle(BuildContext context, PointLogItem item) {
  final parts = <String>[];
  final date = _formatDateTime(item.createTime);
  if (date.isNotEmpty) {
    parts.add(date);
  }
  final remark = item.remark.trim();
  if (remark.isNotEmpty) {
    parts.add(remark);
  }
  final sourceType = item.sourceType.trim();
  if (sourceType.isNotEmpty) {
    parts.add(context.l10n.meHonorPointSource(sourceType));
  }
  return parts.join(' · ');
}

String _formatPoints(int points) {
  if (points > 0) {
    return '+$points';
  }
  return '$points';
}

String _formatDateTime(String value) {
  final trimmed = value.trim();
  if (trimmed.length >= 16) {
    return trimmed.substring(0, 16);
  }
  return trimmed;
}

class _PointLogsPalette {
  const _PointLogsPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.borderColor,
    required this.primaryText,
    required this.secondaryText,
  });

  static _PointLogsPalette of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _PointLogsPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFECE7E4),
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color borderColor;
  final Color primaryText;
  final Color secondaryText;
}
