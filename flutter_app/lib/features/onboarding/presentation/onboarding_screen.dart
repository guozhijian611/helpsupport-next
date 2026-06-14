import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../application/onboarding_controller.dart';
import '../data/onboarding_models.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final pages = ref.watch(
      onboardingPagesProvider(OnboardingQuery(locale: locale)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.onboardingTitle)),
      body: SafeArea(
        child: pages.when(
          data: (items) => items.isEmpty
              ? _EmptyOnboarding(
                  onRetry: () => ref.invalidate(
                    onboardingPagesProvider(OnboardingQuery(locale: locale)),
                  ),
                )
              : _OnboardingPager(items: items),
          error: (error, stackTrace) => _ErrorState(
            message: context.l10n.networkUnavailable,
            onRetry: () => ref.invalidate(
              onboardingPagesProvider(OnboardingQuery(locale: locale)),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _OnboardingPager extends StatefulWidget {
  const _OnboardingPager({required this.items});

  final List<OnboardingPage> items;

  @override
  State<_OnboardingPager> createState() => _OnboardingPagerState();
}

class _OnboardingPagerState extends State<_OnboardingPager> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_index];
    final isLast = _index == widget.items.length - 1;

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              return _OnboardingPageCard(page: widget.items[index]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.items.length; i++)
                    AnimatedContainer(
                      width: i == _index ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: i == _index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _handleAction(context, item, isLast),
                child: Text(
                  item.buttonText.isNotEmpty
                      ? item.buttonText
                      : context.l10n.continueLabel,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    OnboardingPage item,
    bool isLast,
  ) async {
    switch (item.actionType.trim()) {
      case 'skip':
        context.go('/login');
        return;
      case 'route':
        final route = item.actionValue.trim();
        if (route.isNotEmpty) {
          context.go(route.startsWith('/') ? route : '/$route');
          return;
        }
        break;
      case 'external_url':
        final uri = Uri.tryParse(item.actionValue.trim());
        if (uri != null && uri.hasScheme) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
        break;
    }

    if (isLast) {
      context.go('/login');
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}

class _OnboardingPageCard extends StatelessWidget {
  const _OnboardingPageCard({required this.page});

  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: page.image.isEmpty
                  ? Icon(
                      Icons.health_and_safety_outlined,
                      size: 96,
                      color: scheme.onPrimaryContainer,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        page.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.broken_image_outlined,
                            size: 80,
                            color: scheme.onPrimaryContainer,
                          );
                        },
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptyOnboarding extends StatelessWidget {
  const _EmptyOnboarding({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _ErrorState(message: context.l10n.onboardingEmpty, onRetry: onRetry);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}
