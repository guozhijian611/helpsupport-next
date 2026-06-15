import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../application/community_controller.dart';
import '../data/community_models.dart';

class CommunityPostEditorScreen extends ConsumerStatefulWidget {
  const CommunityPostEditorScreen({super.key});

  @override
  ConsumerState<CommunityPostEditorScreen> createState() =>
      _CommunityPostEditorScreenState();
}

class _CommunityPostEditorScreenState
    extends ConsumerState<CommunityPostEditorScreen> {
  static const _maxAttachments = 9;

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _linkController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  final Set<int> _selectedTagIds = <int>{};
  List<_EditorImageAttachment> _attachments = const [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(communityTagsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(_t(context, '社区发布', 'New community post'))),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(28, 10, 28, 16),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF5A81DA),
            disabledBackgroundColor: const Color(0xFFB8C7EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          onPressed: _isSubmitting ? null : () => _submit(context),
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  context.l10n.communityPublish,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          children: [
            _SectionLabel(text: _t(context, '标题', 'Title')),
            const SizedBox(height: 12),
            _InputPanel(
              child: TextField(
                controller: _titleController,
                minLines: 2,
                maxLines: 3,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: _t(
                    context,
                    '请输入帖子标题',
                    'Write a short title for your post',
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  color: Color(0xFF42454D),
                  fontSize: 18,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 22),
            _SectionLabel(text: _t(context, '内容', 'Content')),
            const SizedBox(height: 12),
            _InputPanel(
              minHeight: 320,
              child: TextField(
                controller: _contentController,
                minLines: 10,
                maxLines: 14,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: context.l10n.communityPostHint,
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  color: Color(0xFF42454D),
                  fontSize: 17,
                  height: 1.7,
                ),
              ),
            ),
            const SizedBox(height: 22),
            _SectionLabel(text: _t(context, '图片/视频', 'Media')),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final attachment in _attachments)
                  _AttachmentTile(
                    attachment: attachment,
                    onRemove: () => _removeAttachment(attachment.id),
                  ),
                if (_attachments.length < _maxAttachments)
                  _AddAttachmentTile(onTap: _pickImages),
              ],
            ),
            const SizedBox(height: 22),
            _SectionLabel(text: _t(context, '附加链接', 'Optional link')),
            const SizedBox(height: 12),
            _InputPanel(
              child: TextField(
                controller: _linkController,
                decoration: const InputDecoration(
                  hintText: 'https://',
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.url,
              ),
            ),
            const SizedBox(height: 22),
            _SectionLabel(text: _t(context, '标签', 'Tags')),
            const SizedBox(height: 12),
            tags.when(
              data: (items) => Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final tag in items.take(8))
                    _SelectableTagChip(
                      tag: tag,
                      selected: _selectedTagIds.contains(tag.id),
                      onTap: () => setState(() {
                        if (_selectedTagIds.contains(tag.id)) {
                          _selectedTagIds.remove(tag.id);
                        } else {
                          _selectedTagIds.add(tag.id);
                        }
                      }),
                    ),
                ],
              ),
              error: (_, _) => Text(
                _t(
                  context,
                  '标签加载失败，可直接发布内容。',
                  'Tags failed to load. You can still publish the post.',
                ),
                style: const TextStyle(color: Color(0xFF96999F)),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FA),
                borderRadius: BorderRadius.circular(22),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isAnonymous,
                title: Text(context.l10n.communityAnonymous),
                subtitle: Text(
                  _t(
                    context,
                    '匿名后不会展示昵称与头像，但仍会进入审核与互动流程。',
                    'Anonymous posts hide your profile but still go through moderation and engagement.',
                  ),
                ),
                onChanged: (value) => setState(() => _isAnonymous = value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final permission = await ref
        .read(permissionServiceProvider)
        .requestMediaLibrary();
    final granted =
        permission == PermissionStatus.granted ||
        permission == PermissionStatus.limited;
    if (!granted) {
      if (mounted) {
        context.showCenteredNotice(
          _t(
            context,
            '需要开启相册权限后才能添加图片',
            'Photo permission is required to add images',
          ),
        );
      }
      return;
    }

    final files = await _imagePicker.pickMultiImage(
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (files.isEmpty) {
      return;
    }

    final remaining = _maxAttachments - _attachments.length;
    final picked = files.take(remaining).toList(growable: false);
    final pending = picked
        .map(
          (file) => _EditorImageAttachment(
            id: '${DateTime.now().microsecondsSinceEpoch}-${file.path}',
            localPath: file.path,
            remoteUrl: '',
            isUploading: true,
          ),
        )
        .toList(growable: false);

    setState(() {
      _attachments = [..._attachments, ...pending];
    });

    for (var index = 0; index < pending.length; index++) {
      await _uploadAttachment(picked[index], pending[index]);
    }

    if (files.length > remaining && mounted) {
      context.showCenteredNotice(
        _t(context, '最多只能上传 9 张图片', 'You can upload up to 9 images'),
      );
    }
  }

  Future<void> _uploadAttachment(
    XFile file,
    _EditorImageAttachment attachment,
  ) async {
    try {
      final remoteUrl = await ref
          .read(communityRepositoryProvider)
          .uploadImage(file: file);
      if (!mounted) {
        return;
      }
      _updateAttachment(
        attachment.id,
        (current) => current.copyWith(remoteUrl: remoteUrl, isUploading: false),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _attachments = _attachments
            .where((item) => item.id != attachment.id)
            .toList(growable: false);
      });
      context.showCenteredNotice(error.toString());
    }
  }

  void _removeAttachment(String id) {
    setState(() {
      _attachments = _attachments
          .where((item) => item.id != id)
          .toList(growable: false);
    });
  }

  void _updateAttachment(
    String id,
    _EditorImageAttachment Function(_EditorImageAttachment current) transform,
  ) {
    setState(() {
      _attachments = _attachments
          .map((item) {
            if (item.id != id) {
              return item;
            }
            return transform(item);
          })
          .toList(growable: false);
    });
  }

  Future<void> _submit(BuildContext context) async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) {
      context.showCenteredNotice(_t(context, '请先填写标题', 'Please add a title'));
      return;
    }
    if (content.isEmpty) {
      context.showCenteredNotice(context.l10n.communityPostHint);
      return;
    }
    if (_attachments.any((item) => item.isUploading)) {
      context.showCenteredNotice(
        _t(
          context,
          '图片仍在上传，请稍候再发布',
          'Images are still uploading. Please wait a moment.',
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final tags = await ref.read(communityTagsProvider.future);
      final selectedTags = tags
          .where((tag) => _selectedTagIds.contains(tag.id))
          .map((tag) => tag.name)
          .toList(growable: false);
      await ref
          .read(communityRepositoryProvider)
          .createPost(
            content: '$title\n\n$content',
            isAnonymous: _isAnonymous,
            images: _attachments
                .map((item) => item.remoteUrl)
                .where((item) => item.trim().isNotEmpty)
                .toList(growable: false),
            tags: selectedTags,
            linkUrl: _linkController.text.trim(),
          );
      ref.invalidate(communityPostsProvider);
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(context.l10n.communityPendingReview);
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF303236),
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _InputPanel extends StatelessWidget {
  const _InputPanel({required this.child, this.minHeight});

  final Widget child;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: minHeight == null
          ? null
          : BoxConstraints(minHeight: minHeight!),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}

class _AddAttachmentTile extends StatelessWidget {
  const _AddAttachmentTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F5F7),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: const SizedBox(
          width: 108,
          height: 108,
          child: Icon(Icons.add_rounded, size: 44, color: Color(0xFF9AA0A8)),
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment, required this.onRemove});

  final _EditorImageAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            width: 108,
            height: 108,
            child: Image.file(File(attachment.localPath), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.46),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
        if (attachment.isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SelectableTagChip extends StatelessWidget {
  const _SelectableTagChip({
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final CommunityTag tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text('# ${tag.name}'),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFFFEEE9),
      checkmarkColor: const Color(0xFFFF9585),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFFFF9585) : const Color(0xFF6B7380),
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _EditorImageAttachment {
  const _EditorImageAttachment({
    required this.id,
    required this.localPath,
    required this.remoteUrl,
    required this.isUploading,
  });

  final String id;
  final String localPath;
  final String remoteUrl;
  final bool isUploading;

  _EditorImageAttachment copyWith({
    String? id,
    String? localPath,
    String? remoteUrl,
    bool? isUploading,
  }) {
    return _EditorImageAttachment(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
