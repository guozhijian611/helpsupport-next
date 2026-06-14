<?php

namespace plugin\help\app\model\material;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 内容素材模型
 *
 * sa_content_material HelpSupport 教育与娱乐素材表
 */
class SaContentMaterial extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_content_material';

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchCategoryIdAttr($query, $value): void
    {
        $query->where('category_id', (int) $value);
    }

    public function searchMediaTypeAttr($query, $value): void
    {
        $query->where('media_type', (string) $value);
    }

    public function searchMaterialTypeAttr($query, $value): void
    {
        $query->where('material_type', (string) $value);
    }

    public function searchTitleAttr($query, $value): void
    {
        $query->where('title', 'like', '%' . $value . '%');
    }

    public function searchAuditStatusAttr($query, $value): void
    {
        $query->where('audit_status', (int) $value);
    }

    public function searchIsPublicAttr($query, $value): void
    {
        $query->where('is_public', (int) $value);
    }

    public function searchIsRecommendedAttr($query, $value): void
    {
        $query->where('is_recommended', (int) $value);
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
