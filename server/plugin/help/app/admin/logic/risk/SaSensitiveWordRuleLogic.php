<?php

namespace plugin\help\app\admin\logic\risk;

use plugin\help\app\model\risk\SaSensitiveWordRule;
use plugin\saiadmin\basic\think\BaseLogic;

/**
 * 敏感词风控规则逻辑层
 */
class SaSensitiveWordRuleLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaSensitiveWordRule();
        $this->orderField = 'id';
        $this->orderType = 'DESC';
    }

    public function add(array $data): mixed
    {
        return parent::add($this->normalizeFields($data));
    }

    public function edit($id, array $data): mixed
    {
        return parent::edit($id, $this->normalizeFields($data));
    }

    private function normalizeFields(array $data): array
    {
        foreach (['risk_level' => 1, 'hit_count' => 0, 'status' => 1] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        return $data;
    }
}
