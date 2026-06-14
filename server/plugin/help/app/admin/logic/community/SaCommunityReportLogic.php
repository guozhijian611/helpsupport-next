<?php

namespace plugin\help\app\admin\logic\community;

use plugin\help\app\model\community\SaCommunityReport;
use plugin\help\app\service\HelpAuditLogService;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

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

        $report = Db::table('sa_community_report')
            ->where('id', $id)
            ->whereNull('delete_time')
            ->find();
        if (!$report) {
            throw new ApiException('举报不存在');
        }

        return Db::transaction(function () use ($id, $handleStatus, $remark, $adminId, $report) {
            $result = (bool) $this->edit($id, [
                'handle_status' => $handleStatus,
                'handle_remark' => $remark,
                'handle_by' => $adminId > 0 ? $adminId : null,
                'handle_time' => date('Y-m-d H:i:s'),
            ]);
            if ($result) {
                (new HelpAuditLogService())->record(
                    'community_report',
                    $id,
                    'handle',
                    $report['handle_status'] ?? null,
                    $handleStatus,
                    $remark,
                    $adminId
                );
            }

            return $result;
        });
    }
}
