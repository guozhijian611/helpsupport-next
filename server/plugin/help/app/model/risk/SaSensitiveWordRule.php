<?php

namespace plugin\help\app\model\risk;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 敏感词风控规则模型
 */
class SaSensitiveWordRule extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_sensitive_word_rule';

    public function searchSceneAttr($query, $value): void
    {
        $query->where('scene', (string) $value);
    }

    public function searchWordAttr($query, $value): void
    {
        $query->where('word', 'like', '%' . $value . '%');
    }

    public function searchActionAttr($query, $value): void
    {
        $query->where('action', (string) $value);
    }

    public function searchRiskLevelAttr($query, $value): void
    {
        $query->where('risk_level', (int) $value);
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
