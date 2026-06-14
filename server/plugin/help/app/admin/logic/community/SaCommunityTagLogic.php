<?php

namespace plugin\help\app\admin\logic\community;

use plugin\help\app\model\community\SaCommunityTag;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;

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
            if (array_key_exists($field, $data)) {
                $data[$field] = $this->normalizeJsonField($data[$field]);
            }
        }
        foreach (['sort' => 100, 'status' => 1] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        return $data;
    }

    private function normalizeJsonField(mixed $value): ?string
    {
        if ($value === '' || $value === null) {
            return null;
        }

        if (is_array($value) || is_object($value)) {
            return json_encode($value, JSON_UNESCAPED_UNICODE);
        }

        $decoded = json_decode((string) $value, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new ApiException('多语言标签JSON格式错误');
        }

        return json_encode($decoded, JSON_UNESCAPED_UNICODE);
    }
}
