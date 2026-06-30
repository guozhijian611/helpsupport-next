import 'dart:async';

import 'package:flutter/material.dart' hide MaterialPage;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xml/xml.dart';

import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../application/material_controller.dart';
import '../data/material_models.dart';
import '../data/material_music_support.dart';

enum MaterialDetailInitialSection { overview, comments }

class MaterialDetailScreen extends ConsumerStatefulWidget {
  const MaterialDetailScreen({
    super.key,
    required this.materialId,
    this.initialItem,
    this.initialSection = MaterialDetailInitialSection.overview,
  });

  final int materialId;
  final MaterialItem? initialItem;
  final MaterialDetailInitialSection initialSection;

  @override
  ConsumerState<MaterialDetailScreen> createState() =>
      _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends ConsumerState<MaterialDetailScreen> {
  final _commentController = TextEditingController();
  final _detailScrollController = ScrollController();
  final _overviewKey = GlobalKey();
  final _commentsKey = GlobalKey();
  bool _isSending = false;
  bool _historySaved = false;
  bool _didRevealInitialSection = false;
  MaterialComment? _replyTarget;

  @override
  void dispose() {
    _commentController.dispose();
    _detailScrollController.dispose();
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
    final fallback = widget.initialItem;

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
        title: Text(
          material.maybeWhen(
            data: (item) => item.title,
            orElse: () => fallback?.title ?? _t(context, '素材详情', 'Material'),
          ),
        ),
      ),
      body: SafeArea(
        child: material.when(
          data: (item) => _buildDetailBody(item, comments, detailQuery),
          error: (error, _) => fallback == null
              ? Center(child: Text(error.toString()))
              : _buildDetailBody(fallback, comments, detailQuery),
          loading: () => fallback == null
              ? const Center(child: CircularProgressIndicator())
              : _buildDetailBody(fallback, comments, detailQuery),
        ),
      ),
    );
  }

  Widget _buildDetailBody(
    MaterialItem item,
    AsyncValue<MaterialPage<MaterialComment>> comments,
    MaterialDetailQuery detailQuery,
  ) {
    _saveHistoryOnce(item);
    _revealInitialSectionOnce();
    if (item.materialType == 'entertainment' &&
        MaterialMusicSupport.isAudioItem(item)) {
      return _EntertainmentMusicDetailBody(
        item: item,
        comments: comments,
        commentController: _commentController,
        isSending: _isSending,
        replyTarget: _replyTarget,
        onReply: _replyComment,
        onReport: _reportComment,
        onDismissReply: () => setState(() => _replyTarget = null),
        onSend: _sendComment,
        scrollController: _detailScrollController,
        overviewKey: _overviewKey,
        commentsKey: _commentsKey,
      );
    }
    if (item.materialType == 'entertainment') {
      return _EntertainmentDetailBody(
        item: item,
        comments: comments,
        commentController: _commentController,
        isSending: _isSending,
        replyTarget: _replyTarget,
        onReply: _replyComment,
        onReport: _reportComment,
        onDismissReply: () => setState(() => _replyTarget = null),
        onSend: _sendComment,
        scrollController: _detailScrollController,
        overviewKey: _overviewKey,
        commentsKey: _commentsKey,
      );
    }
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(materialDetailProvider(detailQuery));
              ref.invalidate(materialCommentsProvider(widget.materialId));
              await Future.wait([
                ref.read(materialDetailProvider(detailQuery).future),
                ref.read(materialCommentsProvider(widget.materialId).future),
              ]);
            },
            child: ListView(
              controller: _detailScrollController,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
              children: [
                _MaterialHero(item: item),
                const SizedBox(height: 18),
                KeyedSubtree(
                  key: _overviewKey,
                  child: _MaterialContentSection(item: item),
                ),
                const SizedBox(height: 18),
                KeyedSubtree(
                  key: _commentsKey,
                  child: _SectionTitle(
                    title: _t(context, '评论区', 'Comments'),
                    count: item.commentCount,
                  ),
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
                            for (final node in _commentNodes(page.list))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _MaterialCommentThread(
                                  node: node,
                                  depth: 0,
                                  onReply: _replyComment,
                                  onReport: _reportComment,
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
          replyTarget: _replyTarget,
          onDismissReply: () => setState(() => _replyTarget = null),
          onSend: _sendComment,
        ),
      ],
    );
  }

  void _revealInitialSectionOnce() {
    if (_didRevealInitialSection) {
      return;
    }
    _didRevealInitialSection = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final targetContext =
          (widget.initialSection == MaterialDetailInitialSection.comments
                  ? _commentsKey
                  : _overviewKey)
              .currentContext;
      if (targetContext == null) {
        return;
      }
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment:
            widget.initialSection == MaterialDetailInitialSection.comments
            ? 0.04
            : 0,
      );
    });
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

  List<_MaterialCommentNode> _commentNodes(List<MaterialComment> source) {
    return _materialCommentNodes(source);
  }

  void _replyComment(MaterialComment comment) {
    setState(() => _replyTarget = comment);
  }

  Future<void> _reportComment(MaterialComment comment) async {
    final draft = await _showMaterialReportDialog(
      context,
      title: _t(context, '举报评论', 'Report comment'),
    );
    if (draft == null) {
      return;
    }
    try {
      await ref
          .read(materialRepositoryProvider)
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

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSending) {
      return;
    }
    final locale = Localizations.localeOf(context).toLanguageTag();

    setState(() => _isSending = true);
    try {
      await ref
          .read(materialRepositoryProvider)
          .createComment(
            materialId: widget.materialId,
            content: content,
            parentId: _replyTarget == null
                ? null
                : (_replyTarget!.parentId > 0
                      ? _replyTarget!.parentId
                      : _replyTarget!.id),
          );
      _commentController.clear();
      ref.invalidate(
        materialDetailProvider(
          MaterialDetailQuery(id: widget.materialId, locale: locale),
        ),
      );
      ref.invalidate(materialCommentsProvider(widget.materialId));
      if (mounted) {
        setState(() => _replyTarget = null);
      }
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

class _MaterialCommentNode {
  const _MaterialCommentNode({required this.comment, required this.replies});

  final MaterialComment comment;
  final List<_MaterialCommentNode> replies;
}

List<_MaterialCommentNode> _materialCommentNodes(List<MaterialComment> source) {
  final repliesByParent = <int, List<MaterialComment>>{};
  final roots = <MaterialComment>[];
  for (final comment in source) {
    if (comment.parentId > 0) {
      repliesByParent.putIfAbsent(comment.parentId, () => []).add(comment);
    } else {
      roots.add(comment);
    }
  }
  roots.sort((left, right) => left.id.compareTo(right.id));
  for (final replies in repliesByParent.values) {
    replies.sort((left, right) => left.id.compareTo(right.id));
  }

  _MaterialCommentNode buildNode(MaterialComment comment) {
    return _MaterialCommentNode(
      comment: comment,
      replies: (repliesByParent[comment.id] ?? const <MaterialComment>[])
          .map(buildNode)
          .toList(growable: false),
    );
  }

  return roots.map(buildNode).toList(growable: false);
}

class _EntertainmentMusicDetailBody extends StatelessWidget {
  const _EntertainmentMusicDetailBody({
    required this.item,
    required this.comments,
    required this.commentController,
    required this.isSending,
    required this.replyTarget,
    required this.onReply,
    required this.onReport,
    required this.onDismissReply,
    required this.onSend,
    required this.scrollController,
    required this.overviewKey,
    required this.commentsKey,
  });

  final MaterialItem item;
  final AsyncValue<MaterialPage<MaterialComment>> comments;
  final TextEditingController commentController;
  final bool isSending;
  final MaterialComment? replyTarget;
  final ValueChanged<MaterialComment> onReply;
  final ValueChanged<MaterialComment> onReport;
  final VoidCallback onDismissReply;
  final VoidCallback onSend;
  final ScrollController scrollController;
  final GlobalKey overviewKey;
  final GlobalKey commentsKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
            children: [
              _MusicDetailHero(item: item),
              const SizedBox(height: 18),
              KeyedSubtree(
                key: overviewKey,
                child: _MusicDetailOverviewCard(item: item),
              ),
              const SizedBox(height: 24),
              KeyedSubtree(
                key: commentsKey,
                child: _SectionTitle(
                  title: _t(context, '评论区', 'Comments'),
                  count: item.commentCount,
                ),
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
                          for (final node in _materialCommentNodes(page.list))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _MaterialCommentThread(
                                node: node,
                                depth: 0,
                                onReply: onReply,
                                onReport: onReport,
                              ),
                            ),
                        ],
                      ),
                error: (error, _) => _CommentEmptyState(text: error.toString()),
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          ),
        ),
        _CommentComposer(
          controller: commentController,
          isSending: isSending,
          replyTarget: replyTarget,
          onDismissReply: onDismissReply,
          onSend: onSend,
        ),
      ],
    );
  }
}

