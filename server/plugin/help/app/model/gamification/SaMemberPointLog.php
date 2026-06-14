<?php

namespace plugin\help\app\model\gamification;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 积分流水模型
 */
class SaMemberPointLog extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_member_point_log';

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchChangeTypeAttr($query, $value): void
    {
        $query->where('change_type', (string) $value);
    }

    public function searchSourceTypeAttr($query, $value): void
    {
        $query->where('source_type', (string) $value);
    }

    public function searchTitleAttr($query, $value): void
    {
        $query->where('title', 'like', '%' . $value . '%');
    }
}
