<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use think\facade\Db;

class HelpAuditLogService
{
    public function record(
        string $targetType,
        int $targetId,
        string $action,
        mixed $beforeStatus,
        mixed $afterStatus,
        string $reason,
        int $operatorId,
        string $operatorType = 'admin',
        array $metadata = []
    ): void {
        if ($targetType === '' || $targetId <= 0 || $action === '') {
            return;
        }

        $now = date('Y-m-d H:i:s');
        Db::table('sa_help_audit_log')->insert([
            'target_type' => $targetType,
            'target_id' => $targetId,
            'action' => $action,
            'before_status' => $beforeStatus === null ? null : (string) $beforeStatus,
            'after_status' => (string) $afterStatus,
            'reason' => $reason,
            'operator_id' => $operatorId > 0 ? $operatorId : null,
            'operator_type' => in_array($operatorType, ['system', 'ai', 'doctor', 'admin'], true) ? $operatorType : 'system',
            'metadata' => $metadata === [] ? null : json_encode($metadata, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            'created_by' => $operatorId > 0 ? $operatorId : null,
            'create_time' => $now,
            'delete_time' => null,
        ]);
    }

    public function list(string $targetType, int $targetId, int $limit = 20): array
    {
        if ($targetType === '' || $targetId <= 0) {
            return [];
        }

        $rows = Db::table('sa_help_audit_log')
            ->where('target_type', $targetType)
            ->where('target_id', $targetId)
            ->whereNull('delete_time')
            ->field('id, target_type, target_id, action, before_status, after_status, reason, operator_id, operator_type, metadata, create_time')
            ->order('id', 'desc')
            ->limit(max(1, min($limit, 50)))
            ->select()
            ->toArray();

        foreach ($rows as &$row) {
            $metadata = json_decode((string) ($row['metadata'] ?? ''), true);
            $row['metadata'] = is_array($metadata) ? $metadata : [];
        }
        unset($row);
        return $rows;
    }
}
