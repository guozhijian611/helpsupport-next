<?php

namespace plugin\help\app\admin\logic\community;

use plugin\help\app\model\community\SaCommunityTag;
use plugin\saiadmin\basic\think\BaseLogic;

/**
 * 社区标签逻辑层
 */
class SaCommunityTagLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaCommunityTag();
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
        foreach (['tag_name_i18n'] as $field) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = null;
            } elseif (is_array($data[$field]) || is_object($data[$field])) {
                $data[$field] = json_encode($data[$field], JSON_UNESCAPED_UNICODE);
            }
        }
        foreach (['sort' => 100, 'status' => 1] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        return $data;
    }
}