class _EntertainmentDetailBody extends StatelessWidget {
  const _EntertainmentDetailBody({
    required this.item,
    required this.comments,
    required this.commentController,
    required this.isSending,
    required this.replyTarget,
    required this.onReply,
    required this.onReport,
    required this.onDismissReply,
    required this.onSend,
    required this.scrollController,
    required this.overviewKey,
    required this.commentsKey,
  });

  final MaterialItem item;
  final AsyncValue<MaterialPage<MaterialComment>> comments;
  final TextEditingController commentController;
  final bool isSending;
  final MaterialComment? replyTarget;
  final ValueChanged<MaterialComment> onReply;
  final ValueChanged<MaterialComment> onReport;
  final VoidCallback onDismissReply;
  final VoidCallback onSend;
  final ScrollController scrollController;
  final GlobalKey overviewKey;
  final GlobalKey commentsKey;

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialDetailPalette.of(context);

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scrollController,
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
                    KeyedSubtree(
                      key: overviewKey,
                      child: _MaterialContentSection(item: item),
                    ),
                    const SizedBox(height: 24),
                    Divider(color: palette.outline, height: 1),
                    const SizedBox(height: 24),
                    KeyedSubtree(
                      key: commentsKey,
                      child: _SectionTitle(
                        title: _t(context, '评论区', 'Comments'),
                        count: item.commentCount,
                      ),
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
                                for (final node in _materialCommentNodes(
                                  page.list,
                                ))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _MaterialCommentThread(
                                      node: node,
                                      depth: 0,
                                      onReply: onReply,
                                      onReport: onReport,
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
          replyTarget: replyTarget,
          onDismissReply: onDismissReply,
          onSend: onSend,
        ),
      ],
    );
  }
}

