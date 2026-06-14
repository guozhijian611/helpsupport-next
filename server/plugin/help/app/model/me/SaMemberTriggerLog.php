<?php

namespace plugin\help\app\model\me;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 触发因素记录模型
 */
class SaMemberTriggerLog extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_member_trigger_log';

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchTriggerNameAttr($query, $value): void
    {
        $query->where('trigger_name', 'like', '%' . $value . '%');
    }

    public function searchTriggerTypeAttr($query, $value): void
    {
        $query->where('trigger_type', (string) $value);
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
