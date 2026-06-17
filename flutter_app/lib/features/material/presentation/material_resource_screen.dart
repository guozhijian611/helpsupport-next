import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart' hide MaterialPage;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:xml/xml.dart';

import '../../../core/api/api_client.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../application/material_controller.dart';
import '../data/material_models.dart';
import '../data/material_repository.dart';

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

  late final ApiClient _apiClient;
  late final MaterialRepository _materialRepository;
  WebViewController? _webViewController;
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  Uri? _pdfUri;
  StreamSubscription<Duration>? _audioPositionSubscription;
  StreamSubscription<PlayerState>? _audioStateSubscription;
  MaterialItem? _activeItem;
  String _activeCacheKey = '';
  String _textContent = '';
  String _lyricContent = '';
  String _cachePath = '';
  String _activeResourceUrl = '';
  String _resourceError = '';
  double _cacheProgress = 0;
  double _readingProgress = 0;
  bool _isCaching = false;
  bool _isLoadingText = false;
  bool _isPreparingResource = false;
  DateTime _openedAt = DateTime.now();
  DateTime _lastSavedAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _apiClient = ref.read(apiClientProvider);
    _materialRepository = ref.read(materialRepositoryProvider);
    _scrollController.addListener(_handleTextScroll);
  }

  @override
  void dispose() {
    unawaited(_saveProgress(force: true));
    unawaited(_disposePlaybackControllers());
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
              canCache: _canCacheActiveResource,
              onCache: _cacheActiveResource,
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
              canCache: _canCacheActiveResource,
              onCache: _cacheActiveResource,
              child: _resourceBody(fallback),
            );
          },
          loading: () => fallback == null
              ? const Center(child: CircularProgressIndicator())
              : _ResourceScaffold(
                  cachePath: _cachePath,
                  cacheProgress: _cacheProgress,
                  isCaching: _isCaching,
                  canCache: _canCacheActiveResource,
                  onCache: _cacheActiveResource,
                  child: _resourceBody(fallback),
                ),
        ),
      ),
    );
  }

  Widget _resourceBody(MaterialItem item) {
    if (_resourceError.trim().isNotEmpty) {
      return _CenteredResourceMessage(text: _resourceError);
    }

    if (_isBookReader(item)) {
      if (_isLoadingText) {
        return _ResourceLoading(
          text: _t(context, '正在准备阅读内容', 'Preparing reader'),
        );
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

    if (_isPdfResource(item)) {
      final pdfUri = _pdfUri;
      if (_isPreparingResource ||
          (_cachePath.trim().isEmpty && pdfUri == null)) {
        return _ResourceLoading(
          text: _t(context, '正在准备 PDF 阅读器', 'Preparing PDF reader'),
        );
      }
      if (_cachePath.trim().isNotEmpty) {
        return PdfViewer.file(_cachePath);
      }
      return PdfViewer.uri(pdfUri!);
    }

    if (_isVideoResource(item)) {
      final controller = _videoController;
      if (_isPreparingResource ||
          controller == null ||
          !controller.value.isInitialized) {
        return _ResourceLoading(
          text: _t(context, '正在准备视频播放器', 'Preparing video player'),
        );
      }
      return _VideoPlayerPanel(controller: controller, item: item);
    }

    if (_isAudioResource(item)) {
      final player = _audioPlayer;
      if (_isPreparingResource || player == null) {
        return _ResourceLoading(
          text: _t(context, '正在准备音乐播放器', 'Preparing music player'),
        );
      }
      final coverUrl = _apiClient.resolveUrl(item.coverUrl);
      final playlist = ref.watch(
        materialListProvider(
          MaterialListQuery(
            materialType: item.materialType,
            categoryId: item.categoryId,
            keyword: '',
            locale: Localizations.localeOf(context).toLanguageTag(),
            pageSize: 50,
          ),
        ),
      );
      return _AudioPlayerPanel(
        player: player,
        item: item,
        coverUrl: coverUrl,
        lyrics: _lyricContent.trim().isNotEmpty
            ? _lyricContent
            : item.contentText,
        playlist: playlist,
        onOpenTrack: (track) {
          context.push('/materials/resource/${track.id}', extra: track);
        },
      );
    }

    final webController = _webViewController;
    if (webController == null) {
      return _ResourceLoading(text: _t(context, '正在打开游戏', 'Opening game'));
    }
    return WebViewWidget(controller: webController);
  }

  Future<void> _configureResource(MaterialItem item) async {
    final resourceUrl = _apiClient.resolveUrl(item.contentUrl);
    final cacheKey =
        '${item.id}:${item.mediaType}:$resourceUrl:${item.lyricUrl.hashCode}:${item.contentText.hashCode}';
    if (_activeCacheKey == cacheKey) {
      return;
    }

    await _saveProgress(force: true);
    await _disposePlaybackControllers();

    _activeCacheKey = cacheKey;
    _activeItem = item;
    _activeResourceUrl = resourceUrl;
    _openedAt = DateTime.now();
    _readingProgress = item.historyProgress.clamp(0, 100).toDouble();
    _textContent = item.contentText;
    _lyricContent = '';
    _cachePath = '';
    _pdfUri = null;
    _resourceError = '';
    _cacheProgress = 0;
    _isCaching = false;
    _isLoadingText = false;
    _isPreparingResource = false;
    _webViewController = null;

    if (mounted) {
      setState(() {});
    }

    try {
      if (_isBookReader(item)) {
        await _prepareBookResource(item, resourceUrl);
      } else if (_isPdfResource(item)) {
        await _preparePdfResource(item, resourceUrl);
      } else if (_isVideoResource(item)) {
        await _prepareVideoResource(item, resourceUrl);
      } else if (_isAudioResource(item)) {
        await _prepareAudioResource(item, resourceUrl);
      } else {
        await _prepareWebResource(resourceUrl);
      }
    } on Object catch (error) {
      if (!mounted || _activeCacheKey != cacheKey) {
        return;
      }
      setState(() {
        _resourceError = error.toString();
        _isLoadingText = false;
        _isPreparingResource = false;
      });
    }
  }

  Future<void> _prepareBookResource(
    MaterialItem item,
    String resourceUrl,
  ) async {
    if (mounted) {
      setState(() {
        _isLoadingText = true;
        _isPreparingResource = true;
      });
    }
    var content = item.contentText;
    if (resourceUrl.trim().isNotEmpty) {
      final localFile = await _cacheFileFor(item, resourceUrl);
      final hasCachedFile = await localFile.exists();
      if (hasCachedFile && mounted) {
        setState(() {
          _cachePath = localFile.path;
          _cacheProgress = 100;
        });
      }
      if (hasCachedFile) {
        content = _isEpubResource(item)
            ? await _loadEpubResource(localFile)
            : await _loadPlainTextResource(localFile);
      } else {
        content = _isEpubResource(item)
            ? await _loadRemoteEpubResource(resourceUrl)
            : await _loadRemotePlainTextResource(resourceUrl);
      }
    }

    if (!mounted || _activeItem?.id != item.id) {
      return;
    }
    setState(() {
      _textContent = content;
      _isLoadingText = false;
      _isPreparingResource = false;
    });
    _restoreTextScroll();
  }

  Future<void> _preparePdfResource(
    MaterialItem item,
    String resourceUrl,
  ) async {
    if (resourceUrl.trim().isEmpty) {
      throw _t(context, '暂无 PDF 文件地址', 'Missing PDF file URL');
    }
    final uri = Uri.tryParse(resourceUrl);
    if (uri == null || !uri.hasScheme) {
      throw _t(context, 'PDF 地址无效', 'Invalid PDF URL');
    }
    if (mounted) {
      setState(() => _isPreparingResource = true);
    }
    final localFile = await _cacheFileFor(item, resourceUrl);
    final hasCachedFile = await localFile.exists();
    if (!mounted || _activeItem?.id != item.id) {
      return;
    }
    setState(() {
      if (hasCachedFile) {
        _cachePath = localFile.path;
        _cacheProgress = 100;
      } else {
        _pdfUri = uri;
      }
      _isPreparingResource = false;
    });
  }

  Future<void> _prepareVideoResource(
    MaterialItem item,
    String resourceUrl,
  ) async {
    if (resourceUrl.trim().isEmpty) {
      throw _t(context, '暂无视频文件地址', 'Missing video file URL');
    }
    final uri = Uri.tryParse(resourceUrl);
    if (uri == null || !uri.hasScheme) {
      throw _t(context, '视频地址无效', 'Invalid video URL');
    }
    if (mounted) {
      setState(() => _isPreparingResource = true);
    }
    final localFile = await _cacheFileFor(item, resourceUrl);
    final hasCachedFile = await localFile.exists();
    if (hasCachedFile && mounted) {
      setState(() {
        _cachePath = localFile.path;
        _cacheProgress = 100;
      });
    }
    final controller = hasCachedFile
        ? VideoPlayerController.file(localFile)
        : VideoPlayerController.networkUrl(uri);
    _videoController = controller;
    controller.addListener(_handleVideoProgress);
    await controller.initialize();
    final restoredPosition = _positionFromProgress(
      controller.value.duration,
      _readingProgress,
    );
    if (restoredPosition > Duration.zero) {
      await controller.seekTo(restoredPosition);
    }
    if (!mounted || _activeItem?.id != item.id) {
      return;
    }
    setState(() => _isPreparingResource = false);
  }

  Future<void> _prepareAudioResource(
    MaterialItem item,
    String resourceUrl,
  ) async {
    if (resourceUrl.trim().isEmpty) {
      throw _t(context, '暂无音乐文件地址', 'Missing music file URL');
    }
    final uri = Uri.tryParse(resourceUrl);
    if (uri == null || !uri.hasScheme) {
      throw _t(context, '音乐地址无效', 'Invalid music URL');
    }
    if (mounted) {
      setState(() => _isPreparingResource = true);
    }
    final localFile = await _cacheFileFor(item, resourceUrl);
    final hasCachedFile = await localFile.exists();
    if (hasCachedFile && mounted) {
      setState(() {
        _cachePath = localFile.path;
        _cacheProgress = 100;
      });
    }
    final player = AudioPlayer();
    _audioPlayer = player;
    _audioPositionSubscription = player.positionStream.listen(
      _handleAudioPosition,
    );
    _audioStateSubscription = player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _readingProgress = 100;
        unawaited(
          _saveProgress(
            durationSeconds: player.duration?.inSeconds ?? 0,
            force: true,
          ),
        );
      }
    });
    final duration = hasCachedFile
        ? await player.setFilePath(localFile.path)
        : await player.setUrl(resourceUrl);
    final lyricContent = await _loadLyricContent(item);
    final restoredPosition = _positionFromProgress(
      duration ?? player.duration,
      _readingProgress,
    );
    if (restoredPosition > Duration.zero) {
      await player.seek(restoredPosition);
    }
    if (!mounted || _activeItem?.id != item.id) {
      return;
    }
    setState(() {
      _lyricContent = lyricContent;
      _isPreparingResource = false;
    });
  }

  Future<String> _loadLyricContent(MaterialItem item) async {
    final lyricUrl = _apiClient.resolveUrl(item.lyricUrl).trim();
    if (lyricUrl.isEmpty) {
      return item.contentText;
    }
    try {
      final response = await _apiClient.dio.get<String>(
        lyricUrl,
        options: Options(responseType: ResponseType.plain),
      );
      final content = (response.data ?? '').trim();
      return content.isEmpty ? item.contentText : content;
    } on Object {
      return item.contentText;
    }
  }

  Future<void> _prepareWebResource(String resourceUrl) async {
    if (resourceUrl.trim().isEmpty) {
      throw _t(context, '暂无游戏地址', 'Missing game URL');
    }
    final uri = Uri.tryParse(resourceUrl);
    if (uri == null || !uri.hasScheme) {
      throw _t(context, '游戏地址无效', 'Invalid game URL');
    }
    final controller = _buildWebViewController();
    _webViewController = controller;
    if (mounted) {
      setState(() {});
    }
    unawaited(
      controller.loadRequest(uri).catchError((Object error) {
        if (!mounted || _webViewController != controller) {
          return;
        }
        setState(() {
          _resourceError = error.toString();
          _isPreparingResource = false;
        });
      }),
    );
  }

  bool get _canCacheActiveResource {
    final item = _activeItem;
    if (item == null ||
        _activeResourceUrl.trim().isEmpty ||
        _isCaching ||
        _cachePath.trim().isNotEmpty) {
      return false;
    }
    return _isBookReader(item) ||
        _isPdfResource(item) ||
        _isVideoResource(item) ||
        _isAudioResource(item);
  }

  Future<void> _cacheActiveResource() async {
    final item = _activeItem;
    final resourceUrl = _activeResourceUrl.trim();
    if (item == null ||
        resourceUrl.isEmpty ||
        _isCaching ||
        _cachePath.trim().isNotEmpty) {
      return;
    }
    final localFile = await _cacheFileFor(item, resourceUrl);
    if (await localFile.exists()) {
      if (mounted) {
        setState(() {
          _cachePath = localFile.path;
          _cacheProgress = 100;
        });
      }
      return;
    }
    await _cacheRemoteFile(resourceUrl, localFile);
    if (!mounted) {
      return;
    }
    if (await localFile.exists()) {
      context.showCenteredNotice(_t(context, '已缓存到本地', 'Cached offline'));
    } else {
      context.showCenteredNotice(_t(context, '缓存失败', 'Cache failed'));
    }
  }

  WebViewController _buildWebViewController() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
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

  Future<String> _loadPlainTextResource(File file) async {
    final bytes = await file.readAsBytes();
    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<String> _loadRemotePlainTextResource(String resourceUrl) async {
    final response = await _apiClient.dio.get<List<int>>(
      resourceUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    return utf8.decode(response.data ?? const [], allowMalformed: true);
  }

  Future<String> _loadEpubResource(File file) async {
    return _loadEpubBytes(await file.readAsBytes());
  }

  Future<String> _loadRemoteEpubResource(String resourceUrl) async {
    final response = await _apiClient.dio.get<List<int>>(
      resourceUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    return _loadEpubBytes(response.data ?? const []);
  }

  String _loadEpubBytes(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final containerText = _archiveText(archive, 'META-INF/container.xml');
    if (containerText == null || containerText.trim().isEmpty) {
      throw _t(context, 'EPUB 文件缺少目录信息', 'Invalid EPUB container');
    }
    final container = XmlDocument.parse(containerText);
    final rootPath = _epubRootPath(container);
    if (rootPath == null) {
      throw _t(context, 'EPUB 文件缺少主文档', 'Invalid EPUB package');
    }
    final packageText = _archiveText(archive, rootPath);
    if (packageText == null || packageText.trim().isEmpty) {
      throw _t(context, 'EPUB 主文档读取失败', 'Failed to read EPUB package');
    }
    final packageDocument = XmlDocument.parse(packageText);
    final rootDir = rootPath.contains('/')
        ? rootPath.substring(0, rootPath.lastIndexOf('/') + 1)
        : '';
    final manifest = <String, String>{};
    for (final element in _elementsByLocalName(packageDocument, 'item')) {
      final id = element.getAttribute('id')?.trim();
      final href = element.getAttribute('href')?.trim();
      if (id == null || id.isEmpty || href == null || href.isEmpty) {
        continue;
      }
      manifest[id] = _resolveArchivePath(rootDir, href);
    }
    final parts = <String>[];
    for (final itemref in _elementsByLocalName(packageDocument, 'itemref')) {
      final idref = itemref.getAttribute('idref')?.trim();
      final archivePath = idref == null ? null : manifest[idref];
      if (archivePath == null) {
        continue;
      }
      final text = _archiveText(archive, archivePath);
      if (text != null) {
        parts.add(_xhtmlToPlainText(text));
      }
    }
    if (parts.isEmpty) {
      for (final entry in archive.files) {
        final name = entry.name.toLowerCase();
        if (entry.isFile &&
            (name.endsWith('.xhtml') || name.endsWith('.html'))) {
          parts.add(
            _xhtmlToPlainText(utf8.decode(entry.content, allowMalformed: true)),
          );
        }
      }
    }
    final content = parts
        .map(_compactText)
        .where((part) => part.trim().isNotEmpty)
        .join('\n\n');
    if (content.trim().isEmpty) {
      throw _t(context, 'EPUB 暂无可阅读正文', 'No readable EPUB text');
    }
    return content;
  }

  String? _archiveText(Archive archive, String path) {
    final file = archive.findFile(path.replaceAll('\\', '/'));
    if (file == null || !file.isFile) {
      return null;
    }
    return utf8.decode(file.content, allowMalformed: true);
  }

  String? _epubRootPath(XmlDocument document) {
    for (final element in _elementsByLocalName(document, 'rootfile')) {
      final path = element.getAttribute('full-path')?.trim();
      if (path != null && path.isNotEmpty) {
        return path;
      }
    }
    return null;
  }

  Iterable<XmlElement> _elementsByLocalName(XmlNode node, String localName) {
    return node.descendants.whereType<XmlElement>().where(
      (element) => element.name.local == localName,
    );
  }

  String _resolveArchivePath(String rootDir, String href) {
    final segments = <String>[];
    for (final segment in '$rootDir$href'.split('/')) {
      if (segment.isEmpty || segment == '.') {
        continue;
      }
      if (segment == '..') {
        if (segments.isNotEmpty) {
          segments.removeLast();
        }
        continue;
      }
      segments.add(Uri.decodeComponent(segment));
    }
    return segments.join('/');
  }

  String _xhtmlToPlainText(String source) {
    try {
      final document = XmlDocument.parse(source);
      XmlNode root = document.rootElement;
      for (final body in _elementsByLocalName(document, 'body')) {
        root = body;
        break;
      }
      final text = root.descendants
          .whereType<XmlText>()
          .map((node) => node.value)
          .join('\n');
      return _compactText(text);
    } on Object {
      return _compactText(
        source
            .replaceAll(
              RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
              '',
            )
            .replaceAll(
              RegExp(r'<style[\s\S]*?</style>', caseSensitive: false),
              '',
            )
            .replaceAll(RegExp(r'<[^>]+>'), '\n'),
      );
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
      await _apiClient.dio.download(
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
    } on Object {
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
    return File('${dir.path}/material_cache/${item.id}.$extension');
  }

  String _resourceExtension(MaterialItem item, String resourceUrl) {
    final type = item.mediaType.trim().toLowerCase();
    if (type == 'video') {
      return _extensionFromUrl(resourceUrl, 'mp4');
    }
    if (type == 'audio') {
      return _extensionFromUrl(resourceUrl, 'mp3');
    }
    if (type.isNotEmpty &&
        type != 'article' &&
        type != 'link' &&
        type != 'game') {
      return type;
    }
    return _extensionFromUrl(resourceUrl, 'html');
  }

  String _extensionFromUrl(String resourceUrl, String fallback) {
    final uri = Uri.tryParse(resourceUrl);
    final path = uri?.path ?? '';
    final dot = path.lastIndexOf('.');
    if (dot >= 0 && dot < path.length - 1) {
      final extension = path
          .substring(dot + 1)
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (extension.isNotEmpty) {
        return extension.length > 12 ? extension.substring(0, 12) : extension;
      }
    }
    return fallback;
  }

  void _handleTextScroll() {
    if (!_scrollController.hasClients || !_isBookReader(_activeItem)) {
      return;
    }
    final maxExtent = _scrollController.position.maxScrollExtent;
    final progress = maxExtent <= 0
        ? 100.0
        : (_scrollController.offset / maxExtent * 100).clamp(0, 100).toDouble();
    _readingProgress = progress;
    unawaited(_saveProgress());
  }

  void _handleVideoProgress() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    final duration = controller.value.duration;
    final position = controller.value.position;
    if (duration.inMilliseconds <= 0) {
      return;
    }
    _readingProgress = position.inMilliseconds >= duration.inMilliseconds
        ? 100
        : (position.inMilliseconds / duration.inMilliseconds * 100)
              .clamp(0, 100)
              .toDouble();
    unawaited(_saveProgress(durationSeconds: position.inSeconds));
  }

  void _handleAudioPosition(Duration position) {
    final duration = _audioPlayer?.duration;
    if (duration == null || duration.inMilliseconds <= 0) {
      return;
    }
    _readingProgress = position.inMilliseconds >= duration.inMilliseconds
        ? 100
        : (position.inMilliseconds / duration.inMilliseconds * 100)
              .clamp(0, 100)
              .toDouble();
    unawaited(_saveProgress(durationSeconds: position.inSeconds));
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
    await _materialRepository.saveHistory(
      materialId: item.id,
      title: item.title,
      route: '/materials/resource/${item.id}',
      progress: _readingProgress,
      durationSeconds: elapsedSeconds,
    );
  }

  Future<void> _disposePlaybackControllers() async {
    final videoController = _videoController;
    if (videoController != null) {
      videoController.removeListener(_handleVideoProgress);
      _videoController = null;
      await videoController.dispose();
    }
    await _audioPositionSubscription?.cancel();
    await _audioStateSubscription?.cancel();
    _audioPositionSubscription = null;
    _audioStateSubscription = null;
    final audioPlayer = _audioPlayer;
    if (audioPlayer != null) {
      _audioPlayer = null;
      await audioPlayer.dispose();
    }
  }

  Duration _positionFromProgress(Duration? duration, double progress) {
    if (duration == null || duration.inMilliseconds <= 0 || progress <= 0) {
      return Duration.zero;
    }
    final percent = progress.clamp(0, 100).toDouble();
    return Duration(
      milliseconds: (duration.inMilliseconds * percent / 100).round(),
    );
  }

  String _compactText(String source) {
    return source
        .split(RegExp(r'\r?\n'))
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  bool _isBookReader(MaterialItem? item) {
    if (item == null) {
      return false;
    }
    final type = item.mediaType.trim().toLowerCase();
    return type == 'article' || type == 'txt' || type == 'epub';
  }

  bool _isEpubResource(MaterialItem item) {
    return item.mediaType.trim().toLowerCase() == 'epub';
  }

  bool _isPdfResource(MaterialItem item) {
    return item.mediaType.trim().toLowerCase() == 'pdf';
  }

  bool _isVideoResource(MaterialItem item) {
    final type = item.mediaType.trim().toLowerCase();
    return type == 'video' || type == 'mp4' || type == 'mov';
  }

  bool _isAudioResource(MaterialItem item) {
    final type = item.mediaType.trim().toLowerCase();
    return type == 'audio' || type == 'mp3';
  }
}

class _ResourceScaffold extends StatelessWidget {
  const _ResourceScaffold({
    required this.cachePath,
    required this.cacheProgress,
    required this.isCaching,
    required this.canCache,
    required this.onCache,
    required this.child,
  });

  final String cachePath;
  final double cacheProgress;
  final bool isCaching;
  final bool canCache;
  final VoidCallback onCache;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cached = cachePath.isNotEmpty && !isCaching;
    return Column(
      children: [
        if (isCaching || cached || canCache)
          _CacheStatusBar(
            progress: cacheProgress,
            cached: cached,
            caching: isCaching,
            canCache: canCache,
            onCache: onCache,
          ),
        Expanded(child: child),
      ],
    );
  }
}

class _ResourceLoading extends StatelessWidget {
  const _ResourceLoading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFFFF9585)),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerPanel extends StatelessWidget {
  const _VideoPlayerPanel({required this.controller, required this.item});

  final VideoPlayerController controller;
  final MaterialItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = controller.value;
        final duration = value.duration;
        final position = value.position;
        final maxMilliseconds = math.max(duration.inMilliseconds, 1);
        final currentMilliseconds = position.inMilliseconds.clamp(
          0,
          maxMilliseconds,
        );
        return Container(
          color: Colors.black,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: value.aspectRatio > 0
                        ? value.aspectRatio
                        : 16 / 9,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                color: Colors.black.withValues(alpha: 0.72),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9585),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              value.isPlaying
                                  ? controller.pause()
                                  : controller.play();
                            },
                            icon: Icon(
                              value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFFFF9585),
                                thumbColor: const Color(0xFFFF9585),
                                inactiveTrackColor: Colors.white24,
                              ),
                              child: Slider(
                                value: currentMilliseconds.toDouble(),
                                min: 0,
                                max: maxMilliseconds.toDouble(),
                                onChanged: (next) => controller.seekTo(
                                  Duration(milliseconds: next.round()),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (value.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            value.errorDescription ??
                                _t(context, '视频播放失败', 'Video playback failed'),
                            style: TextStyle(
                              color: scheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AudioPlayerPanel extends StatefulWidget {
  const _AudioPlayerPanel({
    required this.player,
    required this.item,
    required this.coverUrl,
    required this.lyrics,
    required this.playlist,
    required this.onOpenTrack,
  });

  final AudioPlayer player;
  final MaterialItem item;
  final String coverUrl;
  final String lyrics;
  final AsyncValue<MaterialPage<MaterialItem>> playlist;
  final ValueChanged<MaterialItem> onOpenTrack;

  @override
  State<_AudioPlayerPanel> createState() => _AudioPlayerPanelState();
}

class _AudioPlayerPanelState extends State<_AudioPlayerPanel> {
  final _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artist = widget.item.artist.trim().isNotEmpty
        ? widget.item.artist.trim()
        : _t(context, '未知歌手', 'Unknown artist');
    final album = widget.item.album.trim().isNotEmpty
        ? widget.item.album.trim()
        : _t(context, '未设置专辑', 'No album');
    final lines = _parseLrc(widget.lyrics);
    return StreamBuilder<PlayerState>(
      stream: widget.player.playerStateStream,
      builder: (context, playerSnapshot) {
        final playerState = playerSnapshot.data;
        final isPlaying = playerState?.playing ?? widget.player.playing;
        final isBuffering =
            playerState?.processingState == ProcessingState.loading ||
            playerState?.processingState == ProcessingState.buffering;
        return StreamBuilder<Duration?>(
          stream: widget.player.durationStream,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;
            return StreamBuilder<Duration>(
              stream: widget.player.positionStream,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final maxMilliseconds = math.max(duration.inMilliseconds, 1);
                final currentMilliseconds = position.inMilliseconds
                    .clamp(0, maxMilliseconds)
                    .toInt();
                final activeLyricIndex = _activeLyricIndex(lines, position);
                final currentLyric = activeLyricIndex >= 0
                    ? lines[activeLyricIndex].text
                    : lines.isNotEmpty
                    ? lines.first.text
                    : _t(context, '暂无歌词', 'No lyrics yet');
                return Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) =>
                            setState(() => _pageIndex = index),
                        children: [
                          _AudioPlaybackPage(
                            player: widget.player,
                            item: widget.item,
                            coverUrl: widget.coverUrl,
                            artist: artist,
                            album: album,
                            isPlaying: isPlaying,
                            isBuffering: isBuffering,
                            position: position,
                            duration: duration,
                            currentMilliseconds: currentMilliseconds,
                            maxMilliseconds: maxMilliseconds,
                            currentLyric: currentLyric,
                          ),
                          _AudioLyricsPage(
                            lines: lines,
                            position: position,
                            onSeek: widget.player.seek,
                          ),
                          _AudioPlaylistPage(
                            activeId: widget.item.id,
                            playlist: widget.playlist,
                            onOpenTrack: widget.onOpenTrack,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 6, 22, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PageDot(selected: _pageIndex == 0),
                          const SizedBox(width: 8),
                          _PageDot(selected: _pageIndex == 1),
                          const SizedBox(width: 8),
                          _PageDot(selected: _pageIndex == 2),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AudioPlaybackPage extends StatelessWidget {
  const _AudioPlaybackPage({
    required this.player,
    required this.item,
    required this.coverUrl,
    required this.artist,
    required this.album,
    required this.isPlaying,
    required this.isBuffering,
    required this.position,
    required this.duration,
    required this.currentMilliseconds,
    required this.maxMilliseconds,
    required this.currentLyric,
  });

  final AudioPlayer player;
  final MaterialItem item;
  final String coverUrl;
  final String artist;
  final String album;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final int currentMilliseconds;
  final int maxMilliseconds;
  final String currentLyric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
      children: [
        Center(
          child: Container(
            width: 238,
            height: 238,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: coverUrl.isNotEmpty
                ? Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, loadingProgress) =>
                        loadingProgress == null
                        ? child
                        : const _AudioCoverFallback(),
                    errorBuilder: (_, _, _) => const _AudioCoverFallback(),
                  )
                : const _AudioCoverFallback(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          item.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$artist · $album',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 28),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFFF9585),
            thumbColor: const Color(0xFFFF9585),
            inactiveTrackColor: scheme.outlineVariant,
          ),
          child: Slider(
            value: currentMilliseconds.toDouble(),
            min: 0,
            max: maxMilliseconds.toDouble(),
            onChanged: (next) =>
                player.seek(Duration(milliseconds: next.round())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _formatDuration(duration),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: SizedBox(
            width: 72,
            height: 72,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFF9585),
                foregroundColor: Colors.white,
              ),
              onPressed: isBuffering
                  ? null
                  : () {
                      isPlaying ? player.pause() : player.play();
                    },
              iconSize: 38,
              icon: isBuffering
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          currentLyric,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFFFF9585),
            fontSize: 17,
            fontWeight: FontWeight.w900,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _AudioPlaylistPage extends StatelessWidget {
  const _AudioPlaylistPage({
    required this.activeId,
    required this.playlist,
    required this.onOpenTrack,
  });

  final int activeId;
  final AsyncValue<MaterialPage<MaterialItem>> playlist;
  final ValueChanged<MaterialItem> onOpenTrack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return playlist.when(
      data: (page) {
        final tracks = page.list
            .where((item) => _isAudioMediaType(item.mediaType))
            .toList();
        if (tracks.isEmpty) {
          return _AudioPlaylistEmpty(
            text: _t(context, '暂无同分类音乐', 'No music in this category yet'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 48),
          itemCount: tracks.length + 1,
          separatorBuilder: (_, index) => index == 0
              ? const SizedBox(height: 12)
              : const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Text(
                _t(context, '播放列表', 'Playlist'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              );
            }
            final track = tracks[index - 1];
            final selected = track.id == activeId;
            final artist = track.artist.trim().isNotEmpty
                ? track.artist.trim()
                : _t(context, '未知歌手', 'Unknown artist');
            final album = track.album.trim().isNotEmpty
                ? track.album.trim()
                : _t(context, '未设置专辑', 'No album');
            final duration = track.durationSeconds > 0
                ? _formatDuration(Duration(seconds: track.durationSeconds))
                : '';
            return Material(
              color: selected
                  ? const Color(0xFFFF9585).withValues(alpha: 0.12)
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.56),
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                selected: selected,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: selected
                      ? const Color(0xFFFF9585)
                      : scheme.surface,
                  foregroundColor: selected
                      ? Colors.white
                      : const Color(0xFFFF9585),
                  child: Icon(
                    selected
                        ? Icons.equalizer_rounded
                        : Icons.music_note_rounded,
                  ),
                ),
                title: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  duration.isEmpty ? '$artist · $album' : '$artist · $duration',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFFFF9585)
                        : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: Icon(
                  selected
                      ? Icons.play_circle_fill_rounded
                      : Icons.chevron_right_rounded,
                  color: selected
                      ? const Color(0xFFFF9585)
                      : scheme.onSurfaceVariant,
                ),
                onTap: selected ? null : () => onOpenTrack(track),
              ),
            );
          },
        );
      },
      error: (_, _) => _AudioPlaylistEmpty(
        text: _t(context, '播放列表加载失败', 'Playlist failed to load'),
      ),
      loading: () => Center(
        child: CircularProgressIndicator(color: const Color(0xFFFF9585)),
      ),
    );
  }
}

class _AudioPlaylistEmpty extends StatelessWidget {
  const _AudioPlaylistEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AudioLyricsPage extends StatefulWidget {
  const _AudioLyricsPage({
    required this.lines,
    required this.position,
    required this.onSeek,
  });

  final List<_LyricLine> lines;
  final Duration position;
  final ValueChanged<Duration> onSeek;

  @override
  State<_AudioLyricsPage> createState() => _AudioLyricsPageState();
}

class _AudioLyricsPageState extends State<_AudioLyricsPage> {
  final _scrollController = ScrollController();
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncActiveLine());
  }

  @override
  void didUpdateWidget(covariant _AudioLyricsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncActiveLine();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncActiveLine() {
    final activeIndex = _activeLyricIndex(widget.lines, widget.position);
    if (activeIndex < 0 || activeIndex == _lastActiveIndex) {
      return;
    }
    _lastActiveIndex = activeIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      final target = (activeIndex * 48.0 - 120).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lines = widget.lines;
    if (lines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            _t(context, '暂无 LRC 歌词', 'No LRC lyrics yet'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }
    final activeIndex = _activeLyricIndex(lines, widget.position);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(26, 48, 26, 80),
      itemCount: lines.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 26),
            child: Text(
              _t(context, '歌词', 'Lyrics'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        }
        final lineIndex = index - 1;
        final line = lines[lineIndex];
        final selected = lineIndex == activeIndex;
        final time = line.time;
        return AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          style: TextStyle(
            color: selected ? const Color(0xFFFF9585) : scheme.onSurfaceVariant,
            fontSize: selected ? 20 : 16,
            height: 1.45,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: time == null ? null : () => widget.onSeek(time),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text(line.text, textAlign: TextAlign.center),
            ),
          ),
        );
      },
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: selected ? 18 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFFF9585)
            : Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _LyricLine {
  const _LyricLine({required this.time, required this.text});

  final Duration? time;
  final String text;
}

List<_LyricLine> _parseLrc(String source) {
  final lines = <_LyricLine>[];
  final timestampPattern = RegExp(r'\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]');
  for (final rawLine in const LineSplitter().convert(source)) {
    final matches = timestampPattern.allMatches(rawLine).toList();
    final text = rawLine.replaceAll(timestampPattern, '').trim();
    if (matches.isEmpty) {
      if (text.isNotEmpty && !rawLine.trim().startsWith('[')) {
        lines.add(_LyricLine(time: null, text: text));
      }
      continue;
    }
    if (text.isEmpty) {
      continue;
    }
    for (final match in matches) {
      lines.add(_LyricLine(time: _durationFromLrcMatch(match), text: text));
    }
  }
  lines.sort((a, b) {
    final left = a.time;
    final right = b.time;
    if (left == null && right == null) {
      return 0;
    }
    if (left == null) {
      return 1;
    }
    if (right == null) {
      return -1;
    }
    return left.compareTo(right);
  });
  return lines;
}

Duration _durationFromLrcMatch(RegExpMatch match) {
  final minutes = int.tryParse(match.group(1) ?? '') ?? 0;
  final seconds = int.tryParse(match.group(2) ?? '') ?? 0;
  final fraction = match.group(3) ?? '';
  final milliseconds = switch (fraction.length) {
    0 => 0,
    1 => int.parse(fraction) * 100,
    2 => int.parse(fraction) * 10,
    _ => int.parse(fraction.substring(0, 3)),
  };
  return Duration(
    minutes: minutes,
    seconds: seconds,
    milliseconds: milliseconds,
  );
}

int _activeLyricIndex(List<_LyricLine> lines, Duration position) {
  var activeIndex = -1;
  for (var i = 0; i < lines.length; i += 1) {
    final time = lines[i].time;
    if (time == null) {
      continue;
    }
    if (time > position) {
      break;
    }
    activeIndex = i;
  }
  return activeIndex;
}

bool _isAudioMediaType(String mediaType) {
  final type = mediaType.trim().toLowerCase();
  return type == 'audio' || type == 'mp3';
}

class _AudioCoverFallback extends StatelessWidget {
  const _AudioCoverFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF9585), Color(0xFF5A81DA)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note_rounded, size: 72, color: Colors.white),
      ),
    );
  }
}

class _CacheStatusBar extends StatelessWidget {
  const _CacheStatusBar({
    required this.progress,
    required this.cached,
    required this.caching,
    required this.canCache,
    required this.onCache,
  });

  final double progress;
  final bool cached;
  final bool caching;
  final bool canCache;
  final VoidCallback onCache;

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
                  : caching
                  ? _t(
                      context,
                      '正在缓存 ${progress.clamp(0, 100).toStringAsFixed(0)}%',
                      'Caching ${progress.clamp(0, 100).toStringAsFixed(0)}%',
                    )
                  : _t(context, '未缓存，在线打开', 'Not cached, opened online'),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (canCache) ...[
            const SizedBox(width: 10),
            TextButton.icon(
              onPressed: onCache,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF9585),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.download_for_offline_outlined, size: 18),
              label: Text(_t(context, '缓存', 'Cache')),
            ),
          ],
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

String _formatDuration(Duration duration) {
  final safeDuration = duration.isNegative ? Duration.zero : duration;
  final totalSeconds = safeDuration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
