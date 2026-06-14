<?php

namespace plugin\help\app\admin\logic\community;

use plugin\help\app\model\community\SaCommunityComment;
use plugin\help\app\service\HelpAuditLogService;
use plugin\help\app\service\HelpPushService;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use think\facade\Db;
use Throwable;

/**
 * 社区评论逻辑层
 */
class SaCommunityCommentLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaCommunityComment();
        $this->orderField = 'id';
        $this->orderType = 'DESC';
    }

    public function audit(int $id, int $auditStatus, string $remark, int $adminId): bool
    {
        if ($id <= 0) {
            throw new ApiException('请选择要审核的评论');
        }
        if (!in_array($auditStatus, [1, 2], true)) {
            throw new ApiException('审核状态参数错误');
        }
        if ($auditStatus === 2 && $remark === '') {
            throw new ApiException('隐藏原因必须填写');
        }

        $comment = Db::table('sa_community_comment')
            ->where('id', $id)
            ->whereNull('delete_time')
            ->find();
        if (!$comment) {
            throw new ApiException('评论不存在');
        }

        $wasApproved = (int) ($comment['audit_status'] ?? 0) === 1 && (int) ($comment['status'] ?? 1) === 1;
        $willApprove = $auditStatus === 1;
        $now = date('Y-m-d H:i:s');

        Db::transaction(function () use ($id, $auditStatus, $remark, $adminId, $comment, $wasApproved, $willApprove, $now) {
            Db::table('sa_community_comment')->where('id', $id)->update([
                'audit_status' => $auditStatus,
                'audit_remark' => $remark,
                'audit_by' => $adminId > 0 ? $adminId : null,
                'audit_time' => $now,
                'status' => $willApprove ? 1 : 2,
                'updated_by' => $adminId > 0 ? $adminId : null,
                'update_time' => $now,
            ]);

            if (!$wasApproved && $willApprove) {
                $this->syncPostCommentCount((int) ($comment['post_id'] ?? 0), true);
            } elseif ($wasApproved && !$willApprove) {
                $this->syncPostCommentCount((int) ($comment['post_id'] ?? 0), false);
            }

            (new HelpAuditLogService())->record(
                'community_comment',
                $id,
                'audit',
                $comment['audit_status'] ?? null,
                $auditStatus,
                $remark,
                $adminId
            );
        });

        if (!$wasApproved && $willApprove) {
            $this->notifyApprovedCommentReply($comment);
        }

        return true;
    }

    private function syncPostCommentCount(int $postId, bool $increase): void
    {
        if ($postId <= 0) {
            return;
        }

        $operator = $increase ? '+' : '-';
        Db::execute(sprintf(
            'UPDATE `sa_community_post` SET `comment_count` = GREATEST(`comment_count` %s 1, 0), `update_time` = NOW() WHERE `id` = %d',
            $operator,
            $postId
        ));
    }

    private function notifyApprovedCommentReply(array $comment): void
    {
        $memberId = (int) ($comment['member_id'] ?? 0);
        $postId = (int) ($comment['post_id'] ?? 0);
        if ($memberId <= 0 || $postId <= 0) {
            return;
        }

        $post = Db::table('sa_community_post')
            ->where('id', $postId)
            ->whereNull('delete_time')
            ->find();
        if (!$post) {
            return;
        }

        $replyToMemberId = (int) ($comment['reply_to_member_id'] ?? 0);
        if ($replyToMemberId <= 0 && (int) ($comment['parent_id'] ?? 0) > 0) {
            $parentComment = Db::table('sa_community_comment')
                ->where('id', (int) $comment['parent_id'])
                ->whereNull('delete_time')
                ->find();
            $replyToMemberId = (int) ($parentComment['member_id'] ?? 0);
        }

        $receiverId = $replyToMemberId > 0 ? $replyToMemberId : (int) ($post['member_id'] ?? 0);
        if ($receiverId <= 0 || $receiverId === $memberId) {
            return;
        }

        $member = Db::table('sa_member')
            ->where('id', $memberId)
            ->whereNull('delete_time')
            ->find() ?: [];
        $nickname = trim((string) ($member['nickname'] ?? ''));
        if ((int) ($comment['is_anonymous'] ?? 2) === 1) {
            $nickname = 'Anonymous';
        } elseif ($nickname === '') {
            $nickname = 'Member #' . $memberId;
        }

        try {
            (new HelpPushService())->notifyMember($receiverId, 'community_reply', [
                'nickname' => $nickname,
            ], [
                'biz_type' => 'community_comment',
                'biz_id' => (int) ($comment['id'] ?? 0),
                'route' => '/pages/community/detail',
                'payload' => [
                    'post_id' => $postId,
                    'comment_id' => (int) ($comment['id'] ?? 0),
                    'reply_to_member_id' => $replyToMemberId,
                ],
            ]);
        } catch (Throwable) {
            // 评论审核结果已落库，通知失败不阻断后台审核动作。
        }
    }
}
