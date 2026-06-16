import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../application/material_controller.dart';
import '../data/material_models.dart';

class MaterialResourceScreen extends ConsumerStatefulWidget {
  const MaterialResourceScreen({
    super.key,
    required this.materialId,
    this.initialItem,
  });

  final int materialId;
  final MaterialItem? initialItem;

  @override
  ConsumerState<MaterialResourceScreen> createState() =>
      _MaterialResourceScreenState();
}

class _MaterialResourceScreenState
    extends ConsumerState<MaterialResourceScreen> {
  final _scrollController = ScrollController();

  WebViewController? _webViewController;
  MaterialItem? _activeItem;
  String _activeCacheKey = '';
  String _textContent = '';
  String _cachePath = '';
  double _cacheProgress = 0;
  double _readingProgress = 0;
  bool _isCaching = false;
  bool _isLoadingText = false;
  DateTime _openedAt = DateTime.now();
  DateTime _lastSavedAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleTextScroll);
  }

  @override
  void dispose() {
    unawaited(_saveProgress(force: true));
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final query = MaterialDetailQuery(id: widget.materialId, locale: locale);
    final detail = ref.watch(materialDetailProvider(query));
    final fallback = widget.initialItem;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _activeItem?.title ??
              fallback?.title ??
              _t(context, '素材资源', 'Material Resource'),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: detail.when(
          data: (item) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _configureResource(item);
            });
            return _ResourceScaffold(
              cachePath: _cachePath,
              cacheProgress: _cacheProgress,
              isCaching: _isCaching,
              child: _resourceBody(item),
            );
          },
          error: (error, _) {
            if (fallback == null) {
              return Center(child: Text(error.toString()));
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _configureResource(fallback);
            });
            return _ResourceScaffold(
              cachePath: _cachePath,
              cacheProgress: _cacheProgress,
              isCaching: _isCaching,
              child: _resourceBody(fallback),
            );
          },
          loading: () => fallback == null
              ? const Center(child: CircularProgressIndicator())
              : _ResourceScaffold(
                  cachePath: _cachePath,
                  cacheProgress: _cacheProgress,
                  isCaching: _isCaching,
                  child: _resourceBody(fallback),
                ),
        ),
      ),
    );
  }

  Widget _resourceBody(MaterialItem item) {
    if (_isTextLike(item)) {
      if (_isLoadingText) {
        return const Center(child: CircularProgressIndicator());
      }
      final content = _textContent.trim().isNotEmpty
          ? _textContent
          : item.contentText;
      if (content.trim().isEmpty) {
        return _CenteredResourceMessage(
          text: _t(context, '暂无可阅读内容', 'No readable content'),
        );
      }
      return SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 36),
        child: SelectableText(
          content,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 17,
            height: 1.8,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final controller = _webViewController;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return WebViewWidget(controller: controller);
  }

  Future<void> _configureResource(MaterialItem item) async {
    final apiClient = ref.read(apiClientProvider);
    final resourceUrl = apiClient.resolveUrl(item.contentUrl);
    final cacheKey = '${item.id}:${item.mediaType}:$resourceUrl';
    if (_activeCacheKey == cacheKey) {
      return;
    }

    _activeCacheKey = cacheKey;
    _activeItem = item;
    _openedAt = DateTime.now();
    _readingProgress = item.historyProgress.clamp(0, 100).toDouble();
    _textContent = item.contentText;
    _cachePath = '';
    _cacheProgress = 0;
    _isCaching = false;
    _isLoadingText = false;

    if (resourceUrl.trim().isEmpty) {
      if (mounted) {
        setState(() {});
      }
      _restoreTextScroll();
      return;
    }

    final localFile = await _cacheFileFor(item, resourceUrl);
    final hasCachedFile = await localFile.exists();
    if (hasCachedFile) {
      _cachePath = localFile.path;
      _cacheProgress = 100;
    }

    if (_isTextLike(item)) {
      await _loadTextResource(item, resourceUrl, localFile, hasCachedFile);
      return;
    }

    _webViewController = _buildWebViewController(item);
    if (_isMediaResource(item)) {
      final source = hasCachedFile
          ? Uri.file(localFile.path).toString()
          : resourceUrl;
      await _webViewController!.loadHtmlString(_mediaHtml(item, source));
    } else if (hasCachedFile && item.mediaType != 'link') {
      await _webViewController!.loadFile(localFile.path);
    } else {
      final uri = Uri.tryParse(resourceUrl);
      if (uri == null || !uri.hasScheme) {
        if (mounted) {
          context.showCenteredNotice(
            _t(context, '资源地址无效', 'Invalid resource URL'),
          );
        }
      } else {
        await _webViewController!.loadRequest(uri);
      }
    }

    if (mounted) {
      setState(() {});
    }
    if (!hasCachedFile && item.mediaType != 'link') {
      unawaited(_cacheRemoteFile(resourceUrl, localFile));
    }
  }

  WebViewController _buildWebViewController(MaterialItem item) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'MaterialProgress',
        onMessageReceived: _handleProgressMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!_isMediaResource(item)) {
              unawaited(_injectScrollProgressTracker());
            }
          },
          onWebResourceError: (_) {
            if (mounted) {
              context.showCenteredNotice(
                _t(context, '资源加载失败', 'Resource load failed'),
              );
            }
          },
        ),
      );
  }

  Future<void> _loadTextResource(
    MaterialItem item,
    String resourceUrl,
    File localFile,
    bool hasCachedFile,
  ) async {
    if (mounted) {
      setState(() => _isLoadingText = true);
    }
    try {
      if (!hasCachedFile) {
        await _cacheRemoteFile(resourceUrl, localFile);
      }
      final content = await localFile.readAsString();
      if (!mounted || _activeItem?.id != item.id) {
        return;
      }
      setState(() {
        _textContent = content;
        _cachePath = localFile.path;
        _cacheProgress = 100;
      });
      _restoreTextScroll();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      if (item.contentText.trim().isEmpty) {
        context.showCenteredNotice(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingText = false);
      }
    }
  }

  Future<void> _cacheRemoteFile(String resourceUrl, File localFile) async {
    final uri = Uri.tryParse(resourceUrl);
    if (uri == null || !uri.hasScheme) {
      return;
    }
    await localFile.parent.create(recursive: true);
    if (mounted) {
      setState(() {
        _isCaching = true;
        _cacheProgress = 0;
      });
    }
    try {
      await ref
          .read(apiClientProvider)
          .dio
          .download(
            resourceUrl,
            localFile.path,
            onReceiveProgress: (received, total) {
              if (!mounted || total <= 0) {
                return;
              }
              setState(() => _cacheProgress = received * 100 / total);
            },
          );
      if (mounted) {
        setState(() {
          _cachePath = localFile.path;
          _cacheProgress = 100;
        });
      }
    } on DioException {
      if (await localFile.exists()) {
        await localFile.delete();
      }
    } finally {
      if (mounted) {
        setState(() => _isCaching = false);
      }
    }
  }

  Future<File> _cacheFileFor(MaterialItem item, String resourceUrl) async {
    final dir = await getApplicationDocumentsDirectory();
    final extension = _resourceExtension(item, resourceUrl);
    return File('${dir.path}/material_cache/${item.id}_$extension.$extension');
  }

  String _resourceExtension(MaterialItem item, String resourceUrl) {
    final type = item.mediaType.trim().toLowerCase();
    if (type.isNotEmpty && type != 'article' && type != 'link') {
      return type;
    }
    final uri = Uri.tryParse(resourceUrl);
    final path = uri?.path ?? '';
    final dot = path.lastIndexOf('.');
    if (dot >= 0 && dot < path.length - 1) {
      return path.substring(dot + 1).toLowerCase();
    }
    return 'html';
  }

  Future<void> _injectScrollProgressTracker() async {
    final controller = _webViewController;
    if (controller == null) {
      return;
    }
    await controller.runJavaScript('''
      (function() {
        if (window.__materialProgressInstalled) return;
        window.__materialProgressInstalled = true;
        function report() {
          var body = document.body || {};
          var root = document.documentElement || {};
          var scrollTop = window.pageYOffset || root.scrollTop || body.scrollTop || 0;
          var height = Math.max(root.scrollHeight || 0, body.scrollHeight || 0);
          var viewport = window.innerHeight || root.clientHeight || 1;
          var max = Math.max(1, height - viewport);
          var progress = Math.max(0, Math.min(100, scrollTop / max * 100));
          MaterialProgress.postMessage(JSON.stringify({progress: progress, duration: 0}));
        }
        window.addEventListener('scroll', report, {passive: true});
        setInterval(report, 5000);
        setTimeout(report, 500);
      })();
    ''');
  }

  void _handleProgressMessage(JavaScriptMessage message) {
    final Object? decoded;
    try {
      decoded = jsonDecode(message.message);
    } on FormatException {
      return;
    }
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    final progress = (decoded['progress'] is num)
        ? (decoded['progress'] as num).toDouble()
        : double.tryParse('${decoded['progress']}') ?? 0;
    final duration = (decoded['duration'] is num)
        ? (decoded['duration'] as num).round()
        : int.tryParse('${decoded['duration']}') ?? 0;
    _readingProgress = progress.clamp(0, 100).toDouble();
    unawaited(_saveProgress(durationSeconds: duration));
  }

  void _handleTextScroll() {
    if (!_scrollController.hasClients || !_isTextLike(_activeItem)) {
      return;
    }
    final maxExtent = _scrollController.position.maxScrollExtent;
    final progress = maxExtent <= 0
        ? 100.0
        : (_scrollController.offset / maxExtent * 100).clamp(0, 100).toDouble();
    _readingProgress = progress;
    unawaited(_saveProgress());
  }

  void _restoreTextScroll() {
    if (_readingProgress <= 0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent <= 0) {
        return;
      }
      _scrollController.jumpTo(maxExtent * (_readingProgress / 100));
    });
  }

  Future<void> _saveProgress({
    bool force = false,
    int durationSeconds = 0,
  }) async {
    final item = _activeItem;
    if (item == null) {
      return;
    }
    final now = DateTime.now();
    if (!force && now.difference(_lastSavedAt).inSeconds < 5) {
      return;
    }
    _lastSavedAt = now;
    final elapsedSeconds = durationSeconds > 0
        ? durationSeconds
        : now.difference(_openedAt).inSeconds;
    await ref
        .read(materialRepositoryProvider)
        .saveHistory(
          materialId: item.id,
          title: item.title,
          route: '/materials/resource/${item.id}',
          progress: _readingProgress,
          durationSeconds: elapsedSeconds,
        );
  }

  String _mediaHtml(MaterialItem item, String source) {
    final isAudio = item.mediaType == 'audio' || item.mediaType == 'mp3';
    final tag = isAudio ? 'audio' : 'video';
    final title = jsonEncode(item.title);
    final src = jsonEncode(source);
    final startProgress = item.historyProgress.clamp(0, 100).toStringAsFixed(2);
    return '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
  <style>
    html, body { margin: 0; height: 100%; background: #111; color: #fff; font-family: -apple-system, BlinkMacSystemFont, sans-serif; }
    body { display: flex; align-items: center; justify-content: center; }
    .wrap { width: 100%; padding: 24px; box-sizing: border-box; }
    h1 { font-size: 20px; line-height: 1.35; margin: 0 0 24px; text-align: center; }
    video { width: 100%; max-height: 76vh; border-radius: 12px; background: #000; }
    audio { width: 100%; }
  </style>
</head>
<body>
  <div class="wrap">
    <h1 id="title"></h1>
    <$tag id="player" controls playsinline preload="metadata"></$tag>
  </div>
  <script>
    const player = document.getElementById('player');
    document.getElementById('title').textContent = $title;
    player.src = $src;
    const startProgress = Number($startProgress);
    let restored = false;
    function report() {
      const duration = Number.isFinite(player.duration) ? player.duration : 0;
      const current = Number.isFinite(player.currentTime) ? player.currentTime : 0;
      const progress = duration > 0 ? Math.max(0, Math.min(100, current / duration * 100)) : 0;
      MaterialProgress.postMessage(JSON.stringify({
        progress: progress,
        duration: Math.round(current)
      }));
    }
    player.addEventListener('loadedmetadata', function() {
      if (!restored && startProgress > 0 && Number.isFinite(player.duration) && player.duration > 0) {
        restored = true;
        player.currentTime = player.duration * startProgress / 100;
      }
      report();
    });
    player.addEventListener('timeupdate', report);
    player.addEventListener('pause', report);
    player.addEventListener('ended', function() {
      MaterialProgress.postMessage(JSON.stringify({progress: 100, duration: Math.round(player.duration || 0)}));
    });
    setInterval(report, 5000);
  </script>
</body>
</html>
''';
  }

  bool _isTextLike(MaterialItem? item) {
    if (item == null) {
      return false;
    }
    return item.mediaType == 'article' || item.mediaType == 'txt';
  }

  bool _isMediaResource(MaterialItem item) {
    return item.mediaType == 'video' ||
        item.mediaType == 'mp4' ||
        item.mediaType == 'mov' ||
        item.mediaType == 'audio' ||
        item.mediaType == 'mp3';
  }
}

class _ResourceScaffold extends StatelessWidget {
  const _ResourceScaffold({
    required this.cachePath,
    required this.cacheProgress,
    required this.isCaching,
    required this.child,
  });

  final String cachePath;
  final double cacheProgress;
  final bool isCaching;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isCaching || cachePath.isNotEmpty)
          _CacheStatusBar(
            progress: cacheProgress,
            cached: cachePath.isNotEmpty && !isCaching,
          ),
        Expanded(child: child),
      ],
    );
  }
}

class _CacheStatusBar extends StatelessWidget {
  const _CacheStatusBar({required this.progress, required this.cached});

  final double progress;
  final bool cached;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      color: scheme.surfaceContainerLow,
      child: Row(
        children: [
          Icon(
            cached ? Icons.offline_pin_rounded : Icons.cloud_download_outlined,
            size: 18,
            color: const Color(0xFFFF9585),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cached
                  ? _t(context, '已支持离线查看', 'Available offline')
                  : _t(
                      context,
                      '正在缓存 ${progress.clamp(0, 100).toStringAsFixed(0)}%',
                      'Caching ${progress.clamp(0, 100).toStringAsFixed(0)}%',
                    ),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredResourceMessage extends StatelessWidget {
  const _CenteredResourceMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
