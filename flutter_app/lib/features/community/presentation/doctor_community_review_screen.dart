import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../application/community_controller.dart';
import '../data/community_models.dart';

class DoctorCommunityReviewScreen extends ConsumerStatefulWidget {
  const DoctorCommunityReviewScreen({super.key});

  @override
  ConsumerState<DoctorCommunityReviewScreen> createState() =>
      _DoctorCommunityReviewScreenState();
}

class _DoctorCommunityReviewScreenState
    extends ConsumerState<DoctorCommunityReviewScreen> {
  String _scope = 'pending';
  int? _submittingPostId;

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(communityReviewPostsProvider(_scope));
    final apiClient = ref.watch(apiClientProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: Text(_t(context, '社区内容审核', 'Community review')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _ScopeTab(
                      label: _t(context, '未审核', 'Pending'),
                      active: _scope == 'pending',
                      onTap: () => setState(() => _scope = 'pending'),
                    ),
                  ),
                  Expanded(
                    child: _ScopeTab(
                      label: _t(context, '已审核', 'Reviewed'),
                      active: _scope == 'reviewed',
                      onTap: () => setState(() => _scope = 'reviewed'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(communityReviewPostsProvider('pending'));
                  ref.invalidate(communityReviewPostsProvider('reviewed'));
                  await ref.read(communityReviewPostsProvider(_scope).future);
                },
                child: posts.when(
                  data: (page) => page.list.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                          children: [
                            _ReviewStatusCard(
                              title: _scope == 'pending'
                                  ? _t(context, '暂无待审核内容', 'Nothing pending')
                                  : _t(
                                      context,
                                      '暂无已审核记录',
                                      'No reviewed posts yet',
                                    ),
                              subtitle: _scope == 'pending'
                                  ? _t(
                                      context,
                                      '新的社区发帖会在这里等待医生审核。',
                                      'New community posts will appear here for review.',
                                    )
                                  : _t(
                                      context,
                                      '通过或拒绝后的内容会沉淀到这里。',
                                      'Approved and rejected posts will appear here.',
                                    ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                          itemCount: page.list.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final post = page.list[index];
                            return _ReviewPostCard(
                              post: post,
                              thumbnailUrl: post.images.isEmpty
                                  ? ''
                                  : apiClient.resolveUrl(post.images.first),
                              submitting: _submittingPostId == post.id,
                              reviewedMode: _scope == 'reviewed',
                              onApprove: _scope == 'pending'
                                  ? () => _submitReview(
                                      context,
                                      postId: post.id,
                                      auditStatus: 1,
                                    )
                                  : null,
                              onReject: _scope == 'pending'
                                  ? () => _showRejectDialog(context, post)
                                  : null,
                            );
                          },
                        ),
                  error: (error, _) => ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    children: [
                      _ReviewStatusCard(
                        title: _t(context, '审核列表加载失败', 'Load failed'),
                        subtitle: error.toString(),
                      ),
                    ],
                  ),
                  loading: () => ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    children: List.generate(
                      4,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          height: 212,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    CommunityPost post,
  ) async {
    final controller = TextEditingController();
    final remark = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_t(context, '填写拒绝原因', 'Reject reason')),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: _t(
                context,
                '例如：内容不符合社区规范',
                'For example: this content does not meet the community rules.',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_t(context, '取消', 'Cancel')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(_t(context, '提交', 'Submit')),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (remark == null) {
      return;
    }
    if (remark.trim().isEmpty) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(
        _t(context, '请填写拒绝原因', 'Please enter a reason'),
      );
      return;
    }

    await _submitReview(
      context,
      postId: post.id,
      auditStatus: 2,
      auditRemark: remark,
    );
  }

  Future<void> _submitReview(
    BuildContext context, {
    required int postId,
    required int auditStatus,
    String? auditRemark,
  }) async {
    if (_submittingPostId != null) {
      return;
    }

    setState(() => _submittingPostId = postId);
    try {
      await ref
          .read(communityRepositoryProvider)
          .reviewPost(
            postId: postId,
            auditStatus: auditStatus,
            auditRemark: auditRemark,
          );
      ref.invalidate(communityReviewPostsProvider('pending'));
      ref.invalidate(communityReviewPostsProvider('reviewed'));
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(
        auditStatus == 1
            ? _t(context, '已审核通过', 'Approved')
            : _t(context, '已拒绝该内容', 'Rejected'),
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showCenteredNotice(error.toString());
    } finally {
      if (mounted) {
        setState(() => _submittingPostId = null);
      }
    }
  }
}

class _ScopeTab extends StatelessWidget {
  const _ScopeTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active
                    ? const Color(0xFF5A81DA)
                    : const Color(0xFF303236),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF5A81DA) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewPostCard extends StatelessWidget {
  const _ReviewPostCard({
    required this.post,
    required this.thumbnailUrl,
    required this.submitting,
    required this.reviewedMode,
    this.onApprove,
    this.onReject,
  });

  final CommunityPost post;
  final String thumbnailUrl;
  final bool submitting;
  final bool reviewedMode;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final title = post.content.replaceAll('\n', ' ').trim();
    final approved = post.auditStatus == 1;
    final rejected = post.auditStatus == 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF57D6CB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF303236),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            post.content,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6F737B),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.55,
                            ),
                          ),
                        ),
                        if (thumbnailUrl.isNotEmpty) ...[
                          const SizedBox(width: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              thumbnailUrl,
                              width: 126,
                              height: 88,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE7EAF0)),
          const SizedBox(height: 14),
          if (!reviewedMode)
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: submitting ? null : onReject,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF9E8F),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Text(_t(context, '拒绝', 'Reject')),
                  ),
                ),
                Container(width: 1, height: 34, color: const Color(0xFFE7EAF0)),
                Expanded(
                  child: TextButton(
                    onPressed: submitting ? null : onApprove,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF5A81DA),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_t(context, '通过', 'Approve')),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  approved
                      ? _t(context, '已通过', 'Approved')
                      : rejected
                      ? _t(context, '已拒绝', 'Rejected')
                      : _t(context, '已审核', 'Reviewed'),
                  style: TextStyle(
                    color: approved
                        ? const Color(0xFF8A8F98)
                        : const Color(0xFFFF9E8F),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (rejected && post.auditRemark.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    post.auditRemark,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFFB0B3BA),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          if (reviewedMode &&
              post.auditStatus == 2 &&
              post.createTime.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _t(
                  context,
                  '发布时间：${post.createTime}',
                  'Published at ${post.createTime}',
                ),
                style: const TextStyle(
                  color: Color(0xFF96999F),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewStatusCard extends StatelessWidget {
  const _ReviewStatusCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF303236),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF7D828A),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
