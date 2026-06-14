<?php

namespace plugin\help\app\admin\logic\me;

use plugin\help\app\model\me\SaMemberMemoirConfig;
use plugin\saiadmin\basic\think\BaseLogic;

/**
 * 回忆录配置逻辑层
 */
class SaMemberMemoirConfigLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberMemoirConfig();
        $this->orderField = 'sort';
        $this->orderType = 'ASC';
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
        foreach (['min_journal_count' => 3, 'start_day' => 1, 'sort' => 100, 'status' => 1] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        return $data;
    }
}
