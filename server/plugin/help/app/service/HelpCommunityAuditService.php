<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use plugin\saiadmin\exception\ApiException;
use think\facade\Db;
use Throwable;

/**
 * 社区帖子与评论的统一审核状态流转。
 */
class HelpCommunityAuditService
{
    public const STATUS_PENDING = 0;
    public const STATUS_APPROVED = 1;
    public const STATUS_REJECTED = 2;
    public const STATUS_AI_REVIEWING = 3;

    public function review(
        string $targetType,
        int $targetId,
        int $auditStatus,
        string $remark,
        int $operatorId = 0,
        string $operatorType = 'admin',
        array $metadata = [],
        ?string $expectedContentHash = null
    ): bool {
        if (!in_array($targetType, ['community_post', 'community_comment'], true)) {
            throw new ApiException('审核对象类型错误');
        }
        if ($targetId <= 0 || !in_array($auditStatus, [0, 1, 2], true)) {
            throw new ApiException('审核状态参数错误');
        }
        if ($auditStatus === self::STATUS_REJECTED && trim($remark) === '') {
            throw new ApiException($targetType === 'community_comment' ? '隐藏原因必须填写' : '拒绝原因必须填写');
        }

        $table = $this->tableFor($targetType);
        $record = null;
        $changed = false;
        Db::transaction(function () use (
            $table,
            $targetType,
            $targetId,
            $auditStatus,
            $remark,
            $operatorId,
            $operatorType,
            $metadata,
            $expectedContentHash,
            &$record,
            &$changed
        ) {
            $record = Db::table($table)
                ->where('id', $targetId)
                ->whereNull('delete_time')
                ->lock(true)
                ->find();
            if (!$record) {
                throw new ApiException($targetType === 'community_comment' ? '评论不存在' : '帖子不存在');
            }

            if ($expectedContentHash !== null) {
                if ((int) ($record['audit_status'] ?? -1) !== self::STATUS_AI_REVIEWING) {
                    return;
                }
                if (!hash_equals($expectedContentHash, hash('sha256', (string) ($record['content'] ?? '')))) {
                    return;
                }
            }

            $beforeStatus = (int) ($record['audit_status'] ?? self::STATUS_PENDING);
            $wasApproved = $beforeStatus === self::STATUS_APPROVED && (int) ($record['status'] ?? 1) === 1;
            $willApprove = $auditStatus === self::STATUS_APPROVED;
            $now = date('Y-m-d H:i:s');
            Db::table($table)->where('id', $targetId)->update([
                'audit_status' => $auditStatus,
                'audit_remark' => trim($remark),
                'audit_by' => $operatorId > 0 ? $operatorId : null,
                'audit_time' => $now,
                'status' => $auditStatus === self::STATUS_REJECTED ? 2 : 1,
                'updated_by' => $operatorId > 0 ? $operatorId : null,
                'update_time' => $now,
            ]);

            if ($targetType === 'community_comment' && $wasApproved !== $willApprove) {
                $this->syncPostCommentCount((int) ($record['post_id'] ?? 0), $willApprove);
            }

            (new HelpAuditLogService())->record(
                $targetType,
                $targetId,
                'audit',
                $beforeStatus,
                $auditStatus,
                trim($remark),
                $operatorId,
                $operatorType,
                $metadata
            );
            $changed = true;
        });

        if ($changed) {
            $this->notifyReviewResult(
                $targetType,
                $record ?: [],
                $auditStatus,
                trim($remark),
                $operatorId,
                $operatorType
            );
        }

        return $changed;
    }

    private function tableFor(string $targetType): string
    {
        return $targetType === 'community_comment' ? 'sa_community_comment' : 'sa_community_post';
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

    private function notifyReviewResult(
        string $targetType,
        array $record,
        int $auditStatus,
        string $remark,
        int $operatorId,
        string $operatorType
    ): void
    {
        if (!in_array($auditStatus, [self::STATUS_APPROVED, self::STATUS_REJECTED], true)) {
            return;
        }

        try {
            if ($targetType === 'community_comment') {
                if ($auditStatus === self::STATUS_APPROVED) {
                    $this->notifyApprovedCommentReply($record);
                }
                return;
            }

            $memberId = (int) ($record['member_id'] ?? 0);
            if ($memberId <= 0 || ($operatorType === 'doctor' && $memberId === $operatorId)) {
                return;
            }
            $approved = $auditStatus === self::STATUS_APPROVED;
            (new HelpPushService())->notifyMember($memberId, 'system_notice', [
                'title' => $approved ? '社区帖子审核已通过' : '社区帖子审核未通过',
                'content' => $approved
                    ? '你发布的社区帖子已通过审核，现在可以在社区展示。'
                    : '你发布的社区帖子未通过审核。' . ($remark !== '' ? ' 原因：' . $remark : ''),
            ], [
                'biz_type' => 'community_audit_result',
                'biz_id' => (int) ($record['id'] ?? 0),
                'route' => '/community/post/' . (int) ($record['id'] ?? 0),
                'payload' => [
                    'post_id' => (int) ($record['id'] ?? 0),
                    'audit_status' => $auditStatus,
                ],
            ]);
        } catch (Throwable) {
            // 审核结果已落库，通知失败不回滚审核。
        }
    }

    private function notifyApprovedCommentReply(array $comment): void
    {
        $memberId = (int) ($comment['member_id'] ?? 0);
        $postId = (int) ($comment['post_id'] ?? 0);
        if ($memberId <= 0 || $postId <= 0) {
            return;
        }

        $post = Db::table('sa_community_post')->where('id', $postId)->whereNull('delete_time')->find();
        if (!$post) {
            return;
        }
        $replyToMemberId = (int) ($comment['reply_to_member_id'] ?? 0);
        if ($replyToMemberId <= 0 && (int) ($comment['parent_id'] ?? 0) > 0) {
            $parent = Db::table('sa_community_comment')
                ->where('id', (int) $comment['parent_id'])
                ->whereNull('delete_time')
                ->find();
            $replyToMemberId = (int) ($parent['member_id'] ?? 0);
        }
        $receiverId = $replyToMemberId > 0 ? $replyToMemberId : (int) ($post['member_id'] ?? 0);
        if ($receiverId <= 0 || $receiverId === $memberId) {
            return;
        }

        $member = Db::table('sa_member')->where('id', $memberId)->whereNull('delete_time')->find() ?: [];
        $nickname = (int) ($comment['is_anonymous'] ?? 2) === 1
            ? 'Anonymous'
            : trim((string) ($member['nickname'] ?? ''));
        $nickname = $nickname !== '' ? $nickname : 'Member #' . $memberId;
        (new HelpPushService())->notifyMember($receiverId, 'community_reply', ['nickname' => $nickname], [
            'biz_type' => 'community_comment',
            'biz_id' => (int) ($comment['id'] ?? 0),
            'route' => '/community/post/' . $postId,
            'payload' => [
                'post_id' => $postId,
                'comment_id' => (int) ($comment['id'] ?? 0),
                'reply_to_member_id' => $replyToMemberId,
            ],
        ]);
    }
}
