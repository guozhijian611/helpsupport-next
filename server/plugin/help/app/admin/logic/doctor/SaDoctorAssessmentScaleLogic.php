<?php

namespace plugin\help\app\admin\logic\doctor;

use plugin\help\app\model\doctor\SaDoctorAssessmentScale;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;

/**
 * 医生评估量表逻辑层
 */
class SaDoctorAssessmentScaleLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaDoctorAssessmentScale();
        $this->orderField = 'id';
        $this->orderType = 'DESC';
    }

    public function add(array $data): mixed
    {
        return parent::add($this->normalizeFields($data, true));
    }

    public function edit($id, array $data): mixed
    {
        return parent::edit($id, $this->normalizeFields($data));
    }

    public function publish(string $id): bool
    {
        if ($id === '') {
            throw new ApiException('请选择要发布的量表');
        }

        return (bool) $this->edit($id, [
            'status' => 'published',
            'published_at' => date('Y-m-d H:i:s'),
        ]);
    }

    public function disable(string $id): bool
    {
        if ($id === '') {
            throw new ApiException('请选择要禁用的量表');
        }

        return (bool) $this->edit($id, [
            'status' => 'disabled',
        ]);
    }

    private function normalizeFields(array $data, bool $isCreate = false): array
    {
        if ($isCreate && empty($data['id'])) {
            $data['id'] = bin2hex(random_bytes(16));
        }

        foreach ([
            'doctor_id' => 0,
            'stage' => '',
            'total_score' => 0,
        ] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        if (array_key_exists('published_at', $data) && $data['published_at'] === '') {
            $data['published_at'] = null;
        }

        foreach (['questions', 'scoring_rule'] as $field) {
            if (array_key_exists($field, $data)) {
                $data[$field] = $this->normalizeJsonField($data[$field]);
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

        return (string) $value;
    }
}
