<?php

namespace plugin\help\app\model\me;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 康复目标记录模型
 */
class SaMemberRecoveryGoalLog extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_member_recovery_goal_log';

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchGoalTextAttr($query, $value): void
    {
        $query->where('goal_text', 'like', '%' . $value . '%');
    }

    public function searchGoalTypeAttr($query, $value): void
    {
        $query->where('goal_type', (string) $value);
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
