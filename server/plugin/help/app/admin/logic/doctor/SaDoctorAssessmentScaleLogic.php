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

        $scale = $this->scaleRow($id);
        $this->assertPublishable($this->presentScale($scale));

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
            if ($isCreate && (!array_key_exists($field, $data) || $data[$field] === '')) {
                $data[$field] = $default;
                continue;
            }
            if (!$isCreate && array_key_exists($field, $data) && $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        if (array_key_exists('published_at', $data) && $data['published_at'] === '') {
            $data['published_at'] = null;
        }

        foreach (['questions', 'scoring_rule'] as $field) {
            if (array_key_exists($field, $data)) {
                $data[$field] = $this->normalizeJsonField(
                    $data[$field],
                    $field === 'questions' ? '题目配置' : '计分规则'
                );
            }
        }

        return $data;
    }

    public function presentScale(array $scale): array
    {
        foreach (['questions', 'scoring_rule'] as $field) {
            if (!array_key_exists($field, $scale)) {
                continue;
            }
            $scale[$field] = $this->decodeJsonList($scale[$field]);
        }

        return $scale;
    }

    private function decodeJsonList(mixed $value): array
    {
        if (is_array($value)) {
            return $value;
        }
        if ($value === '' || $value === null) {
            return [];
        }
        $decoded = json_decode((string) $value, true);

        return is_array($decoded) ? $decoded : [];
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

    private function scaleRow(string $id): array
    {
        $scale = $this->model->where('id', $id)->whereNull('delete_time')->find();
        if (!$scale) {
            throw new ApiException('评估量表不存在');
        }

        return is_array($scale) ? $scale : $scale->toArray();
    }

    private function assertPublishable(array $scale): void
    {
        $questions = $scale['questions'] ?? [];
        if (!is_array($questions) || $questions === []) {
            throw new ApiException('发布前请先配置至少一道题目');
        }
    }
}
