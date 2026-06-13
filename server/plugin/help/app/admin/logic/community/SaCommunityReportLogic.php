<?php

namespace plugin\help\app\admin\logic\community;

use plugin\help\app\model\community\SaCommunityReport;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;

/**
 * 社区举报逻辑层
 */
class SaCommunityReportLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaCommunityReport();
        $this->orderField = 'id';
        $this->orderType = 'DESC';
    }

    public function handle(int $id, int $handleStatus, string $remark, int $adminId): bool
    {
        if (!in_array($handleStatus, [1, 2], true)) {
            throw new ApiException('处理状态参数错误');
        }

        return (bool) $this->edit($id, [
            'handle_status' => $handleStatus,
            'handle_remark' => $remark,
            'handle_by' => $adminId > 0 ? $adminId : null,
            'handle_time' => date('Y-m-d H:i:s'),
        ]);
    }
}
