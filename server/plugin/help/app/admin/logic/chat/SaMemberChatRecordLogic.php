<?php

namespace plugin\help\app\admin\logic\chat;

use plugin\help\app\model\chat\SaMemberChatRecord;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;

/**
 * 会员聊天记录逻辑层
 */
class SaMemberChatRecordLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberChatRecord();
        $this->orderField = 'message_time';
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
        if (array_key_exists('message_time', $data) && $data['message_time'] === '') {
            $data['message_time'] = null;
        }
        if (array_key_exists('ext', $data)) {
            $data['ext'] = $this->normalizeJsonField($data['ext']);
        }
        foreach (['content_type' => 'text', 'token_count' => 0, 'status' => 1] as $field => $default) {
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
            throw new ApiException('扩展信息JSON格式错误');
        }

        return json_encode($decoded, JSON_UNESCAPED_UNICODE);
    }
}
