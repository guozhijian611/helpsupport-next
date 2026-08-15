<?php

namespace plugin\help\app\admin\logic\community;

use plugin\help\app\model\community\SaCommunityComment;
use plugin\help\app\service\HelpCommunityAuditService;
use plugin\saiadmin\basic\think\BaseLogic;

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
        return (new HelpCommunityAuditService())->review(
            'community_comment',
            $id,
            $auditStatus,
            $remark,
            $adminId,
            'admin'
        );
    }
}
