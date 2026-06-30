import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/api/api_client.dart';
import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../application/community_controller.dart';
import '../data/community_models.dart';
import 'community_feed_screen.dart';

class CommunityPostDetailScreen extends ConsumerStatefulWidget {
  const CommunityPostDetailScreen({super.key, required this.postId});

  final int postId;

  @override
  ConsumerState<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState
    extends ConsumerState<CommunityPostDetailScreen> {
  static const _maxComposerAttachments = 3;

  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  final _imagePicker = ImagePicker();
  bool _isSending = false;
  bool _isAnonymous = false;
  _CommentSortMode _sortMode = _CommentSortMode.recommend;
  CommunityComment? _replyTarget;
  List<_ComposerAttachment> _attachments = const [];

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityPostDetailPalette.of(context);
    final post = ref.watch(communityPostProvider(widget.postId));
    final comments = ref.watch(communityCommentsProvider(widget.postId));

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        title: Text(_t(context, '评论', 'Comments')),
      ),
      body: SafeArea(
        child: post.when(
          data: (item) => Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(communityPostProvider(widget.postId));
                    ref.invalidate(communityCommentsProvider(widget.postId));
                    await Future.wait([
                      ref.read(communityPostProvider(widget.postId).future),
                      ref.read(communityCommentsProvider(widget.postId).future),
                    ]);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    children: [
                      CommunityPostCard(
                        post: item,
                        showFollowButton: true,
                        routeToDetail: false,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                        decoration: BoxDecoration(
                          color: palette.cardBackground,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: comments.when(
                          data: (page) => _CommentPanel(
                            total: page.total > 0
                                ? page.total
                                : item.commentCount,
                            sortMode: _sortMode,
                            comments: _commentNodes(page.list),
                            apiClient: ref.watch(apiClientProvider),
                            onReply: _replyComment,
                            onLike: _toggleCommentLike,
                            onReport: _reportComment,
                            onSortChanged: (mode) =>
                                setState(() => _sortMode = mode),
                          ),
                          error: (error, stackTrace) =>
                              _CommentStatus(message: error.toString()),
                          loading: () => const _CommentLoading(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _CommentComposer(
                controller: _commentController,
                focusNode: _commentFocusNode,
                isSending: _isSending,
                isAnonymous: _isAnonymous,
                replyTarget: _replyTarget,
                attachments: _attachments,
                onDismissReply: () => setState(() => _replyTarget = null),
                onRemoveAttachment: _removeAttachment,
                onPickImage: _pickImages,
                onToggleAnonymous: () =>
                    setState(() => _isAnonymous = !_isAnonymous),
                onSend: () => _sendComment(context),
              ),
            ],
          ),
          error: (error, stackTrace) =>
              Center(child: Text(context.l10n.networkUnavailable)),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  List<_CommentNode> _commentNodes(List<CommunityComment> source) {
    final repliesByParent = <int, List<CommunityComment>>{};
    final roots = <CommunityComment>[];
    for (final comment in source) {
      if (comment.parentId > 0) {
        repliesByParent.putIfAbsent(comment.parentId, () => []).add(comment);
      } else {
        roots.add(comment);
      }
    }
    if (_sortMode == _CommentSortMode.time) {
      roots.sort((left, right) {
        final leftTime =
            DateTime.tryParse(left.createTime) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final rightTime =
            DateTime.tryParse(right.createTime) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return rightTime.compareTo(leftTime);
      });
    } else {
      roots.sort((left, right) {
        final likeCompare = right.likeCount.compareTo(left.likeCount);
        if (likeCompare != 0) {
          return likeCompare;
        }
        return left.id.compareTo(right.id);
      });
    }

    for (final replies in repliesByParent.values) {
      replies.sort((left, right) => left.id.compareTo(right.id));
    }
    _CommentNode buildNode(CommunityComment comment) {
      return _CommentNode(
        comment: comment,
        replies: (repliesByParent[comment.id] ?? const <CommunityComment>[])
            .map(buildNode)
            .toList(growable: false),
      );
    }

    return roots.map(buildNode).toList(growable: false);
  }

  void _replyComment(CommunityComment comment) {
    setState(() => _replyTarget = comment);
    _commentFocusNode.requestFocus();
  }

  Future<void> _toggleCommentLike(CommunityComment comment) async {
    try {
      await ref.read(communityRepositoryProvider).toggleCommentLike(comment.id);
      ref.invalidate(communityPostProvider(widget.postId));
      ref.invalidate(communityCommentsProvider(widget.postId));
      ref.invalidate(communityPostsProvider);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }

  Future<void> _reportComment(CommunityComment comment) async {
    final draft = await showCommunityReportSheet(
      context,
      title: _t(context, '举报评论', 'Report comment'),
    );
    if (draft == null || !mounted) {
      return;
    }
    try {
      await ref
          .read(communityRepositoryProvider)
          .reportTarget(
            targetType: 2,
            targetId: comment.id,
            reason: draft.reason,
            description: draft.description,
          );
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(_t(context, '举报已提交', 'Report submitted'));
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
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

    final remaining = _maxComposerAttachments - _attachments.length;
    final picked = files.take(remaining).toList(growable: false);
    final pending = picked
        .map(
          (file) => _ComposerAttachment(
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
        _t(
          context,
          '评论最多上传 3 张图片',
          'You can upload up to 3 images per comment',
        ),
      );
    }
  }

  Future<void> _uploadAttachment(
    XFile file,
    _ComposerAttachment attachment,
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
    _ComposerAttachment Function(_ComposerAttachment current) transform,
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

  Future<void> _sendComment(BuildContext context) async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSending) {
      return;
    }
    if (_attachments.any((item) => item.isUploading)) {
      context.showCenteredNotice(
        _t(
          context,
          '图片仍在上传，请稍候发送',
          'Images are still uploading. Please wait before sending.',
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref
          .read(communityRepositoryProvider)
          .createComment(
            postId: widget.postId,
            content: content,
            isAnonymous: _isAnonymous,
            parentId: _replyTarget == null
                ? null
                : (_replyTarget!.parentId > 0
                      ? _replyTarget!.parentId
                      : _replyTarget!.id),
            replyToMemberId: _replyTarget?.memberId,
            attachments: _attachments
                .map((item) => item.remoteUrl)
                .where((item) => item.trim().isNotEmpty)
                .toList(growable: false),
          );
      _commentController.clear();
      ref.invalidate(communityPostProvider(widget.postId));
      ref.invalidate(communityCommentsProvider(widget.postId));
      ref.invalidate(communityPostsProvider);
      if (!mounted) {
        return;
      }
      setState(() {
        _isAnonymous = false;
        _replyTarget = null;
        _attachments = const [];
      });
      context.showCenteredNotice(_t(context, '评论已提交', 'Comment sent'));
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}

enum _CommentSortMode { recommend, time }

class _CommentNode {
  const _CommentNode({required this.comment, required this.replies});

  final CommunityComment comment;
  final List<_CommentNode> replies;
}

class _CommentPanel extends StatelessWidget {
  const _CommentPanel({
    required this.total,
    required this.sortMode,
    required this.comments,
    required this.apiClient,
    required this.onReply,
    required this.onLike,
    required this.onReport,
    required this.onSortChanged,
  });

  final int total;
  final _CommentSortMode sortMode;
  final List<_CommentNode> comments;
  final ApiClient apiClient;
  final ValueChanged<CommunityComment> onReply;
  final ValueChanged<CommunityComment> onLike;
  final ValueChanged<CommunityComment> onReport;
  final ValueChanged<_CommentSortMode> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityPostDetailPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            _t(context, '$total 条评论', '$total comments'),
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _SortTab(
              label: _t(context, '按推荐', 'Top'),
              selected: sortMode == _CommentSortMode.recommend,
              onTap: () => onSortChanged(_CommentSortMode.recommend),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '|',
                style: TextStyle(color: Color(0xFFD3D5DB), fontSize: 18),
              ),
            ),
            _SortTab(
              label: _t(context, '按时间', 'Newest'),
              selected: sortMode == _CommentSortMode.time,
              onTap: () => onSortChanged(_CommentSortMode.time),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                _t(context, '还没有评论，来说两句吧', 'No comments yet'),
                style: TextStyle(
                  color: palette.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          for (final node in comments)
            Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: _CommentThread(
                node: node,
                depth: 0,
                apiClient: apiClient,
                onReply: onReply,
                onLike: onLike,
                onReport: onReport,
              ),
            ),
      ],
    );
  }
}

class _CommentThread extends StatelessWidget {
  const _CommentThread({
    required this.node,
    required this.depth,
    required this.apiClient,
    required this.onReply,
    required this.onLike,
    required this.onReport,
  });

  final _CommentNode node;
  final int depth;
  final ApiClient apiClient;
  final ValueChanged<CommunityComment> onReply;
  final ValueChanged<CommunityComment> onLike;
  final ValueChanged<CommunityComment> onReport;

  @override
  Widget build(BuildContext context) {
    final comment = node.comment;
    return Column(
      children: [
        _CommentTile(
          comment: comment,
          indent: depth * 24.0,
          avatarUrl: apiClient.resolveUrl(comment.authorAvatar),
          imageUrls: comment.attachments
              .map((item) => apiClient.resolveUrl(item))
              .where((item) => item.trim().isNotEmpty)
              .toList(growable: false),
          onReply: () => onReply(comment),
          onLike: () => onLike(comment),
          onReport: () => onReport(comment),
        ),
        for (final reply in node.replies)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _CommentThread(
              node: reply,
              depth: depth + 1,
              apiClient: apiClient,
              onReply: onReply,
              onLike: onLike,
              onReport: onReport,
            ),
          ),
      ],
    );
  }
}

class _SortTab extends StatelessWidget {
  const _SortTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityPostDetailPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? palette.primaryText : palette.mutedText,
            fontSize: 16,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.indent,
    required this.avatarUrl,
    required this.imageUrls,
    required this.onReply,
    required this.onLike,
    required this.onReport,
  });

  final CommunityComment comment;
  final double indent;
  final String avatarUrl;
  final List<String> imageUrls;
  final VoidCallback onReply;
  final VoidCallback onLike;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityPostDetailPalette.of(context);
    final displayName = comment.isAnonymous
        ? _t(context, '匿名用户', 'Anonymous')
        : comment.authorName;
    final replyTarget = comment.replyToMemberName.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onReply,
      child: Padding(
        padding: EdgeInsets.only(left: indent),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CommentAvatar(
              avatarUrl: avatarUrl,
              isAnonymous: comment.isAnonymous,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    replyTarget.isNotEmpty
                        ? '$displayName  >  $replyTarget'
                        : displayName,
                    style: TextStyle(
                      color: palette.secondaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comment.content,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 18,
                      height: 1.55,
                    ),
                  ),
                  if (imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _CommentAttachmentGrid(urls: imageUrls),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        _timeLabel(context, comment.createTime),
                        style: TextStyle(
                          color: palette.mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 18),
                      GestureDetector(
                        onTap: onReply,
                        child: Text(
                          _t(context, '回复', 'Reply'),
                          style: TextStyle(
                            color: palette.secondaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                IconButton(
                  onPressed: onLike,
                  icon: Icon(
                    comment.isLiked
                        ? Icons.thumb_up_alt_rounded
                        : Icons.thumb_up_alt_outlined,
                    color: comment.isLiked
                        ? const Color(0xFFFF9585)
                        : palette.primaryText,
                  ),
                ),
                Text(
                  comment.likeCount > 0 ? '${comment.likeCount}' : '',
                  style: TextStyle(
                    color: comment.isLiked
                        ? const Color(0xFFFF9585)
                        : palette.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  tooltip: _t(context, '举报评论', 'Report comment'),
                  onPressed: onReport,
                  icon: Icon(Icons.flag_outlined, color: palette.secondaryText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({required this.avatarUrl, required this.isAnonymous});

  final String avatarUrl;
  final bool isAnonymous;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityPostDetailPalette.of(context);
    if (!isAnonymous && avatarUrl.trim().isNotEmpty) {
      return CircleAvatar(radius: 28, backgroundImage: NetworkImage(avatarUrl));
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: palette.avatarBackground,
      child: Icon(
        isAnonymous ? Icons.visibility_off_outlined : Icons.person_outline,
        color: const Color(0xFFFF9585),
      ),
    );
  }
}

class _CommentAttachmentGrid extends StatelessWidget {
  const _CommentAttachmentGrid({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final url in urls.take(3))
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              url,
              width: 106,
              height: 106,
              fit: BoxFit.cover,
            ),
          ),
      ],
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.isAnonymous,
    required this.replyTarget,
    required this.attachments,
    required this.onDismissReply,
    required this.onRemoveAttachment,
    required this.onPickImage,
    required this.onToggleAnonymous,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final bool isAnonymous;
  final CommunityComment? replyTarget;
  final List<_ComposerAttachment> attachments;
  final VoidCallback onDismissReply;
  final ValueChanged<String> onRemoveAttachment;
  final VoidCallback onPickImage;
  final VoidCallback onToggleAnonymous;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityPostDetailPalette.of(context);
    return Material(
      color: palette.cardBackground,
      elevation: 10,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (replyTarget != null)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: palette.softBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _t(
                          context,
                          '回复 ${replyTarget!.authorName}',
                          'Reply to ${replyTarget!.authorName}',
                        ),
                        style: TextStyle(
                          color: palette.bodyText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onDismissReply,
                      child: Icon(
                        Icons.close_rounded,
                        color: palette.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            if (attachments.isNotEmpty) ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final attachment in attachments)
                    _ComposerAttachmentTile(
                      attachment: attachment,
                      onRemove: () => onRemoveAttachment(attachment.id),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: _t(context, '说两句...', 'Say something...'),
                filled: true,
                fillColor: palette.softBackground,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(18),
                ),
                hintStyle: TextStyle(color: palette.secondaryText),
              ),
              style: TextStyle(color: palette.primaryText),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: onToggleAnonymous,
                  tooltip: _t(context, '匿名评论', 'Anonymous reply'),
                  icon: Icon(
                    isAnonymous
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_outlined,
                    color: isAnonymous
                        ? const Color(0xFF5A81DA)
                        : palette.bodyText,
                  ),
                ),
                IconButton(
                  onPressed: onPickImage,
                  tooltip: _t(context, '添加图片', 'Add image'),
                  icon: Icon(Icons.image_outlined, color: palette.bodyText),
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5A81DA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  onPressed: isSending ? null : onSend,
                  child: isSending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(_t(context, '发送', 'Send')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerAttachmentTile extends StatelessWidget {
  const _ComposerAttachmentTile({
    required this.attachment,
    required this.onRemove,
  });

  final _ComposerAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 106,
            height: 106,
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
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
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

class _CommentStatus extends StatelessWidget {
  const _CommentStatus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = _CommunityPostDetailPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(message, style: TextStyle(color: palette.secondaryText)),
      ),
    );
  }
}

class _CommentLoading extends StatelessWidget {
  const _CommentLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ComposerAttachment {
  const _ComposerAttachment({
    required this.id,
    required this.localPath,
    required this.remoteUrl,
    required this.isUploading,
  });

  final String id;
  final String localPath;
  final String remoteUrl;
  final bool isUploading;

  _ComposerAttachment copyWith({
    String? id,
    String? localPath,
    String? remoteUrl,
    bool? isUploading,
  }) {
    return _ComposerAttachment(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

String _timeLabel(BuildContext context, String value) {
  final date = DateTime.tryParse(value);
  if (date == null) {
    return value;
  }
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) {
    final minutes = diff.inMinutes.clamp(1, 59);
    return Localizations.localeOf(context).languageCode == 'zh'
        ? '${minutes}分钟前'
        : '${minutes}m ago';
  }
  if (diff.inHours < 24) {
    return Localizations.localeOf(context).languageCode == 'zh'
        ? '${diff.inHours}小时前'
        : '${diff.inHours}h ago';
  }
  if (diff.inDays < 7) {
    return Localizations.localeOf(context).languageCode == 'zh'
        ? '${diff.inDays}天前'
        : '${diff.inDays}d ago';
  }
  return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

class _CommunityPostDetailPalette {
  const _CommunityPostDetailPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.softBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.bodyText,
    required this.avatarBackground,
  });

  factory _CommunityPostDetailPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _CommunityPostDetailPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      softBackground: scheme.surfaceContainerLow,
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      mutedText: isDark
          ? scheme.onSurfaceVariant.withValues(alpha: 0.8)
          : const Color(0xFF7D828A),
      bodyText: isDark
          ? scheme.onSurface.withValues(alpha: 0.82)
          : const Color(0xFF52555D),
      avatarBackground: isDark
          ? scheme.primaryContainer.withValues(alpha: 0.28)
          : const Color(0xFFF8E3DB),
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color softBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color bodyText;
  final Color avatarBackground;
}
