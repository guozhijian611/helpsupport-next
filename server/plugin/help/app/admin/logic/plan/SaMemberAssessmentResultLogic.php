<?php

namespace plugin\help\app\admin\logic\plan;

use plugin\help\app\model\plan\SaMemberAssessmentResult;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

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
        $data = $this->normalizeTaskSnapshot($data);

        return parent::add($this->normalizeFields($data));
    }

    public function edit($id, array $data): mixed
    {
        $data = $this->normalizeTaskSnapshot($data);

        return parent::edit($id, $this->normalizeFields($data));
    }

    private function normalizeTaskSnapshot(array $data): array
    {
        $taskId = (int) ($data['task_id'] ?? 0);
        if ($taskId <= 0) {
            return $data;
        }

        $task = Db::table('sa_daily_task')
            ->where('id', $taskId)
            ->whereNull('delete_time')
            ->find();
        if (!$task) {
            throw new ApiException('关联任务不存在');
        }

        $memberId = (int) ($data['member_id'] ?? 0);
        if ($memberId > 0 && (int) $task['member_id'] !== $memberId) {
            throw new ApiException('评估结果患者与关联任务患者不一致');
        }

        if (empty($data['task_title'])) {
            $data['task_title'] = (string) ($task['title'] ?? '');
        }
        if (empty($data['stage_key']) && (int) ($task['stage_id'] ?? 0) > 0) {
            $stage = Db::table('sa_treatment_stage')
                ->where('id', (int) $task['stage_id'])
                ->whereNull('delete_time')
                ->find();
            if ($stage && !empty($stage['stage_key'])) {
                $data['stage_key'] = (string) $stage['stage_key'];
            }
        }

        return $data;
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
                continue;
            }
            if (is_string($data[$field])) {
                $decoded = json_decode($data[$field], true);
                if (json_last_error() !== JSON_ERROR_NONE) {
                    throw new ApiException($field === 'answers' ? '作答结果JSON格式错误' : '量表快照JSON格式错误');
                }
                $data[$field] = json_encode($decoded, JSON_UNESCAPED_UNICODE);
            }
        }

        return $data;
    }
}
