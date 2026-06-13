import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.homeTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.localModelTitle,
            onPressed: () => context.push('/local-model'),
            icon: const Icon(Icons.memory_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _HomePanel(
          icon: current.icon,
          title: current.label,
          subtitle: context.l10n.homeGreeting,
        ),
      ),
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
