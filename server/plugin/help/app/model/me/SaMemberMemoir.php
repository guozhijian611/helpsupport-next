<?php

namespace plugin\help\app\model\me;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 会员回忆录模型
 */
class SaMemberMemoir extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_member_memoir';

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchConfigIdAttr($query, $value): void
    {
        $query->where('config_id', (int) $value);
    }

    public function searchTitleAttr($query, $value): void
    {
        $query->where('title', 'like', '%' . $value . '%');
    }

    public function searchSourceMonthAttr($query, $value): void
    {
        $query->where('source_month', (string) $value);
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
