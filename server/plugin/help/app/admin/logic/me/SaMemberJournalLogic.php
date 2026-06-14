<?php

namespace plugin\help\app\admin\logic\me;

use plugin\help\app\model\me\SaMemberJournal;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;

/**
 * 会员日记逻辑层
 */
class SaMemberJournalLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberJournal();
        $this->orderField = 'entry_date';
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
        if (array_key_exists('entry_time', $data) && $data['entry_time'] === '') {
            $data['entry_time'] = null;
        }
        if (array_key_exists('media', $data)) {
            $data['media'] = $this->normalizeJsonField($data['media']);
        }
        foreach (['mood_score' => 0, 'is_private' => 1, 'ai_access' => 2, 'status' => 1] as $field => $default) {
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
            throw new ApiException('媒体列表JSON格式错误');
        }

        return json_encode($decoded, JSON_UNESCAPED_UNICODE);
    }
}
