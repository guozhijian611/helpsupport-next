<?php

namespace plugin\help\app\model\me;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 回忆录配置模型
 */
class SaMemberMemoirConfig extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_member_memoir_config';

    public function searchNameAttr($query, $value): void
    {
        $query->where('name', 'like', '%' . $value . '%');
    }

    public function searchCodeAttr($query, $value): void
    {
        $query->where('code', 'like', '%' . $value . '%');
    }

    public function searchGenerationCycleAttr($query, $value): void
    {
        $query->where('generation_cycle', (string) $value);
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
