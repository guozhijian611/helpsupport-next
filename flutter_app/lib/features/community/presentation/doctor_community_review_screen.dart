import 'package:flutter/material.dart';
import 'package:helpsupport_app/core/cache/cached_remote_image.dart';
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
    final palette = _DoctorCommunityReviewPalette.of(context);
    final posts = ref.watch(communityReviewPostsProvider(_scope));
    final apiClient = ref.watch(apiClientProvider);

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.primaryText,
        surfaceTintColor: Colors.transparent,
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
                            color: palette.cardBackground,
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
    final presetReasons = _rejectReasonOptions(context);
    final remark = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final palette = _DoctorCommunityReviewPalette.of(dialogContext);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedReason = controller.text.trim();
            return AlertDialog(
              title: Text(_t(context, '填写拒绝原因', 'Reject reason')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(context, '常用原因', 'Common reasons'),
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presetReasons.map((reason) {
                        final selected = selectedReason == reason.label;
                        return ChoiceChip(
                          label: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 210),
                            child: Text(
                              reason.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          selected: selected,
                          onSelected: (_) {
                            controller.text = reason.label;
                            controller.selection = TextSelection.collapsed(
                              offset: controller.text.length,
                            );
                            setDialogState(() {});
                          },
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : palette.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          selectedColor: const Color(0xFFFF9585),
                          backgroundColor: palette.cardBackground,
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFFFF9585)
                                : palette.outline,
                          ),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: _t(
                          context,
                          '例如：内容不符合社区规范',
                          'For example: this content does not meet the community rules.',
                        ),
                      ),
                    ),
                  ],
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

List<_RejectReasonOption> _rejectReasonOptions(BuildContext context) {
  return [
    _RejectReasonOption(
      _t(context, '内容不符合社区规范', 'Content does not meet community rules'),
    ),
    _RejectReasonOption(
      _t(context, '含有攻击、辱骂或骚扰内容', 'Abuse, harassment, or insults'),
    ),
    _RejectReasonOption(
      _t(context, '含有自伤、自杀或危险行为暗示', 'Self-harm or dangerous behavior'),
    ),
    _RejectReasonOption(_t(context, '含有广告、引流或无关推广', 'Ads, spam, or promotion')),
    _RejectReasonOption(
      _t(context, '涉及隐私信息或敏感个人信息', 'Private or sensitive information'),
    ),
  ];
}

class _RejectReasonOption {
  const _RejectReasonOption(this.label);

  final String label;
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
    final palette = _DoctorCommunityReviewPalette.of(context);
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
                color: active ? const Color(0xFF5A81DA) : palette.primaryText,
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
    final palette = _DoctorCommunityReviewPalette.of(context);
    final title = post.hasTitle
        ? post.title
        : post.content.replaceAll('\n', ' ').trim();
    final body = post.hasTitle ? post.body : post.content;
    final approved = post.auditStatus == 1;
    final rejected = post.auditStatus == 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: palette.cardBackground,
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
                      style: TextStyle(
                        color: palette.primaryText,
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
                            body,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.bodyText,
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
                            child: CachedRemoteImage(
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
          if (post.aiAudit case final aiAudit?) ...[
            const SizedBox(height: 14),
            _AiAuditInsight(audit: aiAudit),
          ],
          const SizedBox(height: 14),
          Divider(height: 1, color: palette.outline),
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
                Container(width: 1, height: 34, color: palette.outline),
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
            _ReviewedPostMeta(
              approved: approved,
              rejected: rejected,
              auditRemark: post.auditRemark,
              createTime: post.createTime,
            ),
        ],
      ),
    );
  }
}

class _AiAuditInsight extends StatelessWidget {
  const _AiAuditInsight({required this.audit});

  final CommunityAiAudit audit;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorCommunityReviewPalette.of(context);
    final accent = switch (audit.decision) {
      'pass' => const Color(0xFF5A81DA),
      'reject' => const Color(0xFFFF9585),
      _ => const Color(0xFFFFAE4D),
    };
    final decision = switch (audit.decision) {
      'pass' => _t(context, '建议通过', 'Suggested pass'),
      'review' => _t(context, '建议复核', 'Needs review'),
      'reject' => _t(context, '建议拒绝', 'Suggested reject'),
      _ =>
        audit.taskStatus == 3
            ? _t(context, 'AI审核失败', 'AI review failed')
            : _t(context, 'AI审核中', 'AI reviewing'),
    };
    final percent = (audit.confidence * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: accent),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _t(context, 'AI审核参考', 'AI review insight'),
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _ReviewStatusPill(
                label: audit.confidence > 0
                    ? '$decision · $percent%'
                    : decision,
                color: accent,
              ),
            ],
          ),
          if (audit.reason.trim().isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              audit.reason,
              style: TextStyle(
                color: palette.bodyText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ],
          if (audit.errorMessage.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              _t(context, '已转人工处理', 'Routed to human review'),
              style: const TextStyle(
                color: Color(0xFFFF9585),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewedPostMeta extends StatelessWidget {
  const _ReviewedPostMeta({
    required this.approved,
    required this.rejected,
    required this.auditRemark,
    required this.createTime,
  });

  final bool approved;
  final bool rejected;
  final String auditRemark;
  final String createTime;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorCommunityReviewPalette.of(context);
    final statusText = approved
        ? _t(context, '已通过', 'Approved')
        : rejected
        ? _t(context, '已拒绝', 'Rejected')
        : _t(context, '已审核', 'Reviewed');
    final statusColor = approved
        ? const Color(0xFF5A81DA)
        : rejected
        ? const Color(0xFFFF9585)
        : palette.secondaryText;
    final remark = auditRemark.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReviewedMetaRow(
          label: _t(context, '审核结果', 'Review result'),
          child: _ReviewStatusPill(label: statusText, color: statusColor),
        ),
        if (rejected && remark.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ReviewedMetaRow(
            label: _t(context, '拒绝原因', 'Reject reason'),
            child: Text(
              remark,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: palette.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
        if (createTime.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ReviewedMetaRow(
            label: _t(context, '发布时间', 'Published at'),
            child: Text(
              createTime,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: palette.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ReviewedMetaRow extends StatelessWidget {
  const _ReviewedMetaRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = _DoctorCommunityReviewPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: palette.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Align(alignment: Alignment.centerRight, child: child),
        ),
      ],
    );
  }
}

class _ReviewStatusPill extends StatelessWidget {
  const _ReviewStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
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
    final palette = _DoctorCommunityReviewPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: palette.mutedText,
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

class _DoctorCommunityReviewPalette {
  const _DoctorCommunityReviewPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.bodyText,
    required this.outline,
  });

  factory _DoctorCommunityReviewPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return _DoctorCommunityReviewPalette(
      pageBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerLowest,
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurfaceVariant,
      mutedText: isDark
          ? scheme.onSurfaceVariant.withValues(alpha: 0.8)
          : const Color(0xFF7D828A),
      bodyText: isDark
          ? scheme.onSurface.withValues(alpha: 0.82)
          : const Color(0xFF6F737B),
      outline: scheme.outlineVariant,
    );
  }

  final Color pageBackground;
  final Color cardBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color bodyText;
  final Color outline;
}
