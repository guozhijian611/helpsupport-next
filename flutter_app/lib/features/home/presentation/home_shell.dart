import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../auth/application/auth_controller.dart';
import '../../community/presentation/community_feed_screen.dart';
import '../../me/presentation/me_screen.dart';
import '../../plan/presentation/plan_screen.dart';
import 'home_dashboard_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 3);
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = widget.initialIndex.clamp(0, 3);
    if (widget.initialIndex != oldWidget.initialIndex && nextIndex != _index) {
      _index = nextIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      final wasAuthenticated = switch (previous) {
        AsyncData(:final value) => value != null,
        _ => false,
      };
      if (wasAuthenticated && next.hasValue && next.value == null) {
        context.go('/login');
      }
      if (next.hasError) {
        context.showCenteredNotice(next.error.toString());
      }
    });

    final destinations = [
      _HomeDestination(
        label: context.l10n.homeTab,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
      ),
      _HomeDestination(
        label: context.l10n.community,
        icon: Icons.public_outlined,
        selectedIcon: Icons.public_rounded,
      ),
      _HomeDestination(
        label: context.l10n.plan,
        icon: Icons.article_outlined,
        selectedIcon: Icons.article_rounded,
      ),
      _HomeDestination(
        label: context.l10n.me,
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
      ),
    ];
    final body = switch (_index) {
      1 => const CommunityFeedScreen(),
      2 => const PlanScreen(),
      3 => const MeScreen(),
      _ => const HomeDashboardScreen(),
    };

    return Scaffold(
      extendBody: true,
      body: SafeArea(top: true, bottom: false, child: body),
      floatingActionButton: _index == 1
          ? FloatingActionButton(
              tooltip: context.l10n.communityNewPost,
              onPressed: () => context.push('/community/new'),
              child: const Icon(Icons.edit_outlined),
            )
          : null,
      bottomNavigationBar: _FloatingHomeTabBar(
        destinations: destinations,
        selectedIndex: _index,
        onSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _HomeDestination {
  const _HomeDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _FloatingHomeTabBar extends StatelessWidget {
  const _FloatingHomeTabBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _lightBarColor = Color(0xFFDADCE1);
  static const _lightActiveColor = Color(0xFFFF9585);
  static const _darkActiveColor = Color(0xFFFFB4A8);

  final List<_HomeDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final barColor = (isDark ? scheme.surfaceContainerHighest : _lightBarColor)
        .withValues(alpha: isDark ? 0.72 : 0.68);
    final activeColor = isDark ? _darkActiveColor : _lightActiveColor;
    final inactiveColor = isDark
        ? scheme.onSurfaceVariant.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.96);
    final borderColor = isDark
        ? scheme.outline.withValues(alpha: 0.26)
        : Colors.white.withValues(alpha: 0.62);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.18)
        : const Color(0x1A6E707A);
    final borderRadius = BorderRadius.circular(42);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(22, 8, 22, 12),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: borderRadius,
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                height: 86,
                child: Row(
                  children: [
                    for (var index = 0; index < destinations.length; index += 1)
                      Expanded(
                        child: _FloatingHomeTabItem(
                          destination: destinations[index],
                          selected: index == selectedIndex,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          onTap: () => onSelected(index),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingHomeTabItem extends StatelessWidget {
  const _FloatingHomeTabItem({
    required this.destination,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final _HomeDestination destination;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 6),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
