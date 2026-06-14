<?php

namespace plugin\help\app\admin\logic\push;

use plugin\help\app\model\push\SaPushTemplate;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;

/**
 * 推送模板逻辑层
 */
class SaPushTemplateLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaPushTemplate();
        $this->orderField = 'sort';
        $this->orderType = 'ASC';
    }

    public function add(array $data): mixed
    {
        return parent::add($this->normalizeFields($data, true));
    }

    public function edit($id, array $data): mixed
    {
        return parent::edit($id, $this->normalizeFields($data));
    }

    private function normalizeFields(array $data, bool $isCreate = false): array
    {
        if (array_key_exists('payload', $data)) {
            $data['payload'] = $this->normalizeJsonField($data['payload']);
        }

        foreach ([
            'message_type' => 5,
            'is_default' => 2,
            'sort' => 100,
            'status' => 1,
        ] as $field => $default) {
            if ($isCreate && (!array_key_exists($field, $data) || $data[$field] === '')) {
                $data[$field] = $default;
                continue;
            }
            if (!$isCreate && array_key_exists($field, $data) && $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        if ($isCreate && (!array_key_exists('locale', $data) || trim((string) $data['locale']) === '')) {
            $data['locale'] = 'en-US';
        } elseif (!$isCreate && array_key_exists('locale', $data) && trim((string) $data['locale']) === '') {
            $data['locale'] = 'en-US';
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
            throw new ApiException('默认载荷JSON格式错误');
        }

        return json_encode($decoded, JSON_UNESCAPED_UNICODE);
    }
}
