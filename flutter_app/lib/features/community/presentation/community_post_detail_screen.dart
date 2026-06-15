import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
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
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = ref.watch(communityPostProvider(widget.postId));
    final comments = ref.watch(communityCommentsProvider(widget.postId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(title: Text(context.l10n.community)),
      body: SafeArea(
        child: post.when(
          data: (item) => Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(communityPostProvider(widget.postId));
                    ref.invalidate(communityCommentsProvider(widget.postId));
                    await ref.read(communityPostProvider(widget.postId).future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    children: [
                      CommunityPostCard(
                        post: item,
                        showFollowButton: true,
                        routeToDetail: false,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.l10n.communityComments,
                        style: const TextStyle(
                          color: Color(0xFF303236),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      comments.when(
                        data: (page) => page.list.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Text(
                                  context.l10n.noMessages,
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Column(
                                children: [
                                  for (final comment in page.list)
                                    _CommentTile(comment: comment),
                                ],
                              ),
                        error: (error, stackTrace) =>
                            Text(context.l10n.networkUnavailable),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _CommentComposer(
                controller: _commentController,
                isSending: _isSending,
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

  Future<void> _sendComment(BuildContext context) async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref
          .read(communityRepositoryProvider)
          .createComment(postId: widget.postId, content: content);
      _commentController.clear();
      ref.invalidate(communityPostProvider(widget.postId));
      ref.invalidate(communityCommentsProvider(widget.postId));
      ref.invalidate(communityPostsProvider);
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

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final CommunityComment comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFF8E3DB),
            child: Icon(
              comment.isAnonymous
                  ? Icons.visibility_off_outlined
                  : Icons.person_outline,
              color: const Color(0xFFFF9585),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.authorName,
                  style: const TextStyle(
                    color: Color(0xFF303236),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: Color(0xFF4A4D55),
                    height: 1.55,
                  ),
                ),
                if (comment.createTime.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    comment.createTime,
                    style: const TextStyle(
                      color: Color(0xFF96999F),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${comment.likeCount}',
            style: const TextStyle(
              color: Color(0xFF96999F),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: context.l10n.communityCommentHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              tooltip: context.l10n.communitySendComment,
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
