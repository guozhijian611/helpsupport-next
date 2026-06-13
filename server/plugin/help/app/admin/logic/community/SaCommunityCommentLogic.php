<?php

namespace plugin\help\app\admin\logic\community;

use plugin\help\app\model\community\SaCommunityComment;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;

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

    public function audit(int $id, int $auditStatus, int $adminId): bool
    {
        if (!in_array($auditStatus, [1, 2], true)) {
            throw new ApiException('审核状态参数错误');
        }

        return (bool) $this->edit($id, [
            'audit_status' => $auditStatus,
            'status' => $auditStatus === 1 ? 1 : 2,
            'updated_by' => $adminId > 0 ? $adminId : null,
        ]);
    }
}
