import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../auth/application/auth_controller.dart';
import '../../community/presentation/community_feed_screen.dart';
import '../../plan/presentation/plan_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

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

    final isLoggingOut = ref.watch(authControllerProvider).isLoading;
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
    final current = destinations[_index];
    final body = switch (_index) {
      1 => const CommunityFeedScreen(),
      2 => const PlanScreen(),
      _ => _HomePanel(
        icon: current.icon,
        title: current.label,
        subtitle: context.l10n.homeGreeting,
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0 ? context.l10n.homeTitle : current.label),
        actions: [
          IconButton(
            tooltip: context.l10n.chatTitle,
            onPressed: () => context.push('/chat'),
            icon: const Icon(Icons.auto_awesome_outlined),
          ),
          IconButton(
            tooltip: context.l10n.localModelTitle,
            onPressed: () => context.push('/local-model'),
            icon: const Icon(Icons.memory_outlined),
          ),
          IconButton(
            tooltip: context.l10n.logout,
            onPressed: isLoggingOut
                ? null
                : ref.read(authControllerProvider.notifier).logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(child: body),
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

  static const _barColor = Color(0xFFDADCE1);
  static const _activeColor = Color(0xFFFF9585);
  static const _inactiveColor = Colors.white;

  final List<_HomeDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(22, 8, 22, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _barColor,
          borderRadius: BorderRadius.circular(42),
        ),
        child: SizedBox(
          height: 86,
          child: Row(
            children: [
              for (var index = 0; index < destinations.length; index += 1)
                Expanded(
                  child: _FloatingHomeTabItem(
                    destination: destinations[index],
                    selected: index == selectedIndex,
                    activeColor: _activeColor,
                    inactiveColor: _inactiveColor,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
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

class _HomePanel extends StatelessWidget {
  const _HomePanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: scheme.primary),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