class _MusicDetailHero extends ConsumerWidget {
  const _MusicDetailHero({required this.item});

  final MaterialItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _MaterialDetailPalette.of(context);
    final apiClient = ref.watch(apiClientProvider);
    final coverUrl = apiClient.resolveUrl(item.coverUrl);
    final artist = item.artist.trim().isNotEmpty
        ? item.artist.trim()
        : _t(context, '官方发布', 'Official');
    final album = item.album.trim().isNotEmpty
        ? item.album.trim()
        : item.summary.trim().isNotEmpty
        ? item.summary.trim()
        : _t(context, '单曲作品', 'Single');

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  coverUrl.isNotEmpty
                      ? Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, loadingProgress) =>
                              loadingProgress == null
                              ? child
                              : const _MusicDetailCoverShell(),
                          errorBuilder: (_, _, _) =>
                              const _MusicDetailCoverShell(),
                        )
                      : const _MusicDetailCoverShell(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$artist · $album',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.secondaryText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _MusicMetaChip(
                icon: Icons.album_rounded,
                label: _mediaTitle(context, item.mediaType),
              ),
              _MusicMetaChip(
                icon: Icons.headphones_rounded,
                label: '${item.viewCount}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MusicDetailCoverShell extends StatelessWidget {
  const _MusicDetailCoverShell();

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialDetailPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.activeSoftBackground, palette.softBackground],
        ),
      ),
      child: Center(
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: palette.cardBackground.withValues(alpha: 0.92),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Color(0xFFFF9585),
            size: 46,
          ),
        ),
      ),
    );
  }
}

