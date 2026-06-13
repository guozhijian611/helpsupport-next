import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    final isLoggingOut = ref.watch(authControllerProvider).isLoading;
    final destinations = [
      _HomeDestination(
        label: context.l10n.patient,
        icon: Icons.favorite_border,
      ),
      _HomeDestination(
        label: context.l10n.plan,
        icon: Icons.event_available_outlined,
      ),
      _HomeDestination(
        label: context.l10n.community,
        icon: Icons.forum_outlined,
      ),
      _HomeDestination(
        label: context.l10n.notifications,
        icon: Icons.notifications_none,
      ),
      _HomeDestination(label: context.l10n.me, icon: Icons.person_outline),
    ];
    final current = destinations[_index];
    final body = switch (_index) {
      1 => const PlanScreen(),
      2 => const CommunityFeedScreen(),
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
      floatingActionButton: _index == 2
          ? FloatingActionButton(
              tooltip: context.l10n.communityNewPost,
              onPressed: () => context.push('/community/new'),
              child: const Icon(Icons.edit_outlined),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _HomeDestination {
  const _HomeDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
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
