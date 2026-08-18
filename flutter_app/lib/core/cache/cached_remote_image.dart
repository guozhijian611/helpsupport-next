import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CachedRemoteImage extends StatefulWidget {
  const CachedRemoteImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final Widget? placeholder;
  final Widget? errorWidget;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  State<CachedRemoteImage> createState() => _CachedRemoteImageState();
}

class _CachedRemoteImageState extends State<CachedRemoteImage> {
  late Future<File?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = RemoteImageDiskCache.instance.get(widget.url);
  }

  @override
  void didUpdateWidget(CachedRemoteImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _imageFuture = RemoteImageDiskCache.instance.get(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file != null) {
          return Image.file(
            file,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            alignment: widget.alignment,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) =>
                _fallback(context, error, stackTrace),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return _placeholder(context);
        }
        return _fallback(context, snapshot.error, null);
      },
    );
  }

  Widget _placeholder(BuildContext context) {
    final placeholder =
        widget.placeholder ??
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
    final loadingBuilder = widget.loadingBuilder;
    if (loadingBuilder != null) {
      return loadingBuilder(context, placeholder, null);
    }
    return placeholder;
  }

  Widget _fallback(
    BuildContext context,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final errorBuilder = widget.errorBuilder;
    if (errorBuilder != null) {
      return errorBuilder(
        context,
        error ?? const HttpException('Remote image cache failed'),
        stackTrace,
      );
    }
    return widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
  }
}

class RemoteImageDiskCache {
  RemoteImageDiskCache._();

  static final instance = RemoteImageDiskCache._();
  static const directoryName = 'http_image_cache';

  final Map<String, Future<File?>> _inFlight = {};

  Future<File?> get(String rawUrl) {
    final url = _normalizeUrl(rawUrl);
    final uri = _parseHttpUri(url);
    if (uri == null) {
      return Future.value(null);
    }
    return _inFlight.putIfAbsent(uri.toString(), () async {
      try {
        return await _getOrDownload(uri);
      } finally {
        _inFlight.remove(uri.toString());
      }
    });
  }

  Future<File?> _getOrDownload(Uri uri) async {
    final file = await _fileFor(uri);
    if (await file.exists() && await file.length() > 0) {
      unawaited(file.setLastModified(DateTime.now()));
      return file;
    }

    final tempFile = File('${file.path}.download');
    try {
      final client = HttpClient();
      try {
        client.userAgent =
            'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148';
        client.connectionTimeout = const Duration(seconds: 12);
        final request = await client.getUrl(uri);
        request.followRedirects = true;
        request.maxRedirects = 8;
        request.headers.set(
          HttpHeaders.acceptHeader,
          'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
        );
        final response = await request.close();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return null;
        }
        await file.parent.create(recursive: true);
        final sink = tempFile.openWrite();
        await response.pipe(sink);
        if (await tempFile.length() == 0) {
          await tempFile.delete();
          return null;
        }
        await tempFile.rename(file.path);
        return file;
      } finally {
        client.close(force: true);
      }
    } on Object {
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } on FileSystemException {
        // Ignore incomplete downloads that cannot be removed immediately.
      }
      return null;
    }
  }

  Future<File> _fileFor(Uri uri) async {
    final documents = await getApplicationDocumentsDirectory();
    final digest = sha1.convert(uri.toString().codeUnits).toString();
    final extension = _extensionFor(uri);
    return File('${documents.path}/$directoryName/$digest$extension');
  }

  bool _isHttpScheme(String scheme) {
    return scheme == 'http' || scheme == 'https';
  }

  String _normalizeUrl(String rawUrl) {
    return rawUrl
        .trim()
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"');
  }

  Uri? _parseHttpUri(String url) {
    if (url.isEmpty) {
      return null;
    }
    final parsed = Uri.tryParse(url);
    if (parsed == null || !parsed.hasScheme || !_isHttpScheme(parsed.scheme)) {
      return null;
    }
    if (parsed.path.contains('%')) {
      return parsed;
    }
    final encodedPath = parsed.pathSegments.map(Uri.encodeComponent).join('/');
    final path = parsed.path.startsWith('/') ? '/$encodedPath' : encodedPath;
    return parsed.replace(path: path);
  }

  String _extensionFor(Uri uri) {
    final path = uri.path.toLowerCase();
    for (final extension in const ['.jpg', '.jpeg', '.png', '.webp', '.gif']) {
      if (path.endsWith(extension)) {
        return extension;
      }
    }
    return '.img';
  }
}
