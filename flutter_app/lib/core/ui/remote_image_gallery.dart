import 'package:flutter/material.dart';
import 'package:helpsupport_app/core/cache/cached_remote_image.dart';

void showRemoteImageGallery(
  BuildContext context, {
  required List<String> images,
  int initialIndex = 0,
}) {
  final urls = images
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  if (urls.isEmpty) {
    return;
  }
  final startIndex = initialIndex.clamp(0, urls.length - 1);

  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.88),
    builder: (dialogContext) {
      return _RemoteImageGalleryDialog(
        images: urls,
        initialIndex: startIndex,
      );
    },
  );
}

class _RemoteImageGalleryDialog extends StatefulWidget {
  const _RemoteImageGalleryDialog({
    required this.images,
    required this.initialIndex,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<_RemoteImageGalleryDialog> createState() =>
      _RemoteImageGalleryDialogState();
}

class _RemoteImageGalleryDialogState extends State<_RemoteImageGalleryDialog> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final closeLabel = MaterialLocalizations.of(context).closeButtonTooltip;
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: CachedRemoteImage(
                      widget.images[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 56,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                tooltip: closeLabel,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
