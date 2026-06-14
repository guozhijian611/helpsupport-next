<?php

namespace plugin\help\app\model\push;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 推送模板模型
 *
 * sa_push_template HelpSupport 推送模板表
 */
class SaPushTemplate extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_push_template';

    public function searchTemplateCodeAttr($query, $value)
    {
        $query->where('template_code', 'like', '%' . $value . '%');
    }

    public function searchTemplateNameAttr($query, $value)
    {
        $query->where('template_name', 'like', '%' . $value . '%');
    }

    public function searchSceneAttr($query, $value)
    {
        $query->where('scene', (string) $value);
    }

    public function searchLocaleAttr($query, $value)
    {
        $query->where('locale', (string) $value);
    }

    public function searchStatusAttr($query, $value)
    {
        $query->where('status', (int) $value);
    }
}
