<?php

namespace plugin\help\app\admin\logic\me;

use plugin\help\app\model\me\SaMemberMemoir;
use plugin\saiadmin\basic\think\BaseLogic;

/**
 * 会员回忆录逻辑层
 */
class SaMemberMemoirLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberMemoir();
        $this->orderField = 'source_month';
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
        foreach (['config_id' => 0, 'grant_level_id' => 0, 'grant_level_rank' => 0, 'journal_count' => 0, 'material_count' => 0, 'status' => 1] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        return $data;
    }
}
