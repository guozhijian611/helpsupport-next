import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final palette = _MaterialDetailPalette.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final detailQuery = MaterialDetailQuery(
      id: widget.materialId,
      locale: locale,
    );
    final material = ref.watch(materialDetailProvider(detailQuery));
    final comments = ref.watch(materialCommentsProvider(widget.materialId));

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        title: Text(_t(context, '素材详情', 'Material')),
      ),
      body: SafeArea(
        child: material.when(
          data: (item) {
            _saveHistoryOnce(item);
            if (item.materialType == 'entertainment') {
              return _EntertainmentDetailBody(
                item: item,
                comments: comments,
                commentController: _commentController,
                isSending: _isSending,
                onSend: _sendComment,
              );
            }
            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(materialDetailProvider(detailQuery));
                      ref.invalidate(
                        materialCommentsProvider(widget.materialId),
                      );
                      await Future.wait([
                        ref.read(materialDetailProvider(detailQuery).future),
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
      final locale = Localizations.localeOf(context).toLanguageTag();
      ref.invalidate(
        materialDetailProvider(
          MaterialDetailQuery(id: widget.materialId, locale: locale),
        ),
      );
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

class _EntertainmentDetailBody extends StatelessWidget {
  const _EntertainmentDetailBody({
    required this.item,
    required this.comments,
    required this.commentController,
    required this.isSending,
    required this.onSend,
  });

  final MaterialItem item;
  final AsyncValue<MaterialPage<MaterialComment>> comments;
  final TextEditingController commentController;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialDetailPalette.of(context);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _EntertainmentHero(item: item),
              Container(
                color: palette.cardBackground,
                padding: const EdgeInsets.fromLTRB(18, 34, 18, 22),
                child: Column(
                  children: [
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _t(context, '官方发布', 'Official'),
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _MaterialContentSection(item: item),
                    const SizedBox(height: 24),
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
                                    padding: const EdgeInsets.only(bottom: 12),
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
            ],
          ),
        ),
        _CommentComposer(
          controller: commentController,
          isSending: isSending,
          onSend: onSend,
        ),
      ],
    );
  }
}

class _EntertainmentHero extends ConsumerWidget {
  const _EntertainmentHero({required this.item});

  final MaterialItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _MaterialDetailPalette.of(context);
    final apiClient = ref.watch(apiClientProvider);
    final coverUrl = apiClient.resolveUrl(item.coverUrl);

    return Container(
      color: palette.entertainmentHeroBackground,
      padding: const EdgeInsets.fromLTRB(18, 54, 18, 50),
      child: Column(
        children: [
          SizedBox(
            width: 210,
            height: 284,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: coverUrl.isNotEmpty
                  ? Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const _EntertainmentCoverShell(),
                    )
                  : const _EntertainmentCoverShell(),
            ),
          ),
          const SizedBox(height: 54),
          Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
            decoration: BoxDecoration(
              color: palette.entertainmentStatsBackground,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _EntertainmentStatTile(
                        value: _mediaTitle(context, item.mediaType),
                        label: _t(context, '所属分类', 'Category'),
                      ),
                    ),
                    Expanded(
                      child: _EntertainmentStatTile(
                        value: _resourceForm(context, item.mediaType),
                        label: _t(context, '资源形式', 'Format'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _EntertainmentStatTile(
                        value: '${item.viewCount}',
                        label: _t(context, '浏览量', 'Views'),
                      ),
                    ),
                    Expanded(
                      child: _EntertainmentStatTile(
                        value: _dateOnly(item.createTime),
                        label: _t(context, '发布时间', 'Published'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EntertainmentCoverShell extends StatelessWidget {
  const _EntertainmentCoverShell();

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialDetailPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: palette.softBackground),
      child: Center(
        child: Icon(
          Icons.auto_stories_rounded,
          size: 56,
          color: palette.secondaryText.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _EntertainmentStatTile extends StatelessWidget {
  const _EntertainmentStatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialDetailPalette.of(context);
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.secondaryText,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MaterialHero extends ConsumerWidget {
  const _MaterialHero({required this.item});

  final MaterialItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _MaterialDetailPalette.of(context);
    final apiClient = ref.watch(apiClientProvider);
    final url = apiClient.resolveUrl(item.coverUrl);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: palette.cardBackground,
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
            style: TextStyle(
              color: palette.primaryText,
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
            style: TextStyle(
              color: palette.bodyText,
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
                style: TextStyle(
                  color: palette.secondaryText,
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
      final locale = Localizations.localeOf(context).toLanguageTag();
      ref.invalidate(
        materialDetailProvider(
          MaterialDetailQuery(id: item.id, locale: locale),
        ),
      );
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
      final locale = Localizations.localeOf(context).toLanguageTag();
      ref.invalidate(
        materialDetailProvider(
          MaterialDetailQuery(id: item.id, locale: locale),
        ),
      );
      ref.invalidate(
        materialCollectionsProvider(
          MaterialListQuery(
            materialType: '',
            categoryId: 0,
            keyword: '',
            locale: locale,
          ),
        ),
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    }
  }
}

class _MaterialContentSection extends ConsumerWidget {
  const _MaterialContentSection({required this.item});

  final MaterialItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _MaterialDetailPalette.of(context);
    final apiClient = ref.watch(apiClientProvider);
    final contentUrl = apiClient.resolveUrl(item.contentUrl);
    final isGame =
        item.materialType == 'entertainment' && item.mediaType == 'link';
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(context, '内容概览', 'Overview'),
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (item.contentText.isNotEmpty)
            SelectableText(
              item.contentText,
              style: TextStyle(
                color: palette.bodyText,
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
              style: TextStyle(
                color: palette.bodyText,
                fontSize: 15,
                height: 1.7,
              ),
            ),
          if (contentUrl.trim().isNotEmpty ||
              item.contentText.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => _openContent(context, item, contentUrl),
              icon: Icon(
                isGame
                    ? Icons.sports_esports_rounded
                    : Icons.open_in_new_rounded,
              ),
              label: Text(
                isGame
                    ? _t(context, '开始游戏', 'Play')
                    : _t(context, '打开资源', 'Open resource'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openContent(
    BuildContext context,
    MaterialItem item,
    String url,
  ) async {
    final trimmed = url.trim();
    if (trimmed.isNotEmpty) {
      final uri = Uri.tryParse(trimmed);
      if (uri == null || !uri.hasScheme) {
        context.showCenteredNotice(
          _t(context, '内容地址无效', 'Invalid content URL'),
        );
        return;
      }
    }
    context.push('/materials/resource/${item.id}', extra: item);
  }
}

class _MaterialCommentCard extends ConsumerWidget {
  const _MaterialCommentCard({required this.comment});

  final MaterialComment comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _MaterialDetailPalette.of(context);
    final apiClient = ref.watch(apiClientProvider);
    final avatarUrl = apiClient.resolveUrl(comment.authorAvatar);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: palette.avatarBackground,
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
                    fontSize: 16,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      comment.createTime,
                      style: TextStyle(
                        color: palette.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      _t(context, '回复', 'Reply'),
                      style: TextStyle(
                        color: palette.secondaryText,
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
                  : palette.bodyText,
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
      final locale = Localizations.localeOf(context).toLanguageTag();
      ref.invalidate(
        materialDetailProvider(
          MaterialDetailQuery(id: comment.materialId, locale: locale),
        ),
      );
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
    final palette = _MaterialDetailPalette.of(context);
    return Material(
      color: palette.cardBackground,
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
                fillColor: palette.softBackground,
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
    final palette = _MaterialDetailPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.softBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.bodyText,
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
    final palette = _MaterialDetailPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? palette.activeSoftBackground : palette.softBackground,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? const Color(0xFFFF9585) : palette.bodyText,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFFFF9585) : palette.bodyText,
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
    final palette = _MaterialDetailPalette.of(context);
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: palette.primaryText,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$count',
          style: TextStyle(
            color: palette.secondaryText,
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
    final palette = _MaterialDetailPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.secondaryText, height: 1.5),
        ),
      ),
    );
  }
}

String _mediaTitle(BuildContext context, String mediaType) {
  return switch (mediaType) {
    'video' => _t(context, '视频', 'Video'),
    'audio' => _t(context, '音频', 'Audio'),
    'txt' => 'TXT',
    'pdf' => 'PDF',
    'epub' => 'EPUB',
    'mp4' => 'MP4',
    'mov' => 'MOV',
    'mp3' => 'MP3',
    'link' => _t(context, '游戏', 'Game'),
    _ => _t(context, '文章', 'Article'),
  };
}

String _resourceForm(BuildContext context, String mediaType) {
  return switch (mediaType) {
    'txt' || 'epub' || 'pdf' => _t(context, '文件资源', 'File'),
    'video' || 'mp4' || 'mov' => _t(context, '视频资源', 'Video'),
    'audio' || 'mp3' => _t(context, '音频资源', 'Audio'),
    'link' => _t(context, '链接资源', 'Link'),
    _ => _t(context, '图文内容', 'Article'),
  };
}

String _dateOnly(String value) {
  final trimmed = value.trim();
  if (trimmed.length >= 10) {
    return trimmed.substring(0, 10);
  }
  return trimmed.isEmpty ? '--' : trimmed;
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

class _MaterialDetailPalette {
  const _MaterialDetailPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.softBackground,
    required this.activeSoftBackground,
    required this.avatarBackground,
    required this.entertainmentHeroBackground,
    required this.entertainmentStatsBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.bodyText,
  });

  factory _MaterialDetailPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _MaterialDetailPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      softBackground: scheme.surfaceContainerLow,
      activeSoftBackground: isDark
          ? const Color(0x33FF9585)
          : const Color(0xFFFFF1ED),
      avatarBackground: isDark
          ? scheme.primaryContainer.withValues(alpha: 0.28)
          : const Color(0xFFF8E3DB),
      entertainmentHeroBackground: isDark
          ? const Color(0xFF20383E)
          : const Color(0xFFC8E5EB),
      entertainmentStatsBackground: isDark
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.9)
          : const Color(0xFFF8FBFD),
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      mutedText: isDark
          ? scheme.onSurfaceVariant.withValues(alpha: 0.8)
          : const Color(0xFFB0B3BA),
      bodyText: isDark
          ? scheme.onSurface.withValues(alpha: 0.84)
          : const Color(0xFF4A4D55),
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color softBackground;
  final Color activeSoftBackground;
  final Color avatarBackground;
  final Color entertainmentHeroBackground;
  final Color entertainmentStatsBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color bodyText;
}
