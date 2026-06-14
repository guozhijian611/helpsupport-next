<?php

namespace plugin\help\app\admin\logic\doctor;

use plugin\help\app\model\doctor\SaDoctorTaskTemplate;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;

/**
 * 医生任务模板逻辑层
 */
class SaDoctorTaskTemplateLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaDoctorTaskTemplate();
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
        if ($isCreate && empty($data['id'])) {
            $data['id'] = bin2hex(random_bytes(16));
        }

        foreach ([
            'doctor_id' => 0,
            'folder_id' => '',
            'stage' => '',
            'start_time' => '09:00',
            'end_time' => '09:30',
            'reward_score' => 0,
            'sort' => 100,
        ] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        foreach (['reminder_rule', 'attachments'] as $field) {
            if (array_key_exists($field, $data)) {
                $data[$field] = $this->normalizeJsonField(
                    $data[$field],
                    $field === 'reminder_rule' ? '提醒规则' : '附件'
                );
            }
        }

        return $data;
    }

    private function normalizeJsonField(mixed $value, string $label): ?string
    {
        if ($value === '' || $value === null) {
            return null;
        }

        if (is_array($value) || is_object($value)) {
            return json_encode($value, JSON_UNESCAPED_UNICODE);
        }

        $decoded = json_decode((string) $value, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new ApiException($label . 'JSON格式错误');
        }

        return json_encode($decoded, JSON_UNESCAPED_UNICODE);
    }
}
