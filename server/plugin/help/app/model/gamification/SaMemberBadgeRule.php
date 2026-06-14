<?php

namespace plugin\help\app\model\gamification;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 荣誉徽章规则模型
 */
class SaMemberBadgeRule extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_member_badge_rule';

    public function searchNameAttr($query, $value): void
    {
        $query->where('name', 'like', '%' . $value . '%');
    }

    public function searchCodeAttr($query, $value): void
    {
        $query->where('code', 'like', '%' . $value . '%');
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
