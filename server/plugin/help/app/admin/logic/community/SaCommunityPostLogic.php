<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\logic\community;

use plugin\help\app\service\HelpCommunityAuditService;
use plugin\saiadmin\basic\think\BaseLogic;
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
        return (new HelpCommunityAuditService())->review(
            'community_post',
            $id,
            $auditStatus,
            $remark,
            $adminId,
            'admin'
        );
    }

}