class _MusicMetaChip extends StatelessWidget {
  const _MusicMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialDetailPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: palette.softBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: palette.secondaryText),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: palette.bodyText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MusicDetailOverviewCard extends ConsumerWidget {
  const _MusicDetailOverviewCard({required this.item});

  final MaterialItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _MaterialDetailPalette.of(context);
    final overviewText = _materialRichTextToPlainText(item.contentText);
    final summaryText = _materialRichTextToPlainText(item.summary);
    final displayText = overviewText.isNotEmpty
        ? overviewText
        : summaryText.isNotEmpty
        ? summaryText
        : item.summary.trim().isNotEmpty
        ? item.summary.trim()
        : _t(
            context,
            '这首歌曲暂时还没有补充介绍。',
            'No description has been added for this track yet.',
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(context, '歌曲介绍', 'Song Overview'),
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            displayText,
            style: TextStyle(
              color: palette.bodyText,
              fontSize: 15,
              height: 1.72,
            ),
          ),
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.tags
                  .take(4)
                  .map((tag) => _HeroChip(label: tag))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
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
                      loadingBuilder: (_, child, loadingProgress) =>
                          loadingProgress == null
                          ? child
                          : const _EntertainmentCoverShell(),
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

class _MaterialDetailImageLoadingShell extends StatelessWidget {
  const _MaterialDetailImageLoadingShell();

  @override
  Widget build(BuildContext context) {
    final palette = _MaterialDetailPalette.of(context);
    return SizedBox(
      height: 188,
      width: double.infinity,
      child: ColoredBox(
        color: palette.softBackground,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: palette.secondaryText.withValues(alpha: 0.58),
          ),
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
                loadingBuilder: (_, child, loadingProgress) =>
                    loadingProgress == null
                    ? child
                    : const _MaterialDetailImageLoadingShell(),
                errorBuilder: (_, _, _) =>
                    const _MaterialDetailImageLoadingShell(),
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
              const SizedBox(width: 10),
              IconButton(
                tooltip: _t(context, '举报素材', 'Report material'),
                visualDensity: VisualDensity.compact,
                onPressed: () => _reportMaterial(context, ref),
                icon: Icon(
                  Icons.flag_outlined,
                  color: palette.secondaryText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.createTime,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: palette.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(BuildContext context, WidgetRef ref) async {
    final locale = Localizations.localeOf(context).toLanguageTag();
    try {
      await ref.read(materialRepositoryProvider).toggleLike(item.id);
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
    final locale = Localizations.localeOf(context).toLanguageTag();
    try {
      await ref.read(materialRepositoryProvider).toggleCollect(item.id);
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

  Future<void> _reportMaterial(BuildContext context, WidgetRef ref) async {
    final draft = await _showMaterialReportDialog(
      context,
      title: _t(context, '举报素材', 'Report material'),
    );
    if (draft == null) {
      return;
    }
    try {
      await ref
          .read(materialRepositoryProvider)
          .reportTarget(
            targetType: 1,
            targetId: item.id,
            reason: draft.reason,
            description: draft.description,
          );
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(_t(context, '举报已提交', 'Report submitted'));
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
    final overviewText = _materialRichTextToPlainText(item.contentText);
    final summaryText = _materialRichTextToPlainText(item.summary);
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
            MaterialMusicSupport.isAudioItem(item)
                ? _t(context, '歌曲介绍', 'Song Overview')
                : _t(context, '内容概览', 'Overview'),
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (overviewText.isNotEmpty)
            SelectableText(
              overviewText,
              style: TextStyle(
                color: palette.bodyText,
                fontSize: 15,
                height: 1.75,
              ),
            )
          else
            Text(
              summaryText.isNotEmpty
                  ? summaryText
                  : item.summary.isNotEmpty
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
    if (MaterialMusicSupport.isAudioItem(item)) {
      context.push('/materials/music/player/${item.id}', extra: item);
      return;
    }
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

class _MaterialCommentThread extends StatelessWidget {
  const _MaterialCommentThread({
    required this.node,
    required this.depth,
    required this.onReply,
    required this.onReport,
  });

  final _MaterialCommentNode node;
  final int depth;
  final ValueChanged<MaterialComment> onReply;
  final ValueChanged<MaterialComment> onReport;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MaterialCommentCard(
          comment: node.comment,
          indent: depth * 22.0,
          onReply: () => onReply(node.comment),
          onReport: () => onReport(node.comment),
        ),
        for (final reply in node.replies)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _MaterialCommentThread(
              node: reply,
              depth: depth + 1,
              onReply: onReply,
              onReport: onReport,
            ),
          ),
      ],
    );
  }
}

class _MaterialCommentCard extends ConsumerWidget {
  const _MaterialCommentCard({
    required this.comment,
    required this.indent,
    required this.onReply,
    required this.onReport,
  });

  final MaterialComment comment;
  final double indent;
  final VoidCallback onReply;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _MaterialDetailPalette.of(context);
    final apiClient = ref.watch(apiClientProvider);
    final avatarUrl = apiClient.resolveUrl(comment.authorAvatar);

    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Container(
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
                      GestureDetector(
                        onTap: onReply,
                        child: Text(
                          _t(context, '回复', 'Reply'),
                          style: TextStyle(
                            color: palette.secondaryText,
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

  Future<void> _toggleCommentLike(BuildContext context, WidgetRef ref) async {
    final locale = Localizations.localeOf(context).toLanguageTag();
    try {
      await ref.read(materialRepositoryProvider).toggleCommentLike(comment.id);
      ref.invalidate(materialCommentsProvider(comment.materialId));
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
    required this.replyTarget,
    required this.onDismissReply,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final MaterialComment? replyTarget;
  final VoidCallback onDismissReply;
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

class _MaterialReportDraft {
  const _MaterialReportDraft({required this.reason, required this.description});

  final String reason;
  final String description;
}

Future<_MaterialReportDraft?> _showMaterialReportDialog(
  BuildContext context, {
  required String title,
}) async {
  final reasonController = TextEditingController();
  final descriptionController = TextEditingController();
  try {
    return await showDialog<_MaterialReportDraft>(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: reasonController,
                    autofocus: true,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: _t(context, '举报原因', 'Reason'),
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    minLines: 3,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: _t(context, '补充描述（可选）', 'Details (optional)'),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(_t(context, '取消', 'Cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) {
                      setState(() {
                        errorText = _t(
                          context,
                          '请填写举报原因',
                          'Please enter a reason',
                        );
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(
                      _MaterialReportDraft(
                        reason: reason,
                        description: descriptionController.text.trim(),
                      ),
                    );
                  },
                  child: Text(_t(context, '提交', 'Submit')),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    reasonController.dispose();
    descriptionController.dispose();
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

String _materialRichTextToPlainText(String source) {
  final normalized = source
      .trim()
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'&nbsp;', caseSensitive: false), ' ');
  if (normalized.isEmpty) {
    return '';
  }
  try {
    final document = XmlDocument.parse('<root>$normalized</root>');
    final text = document.rootElement.descendants
        .whereType<XmlText>()
        .map((node) => node.value)
        .join('\n');
    return _compactMaterialText(text);
  } on Object {
    return _compactMaterialText(
      _decodeMaterialHtmlEntities(
        normalized
            .replaceAll(
              RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
              '',
            )
            .replaceAll(
              RegExp(r'<style[\s\S]*?</style>', caseSensitive: false),
              '',
            )
            .replaceAll(
              RegExp(
                r'</?(p|div|section|article|li|ul|ol|h[1-6])\b[^>]*>',
                caseSensitive: false,
              ),
              '\n',
            )
            .replaceAll(RegExp(r'<[^>]+>'), ''),
      ),
    );
  }
}

String _compactMaterialText(String source) {
  return source
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'[ \t\f\v]+'), ' ')
      .replaceAll(RegExp(r' *\n *'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

String _decodeMaterialHtmlEntities(String source) {
  return source
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'");
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
    required this.outline,
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
      outline: scheme.outlineVariant,
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
  final Color outline;
  final Color activeSoftBackground;
  final Color avatarBackground;
  final Color entertainmentHeroBackground;
  final Color entertainmentStatsBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color bodyText;
}
