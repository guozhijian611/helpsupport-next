import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../application/material_controller.dart';
import '../data/material_models.dart';

class MaterialDetailScreen extends ConsumerStatefulWidget {
  const MaterialDetailScreen({super.key, required this.materialId});

  final int materialId;

  @override
  ConsumerState<MaterialDetailScreen> createState() =>
      _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends ConsumerState<MaterialDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSending = false;
  bool _historySaved = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final material = ref.watch(materialDetailProvider(widget.materialId));
    final comments = ref.watch(materialCommentsProvider(widget.materialId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(title: Text(_t(context, '素材详情', 'Material'))),
      body: SafeArea(
        child: material.when(
          data: (item) {
            _saveHistoryOnce(item);
            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(materialDetailProvider(widget.materialId));
                      ref.invalidate(
                        materialCommentsProvider(widget.materialId),
                      );
                      await Future.wait([
                        ref.read(
                          materialDetailProvider(widget.materialId).future,
                        ),
                        ref.read(
                          materialCommentsProvider(widget.materialId).future,
                        ),
                      ]);
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
                      children: [
                        _MaterialHero(item: item),
                        const SizedBox(height: 18),
                        _MaterialContentSection(item: item),
                        const SizedBox(height: 18),
                        _SectionTitle(
                          title: _t(context, '评论区', 'Comments'),
                          count: item.commentCount,
                        ),
                        const SizedBox(height: 12),
                        comments.when(
                          data: (page) => page.list.isEmpty
                              ? _CommentEmptyState(
                                  text: _t(
                                    context,
                                    '还没有评论，留下你的第一条感受。',
                                    'No comments yet. Share the first thought.',
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (final comment in page.list)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _MaterialCommentCard(
                                          comment: comment,
                                        ),
                                      ),
                                  ],
                                ),
                          error: (error, _) =>
                              _CommentEmptyState(text: error.toString()),
                          loading: () => const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _CommentComposer(
                  controller: _commentController,
                  isSending: _isSending,
                  onSend: _sendComment,
                ),
              ],
            );
          },
          error: (error, _) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  void _saveHistoryOnce(MaterialItem item) {
    if (_historySaved) {
      return;
    }
    _historySaved = true;
    unawaited(
      ref
          .read(materialRepositoryProvider)
          .saveHistory(
            materialId: item.id,
            title: item.title,
            route: '/materials/detail/${item.id}',
            durationSeconds: item.durationSeconds,
          ),
    );
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref
          .read(materialRepositoryProvider)
          .createComment(materialId: widget.materialId, content: content);
      _commentController.clear();
      ref.invalidate(materialDetailProvider(widget.materialId));
      ref.invalidate(materialCommentsProvider(widget.materialId));
    } on Object catch (error) {
      if (!mounted) {
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

class _MaterialHero extends ConsumerWidget {
  const _MaterialHero({required this.item});

  final MaterialItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiClient = ref.watch(apiClientProvider);
    final url = apiClient.resolveUrl(item.coverUrl);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (url.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                url,
                height: 188,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          if (url.isNotEmpty) const SizedBox(height: 16),
          Text(
            item.title,
            style: const TextStyle(
              color: Color(0xFF303236),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.summary.isNotEmpty
                ? item.summary
                : _t(
                    context,
                    '打开内容详情后，你可以继续阅读、收藏或发表评论。',
                    'Open the content to read more, save it, or leave a comment.',
                  ),
            style: const TextStyle(
              color: Color(0xFF5E6470),
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(label: _mediaTitle(context, item.mediaType)),
              if (item.isRecommended)
                _HeroChip(label: _t(context, '推荐', 'Recommended')),
              ...item.tags.take(3).map((tag) => _HeroChip(label: tag)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ActionStatButton(
                icon: item.isLiked
                    ? Icons.thumb_up_alt_rounded
                    : Icons.thumb_up_alt_outlined,
                label: '${item.likeCount}',
                onTap: () => _toggleLike(context, ref),
                active: item.isLiked,
              ),
              const SizedBox(width: 10),
              _ActionStatButton(
                icon: item.isCollected
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: '${item.collectCount}',
                onTap: () => _toggleCollect(context, ref),
                active: item.isCollected,
              ),
              const SizedBox(width: 10),
              _ActionStatButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${item.commentCount}',
                onTap: null,
                active: false,
              ),
              const Spacer(),
              Text(
                item.createTime,
                style: const TextStyle(
                  color: Color(0xFF96999F),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(materialRepositoryProvider).toggleLike(item.id);
      ref.invalidate(materialDetailProvider(item.id));
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }

  Future<void> _toggleCollect(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(materialRepositoryProvider).toggleCollect(item.id);
      ref.invalidate(materialDetailProvider(item.id));
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }
}

class _MaterialContentSection extends StatelessWidget {
  const _MaterialContentSection({required this.item});

  final MaterialItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(context, '内容概览', 'Overview'),
            style: const TextStyle(
              color: Color(0xFF303236),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (item.contentText.isNotEmpty)
            SelectableText(
              item.contentText,
              style: const TextStyle(
                color: Color(0xFF4A4D55),
                fontSize: 15,
                height: 1.75,
              ),
            )
          else
            Text(
              item.summary.isNotEmpty
                  ? item.summary
                  : _t(
                      context,
                      '当前内容主要通过外部地址提供，你可以点击下面的按钮继续查看。',
                      'This content is mainly provided through an external source.',
                    ),
              style: const TextStyle(
                color: Color(0xFF4A4D55),
                fontSize: 15,
                height: 1.7,
              ),
            ),
          if (item.contentUrl.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => _openContent(context, item.contentUrl),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(_t(context, '打开原内容', 'Open source')),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openContent(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      context.showCenteredNotice(_t(context, '内容地址无效', 'Invalid content URL'));
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      context.showCenteredNotice(
        _t(context, '无法打开内容链接', 'Unable to open link'),
      );
    }
  }
}

class _MaterialCommentCard extends ConsumerWidget {
  const _MaterialCommentCard({required this.comment});

  final MaterialComment comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiClient = ref.watch(apiClientProvider);
    final avatarUrl = apiClient.resolveUrl(comment.authorAvatar);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFF8E3DB),
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFFFF9585),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.authorName,
                  style: const TextStyle(
                    color: Color(0xFF979CA4),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: Color(0xFF303236),
                    fontSize: 16,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      comment.createTime,
                      style: const TextStyle(
                        color: Color(0xFFB0B3BA),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      _t(context, '回复', 'Reply'),
                      style: const TextStyle(
                        color: Color(0xFF9CA1AA),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: _t(context, '点赞评论', 'Like comment'),
            onPressed: () => _toggleCommentLike(context, ref),
            icon: Icon(
              comment.isLiked
                  ? Icons.thumb_up_alt_rounded
                  : Icons.thumb_up_alt_outlined,
              color: comment.isLiked
                  ? const Color(0xFFFF9585)
                  : const Color(0xFF4A4D55),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCommentLike(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(materialRepositoryProvider).toggleCommentLike(comment.id);
      ref.invalidate(materialCommentsProvider(comment.materialId));
      ref.invalidate(materialDetailProvider(comment.materialId));
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          10 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: _t(context, '说两句...', 'Say something...'),
                filled: true,
                fillColor: const Color(0xFFF4F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.sentiment_satisfied_alt_outlined),
                const SizedBox(width: 20),
                const Icon(Icons.image_outlined),
                const SizedBox(width: 20),
                const Icon(Icons.mood_outlined),
                const Spacer(),
                FilledButton(
                  onPressed: isSending ? null : onSend,
                  child: isSending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
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

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4A4D55),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionStatButton extends StatelessWidget {
  const _ActionStatButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.active,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFF1ED) : const Color(0xFFF4F5F9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? const Color(0xFFFF9585) : const Color(0xFF6D727A),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? const Color(0xFFFF9585)
                    : const Color(0xFF6D727A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF303236),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$count',
          style: const TextStyle(
            color: Color(0xFF9CA1AA),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CommentEmptyState extends StatelessWidget {
  const _CommentEmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF7D828A), height: 1.5),
        ),
      ),
    );
  }
}

String _mediaTitle(BuildContext context, String mediaType) {
  return switch (mediaType) {
    'video' => _t(context, '视频', 'Video'),
    'audio' => _t(context, '音频', 'Audio'),
    'pdf' => 'PDF',
    'epub' => 'EPUB',
    'link' => _t(context, '链接', 'Link'),
    _ => _t(context, '文章', 'Article'),
  };
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
