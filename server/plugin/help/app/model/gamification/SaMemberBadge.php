<?php

namespace plugin\help\app\model\gamification;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 会员徽章记录模型
 */
class SaMemberBadge extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_member_badge';

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchBadgeCodeAttr($query, $value): void
    {
        $query->where('badge_code', 'like', '%' . $value . '%');
    }

    public function searchBadgeNameAttr($query, $value): void
    {
        $query->where('badge_name', 'like', '%' . $value . '%');
    }

    public function searchSourceTypeAttr($query, $value): void
    {
        $query->where('source_type', (string) $value);
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
