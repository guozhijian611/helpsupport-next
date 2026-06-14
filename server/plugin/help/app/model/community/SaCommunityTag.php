<?php

namespace plugin\help\app\model\community;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 社区标签模型
 */
class SaCommunityTag extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_community_tag';

    public function searchTagNameAttr($query, $value): void
    {
        $query->where('tag_name', 'like', '%' . $value . '%');
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
