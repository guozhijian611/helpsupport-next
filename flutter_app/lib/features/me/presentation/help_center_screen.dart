import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/providers/app_providers.dart';
import '../data/help_center_models.dart';
import '../data/help_center_repository.dart';

class HelpCenterScreen extends ConsumerWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _HelpPalette.of(context);
    final categories = ref.watch(helpCategoriesProvider);
    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        title: Text(_t(context, '帮助与反馈', 'Help and feedback')),
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
      ),
      body: SafeArea(
        child: categories.when(
          data: (items) => items.isEmpty
              ? _HelpStateView(
                  text: _t(
                    context,
                    '暂无帮助分类，请先在 saiuser 文章管理中维护分类。',
                    'No help categories yet.',
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    _HelpIntroCard(
                      title: _t(context, '请选择问题分类', 'Choose a topic'),
                      subtitle: _t(
                        context,
                        '分类和文章来自 saiuser 文章管理。',
                        'Categories and articles are managed in saiuser.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final category in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CategoryCard(
                          category: category,
                          onTap: () => context.push(
                            '/me/help/category/${category.id}?name=${Uri.encodeComponent(category.name)}',
                          ),
                        ),
                      ),
                  ],
                ),
          error: (error, _) => _HelpStateView(
            text: _errorText(context, error),
            actionLabel: _t(context, '重试', 'Retry'),
            onAction: () => ref.invalidate(helpCategoriesProvider),
          ),
          loading: () => const _HelpLoadingView(),
        ),
      ),
    );
  }
}

class HelpArticleListScreen extends ConsumerWidget {
  const HelpArticleListScreen({
    required this.categoryId,
    required this.categoryName,
    super.key,
  });

  final int categoryId;
  final String categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _HelpPalette.of(context);
    final query = HelpArticleListQuery(categoryId: categoryId);
    final articles = ref.watch(helpArticleListProvider(query));
    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        title: Text(
          categoryName.isEmpty ? _t(context, '文章列表', 'Articles') : categoryName,
        ),
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
      ),
      body: SafeArea(
        child: articles.when(
          data: (page) => page.list.isEmpty
              ? _HelpStateView(
                  text: _t(
                    context,
                    '该分类下暂无文章，请在 saiuser 文章管理中添加已发布文章。',
                    'No published articles in this category yet.',
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    for (final article in page.list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ArticleCard(
                          article: article,
                          onTap: () => context.push(
                            '/me/help/article/${article.id}',
                            extra: article,
                          ),
                        ),
                      ),
                  ],
                ),
          error: (error, _) => _HelpStateView(
            text: _errorText(context, error),
            actionLabel: _t(context, '重试', 'Retry'),
            onAction: () => ref.invalidate(helpArticleListProvider(query)),
          ),
          loading: () => const _HelpLoadingView(),
        ),
      ),
    );
  }
}

class HelpArticleDetailScreen extends ConsumerWidget {
  const HelpArticleDetailScreen({
    required this.articleId,
    this.initialArticle,
    super.key,
  });

  final int articleId;
  final HelpArticleSummary? initialArticle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _HelpPalette.of(context);
    final article = ref.watch(helpArticleDetailProvider(articleId));
    final title = initialArticle?.title ?? _t(context, '文章详情', 'Article');
    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
      ),
      body: SafeArea(
        child: article.when(
          data: (item) => HelpArticleWebView(article: item),
          error: (error, _) => _HelpStateView(
            text: _errorText(context, error),
            actionLabel: _t(context, '重试', 'Retry'),
            onAction: () =>
                ref.invalidate(helpArticleDetailProvider(articleId)),
          ),
          loading: () => const _HelpLoadingView(),
        ),
      ),
    );
  }
}

class HelpArticleWebView extends ConsumerStatefulWidget {
  const HelpArticleWebView({required this.article, super.key});

  final HelpArticleDetail article;

  @override
  ConsumerState<HelpArticleWebView> createState() => _HelpArticleWebViewState();
}

class _HelpArticleWebViewState extends ConsumerState<HelpArticleWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.startsWith('http://') || url.startsWith('https://')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_loadHtml());
  }

  @override
  void didUpdateWidget(covariant HelpArticleWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.article.id != widget.article.id ||
        oldWidget.article.content != widget.article.content) {
      unawaited(_loadHtml());
    }
  }

  Future<void> _loadHtml() async {
    final apiClient = ref.read(apiClientProvider);
    final html = _buildArticleHtml(
      context: context,
      article: widget.article,
      baseUrl: apiClient.dio.options.baseUrl,
      resolveUrl: apiClient.resolveUrl,
    );
    await _controller.loadHtmlString(html);
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}

