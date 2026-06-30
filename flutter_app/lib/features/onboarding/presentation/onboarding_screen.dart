import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:helpsupport_app/core/cache/cached_remote_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/i18n/language_switcher.dart';
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
      backgroundColor: _onboardingGradientStart,
      body: Stack(
        fit: StackFit.expand,
        children: [
          pages.when(
            data: (items) => items.isEmpty
                ? _OnboardingGradientBackground(
                    child: _EmptyOnboarding(
                      onRetry: () => ref.invalidate(
                        onboardingPagesProvider(
                          OnboardingQuery(locale: locale),
                        ),
                      ),
                    ),
                  )
                : _OnboardingPager(items: items),
            error: (error, stackTrace) => _OnboardingGradientBackground(
              child: _ErrorState(
                message: context.l10n.networkUnavailable,
                onRetry: () => ref.invalidate(
                  onboardingPagesProvider(OnboardingQuery(locale: locale)),
                ),
              ),
            ),
            loading: () => const _OnboardingGradientBackground(
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 14,
            left: 18,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => context.go('/login'),
              child: Text(context.l10n.onboardingSkip),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 14,
            right: 20,
            child: const LanguageSwitcher(onDark: true),
          ),
        ],
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
  void didUpdateWidget(covariant _OnboardingPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _index = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_index];
    final isLast = _index == widget.items.length - 1;
    final scale = _onboardingLayoutScale(context);

    return _OnboardingGradientBackground(
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              return _OnboardingSlide(
                page: widget.items[index],
                variant: _slideVariant(index, widget.items[index]),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 94 * scale,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.items.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 5 * scale),
                  width: 28 * scale,
                  height: 4 * scale,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: i == _index ? 1 : 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2 * scale),
                  ),
                );
              }),
            ),
          ),
          if (isLast)
            Positioned(
              left: 0,
              right: 0,
              bottom: 124 * scale,
              child: Center(
                child: SizedBox(
                  width: 256 * scale,
                  height: 64 * scale,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white, width: 2 * scale),
                      padding: EdgeInsets.symmetric(horizontal: 18 * scale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50 * scale),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () => _handleAction(context, item, isLast),
                    child: Text(
                      item.buttonText.isNotEmpty
                          ? item.buttonText
                          : context.l10n.continueLabel,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _slideVariant(int index, OnboardingPage page) {
    final marker = '${page.actionValue} ${page.title}'.toLowerCase();
    if (index == 0 || page.sort <= 10 || marker.contains('welcome')) {
      return 'cat';
    }
    if (index == 1 || page.sort <= 20 || marker.contains('plan')) {
      return 'dog';
    }
    return 'companion';
  }

  void _goNextOrLogin(BuildContext context, bool isLast) {
    if (isLast) {
      context.go('/login');
      return;
    }
    unawaited(
      _controller.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      ),
    );
  }

  void _handleAction(BuildContext context, OnboardingPage item, bool isLast) {
    switch (item.actionType.trim()) {
      case 'next':
        _goNextOrLogin(context, isLast);
        return;
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
          unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
          return;
        }
        break;
    }

    _goNextOrLogin(context, isLast);
  }
}

class _OnboardingGradientBackground extends StatelessWidget {
  const _OnboardingGradientBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_onboardingGradientStart, _onboardingGradientEnd],
        ),
      ),
      child: child,
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.page, required this.variant});

  final OnboardingPage page;
  final String variant;

  @override
  Widget build(BuildContext context) {
    final scale = _onboardingLayoutScale(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    final copyTop = math.max(78.0, 96 * scale + safeTop * 0.15);
    final imageTop =
        switch (variant) {
          'cat' => 251.0,
          'dog' => 278.5,
          _ => 287.5,
        } *
        scale;
    final imageWidth =
        switch (variant) {
          'cat' => 257.0,
          'dog' => 215.0,
          _ => 254.5,
        } *
        scale;
    final imageHeight =
        switch (variant) {
          'cat' => 342.5,
          'dog' => 308.0,
          _ => 294.5,
        } *
        scale;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: copyTop,
          left: 20 * scale,
          right: 20 * scale,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: math.max(124, imageTop - copyTop - 18 * scale),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12 * scale),
                Text(
                  page.description,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: imageTop,
          left: 0,
          right: 0,
          child: _OnboardingImage(
            source: page.image,
            width: imageWidth,
            height: imageHeight,
          ),
        ),
      ],
    );
  }
}

class _OnboardingImage extends StatelessWidget {
  const _OnboardingImage({
    required this.source,
    required this.width,
    required this.height,
  });

  final String source;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(
      Icons.health_and_safety_outlined,
      color: Colors.white.withValues(alpha: 0.72),
      size: 76,
    );

    return Center(
      child: SizedBox(
        width: width,
        height: height,
        child: source.isEmpty
            ? placeholder
            : CachedRemoteImage(
                source,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes == null
                          ? null
                          : loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => placeholder,
              ),
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
              ),
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

double _onboardingLayoutScale(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final effectiveWidth = math.max(width, 320.0);
  return effectiveWidth / 375.0;
}

const _onboardingGradientStart = Color(0xFFFF9585);
const _onboardingGradientEnd = Color(0xFFFCB08E);
