<?php

namespace plugin\help\app\admin\logic\material;

use plugin\help\app\model\material\SaContentCategory;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;

/**
 * 内容分类逻辑层
 */
class SaContentCategoryLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaContentCategory();
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
        if (!array_key_exists('parent_id', $data) || $data['parent_id'] === '') {
            $data['parent_id'] = 0;
        }

        if (!array_key_exists('sort', $data) || $data['sort'] === '') {
            $data['sort'] = 100;
        }

        if (array_key_exists('name_i18n', $data)) {
            $data['name_i18n'] = $this->normalizeJsonField($data['name_i18n']);
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
            throw new ApiException('多语言分类名称JSON格式错误');
        }

        return json_encode($decoded, JSON_UNESCAPED_UNICODE);
    }
}
