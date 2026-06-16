<?php

namespace plugin\help\app\model\material;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 内容分类模型
 *
 * sa_content_category HelpSupport 内容分类表
 */
class SaContentCategory extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_content_category';

    public function searchParentIdAttr($query, $value): void
    {
        $query->where('parent_id', (int) $value);
    }

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchNameAttr($query, $value): void
    {
        $query->where('name', 'like', '%' . $value . '%');
    }

    public function searchTypeAttr($query, $value): void
    {
        $query->where('type', (string) $value);
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
