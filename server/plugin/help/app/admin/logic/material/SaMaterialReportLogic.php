<?php

namespace plugin\help\app\admin\logic\material;

use plugin\help\app\model\material\SaMaterialReport;
use plugin\help\app\service\HelpAuditLogService;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

/**
 * 素材举报逻辑层
 */
class SaMaterialReportLogic extends BaseLogic
{
    private const TARGET_MATERIAL = 1;
    private const TARGET_COMMENT = 2;

    public function __construct()
    {
        $this->model = new SaMaterialReport();
        $this->orderField = 'id';
        $this->orderType = 'DESC';
    }

    public function handle(int $id, int $handleStatus, string $remark, int $adminId): bool
    {
        if (!in_array($handleStatus, [1, 2], true)) {
            throw new ApiException('处理状态参数错误');
        }

        $report = Db::table('sa_material_report')
            ->where('id', $id)
            ->whereNull('delete_time')
            ->find();
        if (!$report) {
            throw new ApiException('举报不存在');
        }

        return Db::transaction(function () use ($id, $handleStatus, $remark, $adminId, $report) {
            if ($handleStatus === 1) {
                $this->hideReportedTarget($report, $remark, $adminId);
            }

            $result = (bool) $this->edit($id, [
                'handle_status' => $handleStatus,
                'handle_remark' => $remark,
                'handle_by' => $adminId > 0 ? $adminId : null,
                'handle_time' => date('Y-m-d H:i:s'),
            ]);
            if ($result) {
                (new HelpAuditLogService())->record(
                    'material_report',
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

    private function hideReportedTarget(array $report, string $remark, int $adminId): void
    {
        $targetType = (int) ($report['target_type'] ?? 0);
        $targetId = (int) ($report['target_id'] ?? 0);
        $reason = trim($remark);
        if ($reason === '') {
            $reason = '举报处理：' . trim((string) ($report['reason'] ?? ''));
        }
        if ($reason === '举报处理：') {
            $reason = '举报处理';
        }

        if ($targetType === self::TARGET_MATERIAL) {
            $this->hideReportedMaterial($targetId, $reason, $adminId);
            return;
        }

        if ($targetType === self::TARGET_COMMENT) {
            $this->hideReportedComment($targetId, $reason, $adminId);
        }
    }

    private function hideReportedMaterial(int $materialId, string $reason, int $adminId): void
    {
        $material = Db::table('sa_content_material')
            ->where('id', $materialId)
            ->whereNull('delete_time')
            ->find();
        if (!$material) {
            throw new ApiException('被举报素材不存在');
        }

        Db::table('sa_content_material')->where('id', $materialId)->update([
            'audit_status' => 3,
            'audit_remark' => $reason,
            'status' => 2,
            'updated_by' => $adminId > 0 ? $adminId : null,
            'update_time' => date('Y-m-d H:i:s'),
        ]);

        (new HelpAuditLogService())->record(
            'content_material',
            $materialId,
            'report_handle',
            $material['audit_status'] ?? null,
            3,
            $reason,
            $adminId
        );
    }

    private function hideReportedComment(int $commentId, string $reason, int $adminId): void
    {
        $comment = Db::table('sa_material_comment')
            ->where('id', $commentId)
            ->whereNull('delete_time')
            ->find();
        if (!$comment) {
            throw new ApiException('被举报评论不存在');
        }

        $wasVisible = (int) ($comment['audit_status'] ?? 1) === 1 && (int) ($comment['status'] ?? 1) === 1;
        Db::table('sa_material_comment')->where('id', $commentId)->update([
            'audit_status' => 2,
            'audit_remark' => $reason,
            'audit_by' => $adminId > 0 ? $adminId : null,
            'audit_time' => date('Y-m-d H:i:s'),
            'status' => 2,
            'remark' => $reason,
            'updated_by' => $adminId > 0 ? $adminId : null,
            'update_time' => date('Y-m-d H:i:s'),
        ]);

        if ($wasVisible) {
            Db::execute(sprintf(
                'UPDATE `sa_content_material` SET `comment_count` = GREATEST(`comment_count` - 1, 0), `update_time` = NOW() WHERE `id` = %d',
                (int) ($comment['material_id'] ?? 0)
            ));
        }

        (new HelpAuditLogService())->record(
            'material_comment',
            $commentId,
            'report_handle',
            $comment['audit_status'] ?? null,
            2,
            $reason,
            $adminId
        );
    }
}
