<?php

namespace plugin\help\app\model\me;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 会员客户端诊断日志模型
 */
class SaMemberDiagnosticLog extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_member_diagnostic_log';

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchDeviceIdAttr($query, $value): void
    {
        $query->where('device_id', 'like', '%' . $value . '%');
    }

    public function searchPlatformAttr($query, $value): void
    {
        $query->where('platform', (string) $value);
    }

    public function searchSourceAttr($query, $value): void
    {
        $query->where('source', (string) $value);
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
