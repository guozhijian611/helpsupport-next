import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../application/community_controller.dart';
import '../data/community_models.dart';

class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(communityPostsProvider);

    return posts.when(
      data: (page) => RefreshIndicator(
        onRefresh: () => ref.refresh(communityPostsProvider.future),
        child: page.list.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  Icon(
                    Icons.forum_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.communityFeedEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                itemCount: page.list.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return CommunityPostCard(post: page.list[index]);
                },
              ),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.networkUnavailable),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.invalidate(communityPostsProvider),
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class CommunityPostCard extends ConsumerWidget {
  const CommunityPostCard({super.key, required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/community/post/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      post.isAnonymous
                          ? Icons.visibility_off_outlined
                          : Icons.person_outline,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          post.createTime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (post.isPendingReview)
                    Chip(
                      label: Text(context.l10n.communityPendingReview),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in post.tags.take(4))
                      Chip(
                        label: Text(tag),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _PostAction(
                    icon: post.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border_outlined,
                    label: '${post.likeCount}',
                    tooltip: post.isLiked
                        ? context.l10n.communityUnlike
                        : context.l10n.communityLike,
                    onPressed: () => _toggleLike(context, ref),
                  ),
                  _PostAction(
                    icon: Icons.mode_comment_outlined,
                    label: '${post.commentCount}',
                    tooltip: context.l10n.communityComments,
                    onPressed: () => context.push('/community/post/${post.id}'),
                  ),
                  _PostAction(
                    icon: post.isCollected
                        ? Icons.bookmark
                        : Icons.bookmark_border_outlined,
                    label: '${post.collectCount}',
                    tooltip: post.isCollected
                        ? context.l10n.communityUncollect
                        : context.l10n.communityCollect,
                    onPressed: () => _toggleCollect(context, ref),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color: scheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.viewCount}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLike(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(communityRepositoryProvider).togglePostLike(post.id);
      ref.invalidate(communityPostsProvider);
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _toggleCollect(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(communityRepositoryProvider).togglePostCollect(post.id);
      ref.invalidate(communityPostsProvider);
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}