class _HelpIntroCard extends StatelessWidget {
  const _HelpIntroCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = _HelpPalette.of(context);
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.support_agent_rounded, color: palette.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.secondaryText,
                      height: 1.35,
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

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final HelpCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _HelpPalette.of(context);
    final theme = Theme.of(context);
    final imageUrl = category.image.isEmpty
        ? ''
        : ref.read(apiClientProvider).resolveUrl(category.image);
    return Material(
      color: palette.cardBackground,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            children: [
              _HelpThumb(
                imageUrl: imageUrl,
                icon: Icons.folder_open_rounded,
                size: 54,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: palette.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (category.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        category.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.secondaryText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: palette.chevron),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleCard extends ConsumerWidget {
  const _ArticleCard({required this.article, required this.onTap});

  final HelpArticleSummary article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _HelpPalette.of(context);
    final theme = Theme.of(context);
    final imageUrl = article.image.isEmpty
        ? ''
        : ref.read(apiClientProvider).resolveUrl(article.image);
    return Material(
      color: palette.cardBackground,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HelpThumb(
                imageUrl: imageUrl,
                icon: Icons.article_outlined,
                size: 74,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: palette.primaryText,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.description.isEmpty
                          ? _t(context, '点击查看详情', 'Tap to read more')
                          : article.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.secondaryText,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        if (article.author.isNotEmpty)
                          _MetaLabel(
                            icon: Icons.person_outline_rounded,
                            text: article.author,
                          ),
                        _MetaLabel(
                          icon: Icons.visibility_outlined,
                          text: _t(
                            context,
                            '${article.views} 次浏览',
                            '${article.views} views',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpThumb extends StatelessWidget {
  const _HelpThumb({
    required this.imageUrl,
    required this.icon,
    required this.size,
  });

  final String imageUrl;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = _HelpPalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl.isEmpty
            ? ColoredBox(
                color: palette.iconBackground,
                child: Icon(icon, color: palette.accent),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: palette.iconBackground,
                  child: Icon(icon, color: palette.accent),
                ),
              ),
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  const _MetaLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = _HelpPalette.of(context);
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: palette.secondaryText),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: palette.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HelpLoadingView extends StatelessWidget {
  const _HelpLoadingView();

  @override
  Widget build(BuildContext context) {
    final palette = _HelpPalette.of(context);
    return Center(child: CircularProgressIndicator(color: palette.accent));
  }
}

class _HelpStateView extends StatelessWidget {
  const _HelpStateView({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = _HelpPalette.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, color: palette.accent, size: 34),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.primaryText,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _HelpPalette {
  const _HelpPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.cardBorder,
    required this.primaryText,
    required this.secondaryText,
    required this.chevron,
    required this.accent,
    required this.iconBackground,
  });

  static _HelpPalette of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    if (isDark) {
      return _HelpPalette(
        pageBackground: scheme.surface,
        cardBackground: scheme.surfaceContainerHigh,
        cardBorder: Colors.white.withValues(alpha: 0.06),
        primaryText: scheme.onSurface,
        secondaryText: scheme.onSurfaceVariant,
        chevron: scheme.onSurfaceVariant.withValues(alpha: 0.72),
        accent: const Color(0xFFFFB4A8),
        iconBackground: scheme.surfaceContainerHighest,
      );
    }
    return const _HelpPalette(
      pageBackground: Color(0xFFF7F7FA),
      cardBackground: Colors.white,
      cardBorder: Colors.white,
      primaryText: Color(0xFF303236),
      secondaryText: Color(0xFFA5A9B0),
      chevron: Color(0xFFB7BCC4),
      accent: Color(0xFFFF8D7F),
      iconBackground: Color(0xFFF1F4F6),
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color cardBorder;
  final Color primaryText;
  final Color secondaryText;
  final Color chevron;
  final Color accent;
  final Color iconBackground;
}

String _buildArticleHtml({
  required BuildContext context,
  required HelpArticleDetail article,
  required String baseUrl,
  required String Function(String value) resolveUrl,
}) {
  final palette = _HelpPalette.of(context);
  final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(0.92, 1.08);
  final imageUrl = article.image.isEmpty ? '' : resolveUrl(article.image);
  final meta = [
    if (article.author.isNotEmpty) article.author,
    if (article.updatedAt.isNotEmpty || article.createdAt.isNotEmpty)
      article.updatedAt.isNotEmpty ? article.updatedAt : article.createdAt,
    _t(context, '${article.views} 次浏览', '${article.views} views'),
  ].join(' · ');
  final content = article.content.trim().isEmpty
      ? '<p>${const HtmlEscape().convert(_t(context, '暂无正文内容', 'No content yet.'))}</p>'
      : article.content;

  return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  ${baseUrl.trim().isEmpty ? '' : '<base href="${const HtmlEscape().convert(baseUrl)}">'}
  <style>
    :root {
      color-scheme: ${Theme.of(context).colorScheme.brightness == Brightness.dark ? 'dark' : 'light'};
      --bg: ${_cssColor(palette.pageBackground)};
      --text: ${_cssColor(palette.primaryText)};
      --sub: ${_cssColor(palette.secondaryText)};
      --accent: ${_cssColor(palette.accent)};
      --card: ${_cssColor(palette.cardBackground)};
      --border: ${_cssColor(palette.cardBorder)};
      font-size: ${16 * textScale}px;
    }
    * { box-sizing: border-box; }
    html, body {
      margin: 0;
      padding: 0;
      background: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", sans-serif;
      line-height: 1.72;
      overflow-wrap: anywhere;
    }
    body { padding: 8px 16px 28px; }
    .article {
      max-width: 760px;
      margin: 0 auto;
    }
    h1 {
      margin: 12px 0 10px;
      font-size: 1.55rem;
      line-height: 1.28;
      letter-spacing: 0;
      font-weight: 800;
    }
    .meta {
      color: var(--sub);
      font-size: .84rem;
      font-weight: 600;
      margin-bottom: 14px;
    }
    .cover {
      width: 100%;
      border-radius: 20px;
      display: block;
      margin: 10px 0 16px;
      background: var(--card);
      border: 1px solid var(--border);
    }
    .summary {
      margin: 0 0 18px;
      padding: 14px 16px;
      border-radius: 18px;
      color: var(--sub);
      background: var(--card);
      border: 1px solid var(--border);
      font-size: .94rem;
      font-weight: 600;
      line-height: 1.55;
    }
    .content {
      font-size: 1rem;
      line-height: 1.78;
    }
    .content p,
    .content div,
    .content section,
    .content article {
      margin: 0 0 1em;
    }
    .content h1,
    .content h2,
    .content h3,
    .content h4 {
      margin: 1.25em 0 .65em;
      line-height: 1.35;
      font-weight: 800;
    }
    .content h2 { font-size: 1.28rem; }
    .content h3 { font-size: 1.15rem; }
    .content img,
    .content video,
    .content iframe {
      max-width: 100%;
      height: auto;
      border-radius: 16px;
    }
    .content video,
    .content iframe {
      width: 100%;
      background: #000;
    }
    .content a {
      color: var(--accent);
      text-decoration: none;
      font-weight: 700;
    }
    .content blockquote {
      margin: 1em 0;
      padding: .8em 1em;
      border-left: 4px solid var(--accent);
      background: var(--card);
      border-radius: 12px;
    }
    .content table {
      width: 100%;
      border-collapse: collapse;
      display: block;
      overflow-x: auto;
    }
    .content th,
    .content td {
      border: 1px solid var(--border);
      padding: .55em .7em;
    }
  </style>
</head>
<body>
  <main class="article">
    <h1>${const HtmlEscape().convert(article.title)}</h1>
    ${meta.isEmpty ? '' : '<div class="meta">${const HtmlEscape().convert(meta)}</div>'}
    ${imageUrl.isEmpty ? '' : '<img class="cover" src="${const HtmlEscape().convert(imageUrl)}" alt="">'}
    ${article.description.isEmpty ? '' : '<p class="summary">${const HtmlEscape().convert(article.description)}</p>'}
    <div class="content">$content</div>
  </main>
</body>
</html>
''';
}

String _cssColor(Color color) {
  final r = (color.r * 255).round();
  final g = (color.g * 255).round();
  final b = (color.b * 255).round();
  final a = color.a;
  return 'rgba($r, $g, $b, ${a.toStringAsFixed(3)})';
}

String _errorText(BuildContext context, Object error) {
  final text = error.toString();
  if (text.contains('message: ')) {
    return text
        .replaceFirst(RegExp(r'^.*message: '), '')
        .replaceFirst(RegExp(r', traceId: .*$'), '');
  }
  return text.isEmpty
      ? _t(context, '加载失败，请稍后重试', 'Load failed. Please try again.')
      : text;
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
