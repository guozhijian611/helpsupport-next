<?php

namespace plugin\help\app\admin\logic\plan;

use plugin\help\app\model\plan\SaMemberAssessmentResult;
use plugin\saiadmin\basic\think\BaseLogic;

/**
 * 会员评估结果逻辑层
 */
class SaMemberAssessmentResultLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberAssessmentResult();
        $this->orderField = 'id';
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
        if (array_key_exists('assessed_at', $data) && $data['assessed_at'] === '') {
            $data['assessed_at'] = null;
        }

        foreach (['answers', 'assessment_snapshot'] as $field) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = null;
                continue;
            }
            if (is_array($data[$field]) || is_object($data[$field])) {
                $data[$field] = json_encode($data[$field], JSON_UNESCAPED_UNICODE);
            }
        }

        return $data;
    }
}
