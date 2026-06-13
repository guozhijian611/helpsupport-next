<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\logic\community;

use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use plugin\help\app\model\community\SaCommunityPost;

/**
 * 社区内容审核逻辑层
 */
class SaCommunityPostLogic extends BaseLogic
{
    /**
     * 构造函数
     */
    public function __construct()
    {
        $this->model = new SaCommunityPost();
        $this->orderField = 'id';
        $this->orderType = 'DESC';
    }

    public function audit(int $id, int $auditStatus, string $remark, int $adminId): bool
    {
        if (!in_array($auditStatus, [1, 2, 3], true)) {
            throw new ApiException('审核状态参数错误');
        }

        return (bool) $this->edit($id, [
            'audit_status' => $auditStatus,
            'audit_remark' => $remark,
            'audit_by' => $adminId > 0 ? $adminId : null,
            'audit_time' => date('Y-m-d H:i:s'),
            'status' => $auditStatus === 1 ? 1 : 2,
        ]);
    }

}
