<?php

namespace plugin\help\app\admin\logic\plan;

use plugin\help\app\model\plan\SaDailyTask;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

/**
 * 每日任务逻辑层
 */
class SaDailyTaskLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaDailyTask();
        $this->orderField = 'task_date';
        $this->orderType = 'DESC';
    }

    public function add(array $data): mixed
    {
        $data = $this->normalizePlanStage($data);

        return parent::add($this->normalizeFields($data));
    }

    public function edit($id, array $data): mixed
    {
        $data = $this->normalizePlanStage($data);

        return parent::edit($id, $this->normalizeFields($data));
    }

    private function normalizePlanStage(array $data): array
    {
        $memberId = (int) ($data['member_id'] ?? 0);
        $planId = (int) ($data['plan_id'] ?? 0);
        $stageId = (int) ($data['stage_id'] ?? 0);

        if ($planId > 0) {
            $plan = $this->planRow($planId);
            if ($memberId > 0 && (int) $plan['member_id'] !== $memberId) {
                throw new ApiException('每日任务患者与所属计划患者不一致');
            }
        }

        if ($stageId > 0) {
            $stage = $this->stageRow($stageId);
            if ($memberId > 0 && (int) $stage['member_id'] !== $memberId) {
                throw new ApiException('每日任务患者与所属阶段患者不一致');
            }
            if ($planId > 0 && (int) $stage['plan_id'] !== $planId) {
                throw new ApiException('每日任务阶段与所属计划不一致');
            }
            if ($planId <= 0) {
                $planId = (int) $stage['plan_id'];
                $data['plan_id'] = $planId;
            }

            $plan = $this->planRow($planId);
            if ((int) $plan['member_id'] !== (int) $stage['member_id']) {
                throw new ApiException('治疗阶段与所属计划患者不一致');
            }
        }

        return $data;
    }

    private function normalizeFields(array $data): array
    {
        foreach (['start_time', 'end_time', 'completed_time'] as $field) {
            if (array_key_exists($field, $data) && $data[$field] === '') {
                $data[$field] = null;
            }
        }

        foreach (['reminders', 'attachments'] as $field) {
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
                    throw new ApiException($field === 'reminders' ? '提醒规则JSON格式错误' : '附件列表JSON格式错误');
                }
                $data[$field] = json_encode($decoded, JSON_UNESCAPED_UNICODE);
            }
        }

        return $data;
    }

    private function planRow(int $planId): array
    {
        $plan = Db::table('sa_treatment_plan')
            ->where('id', $planId)
            ->whereNull('delete_time')
            ->find();
        if (!$plan) {
            throw new ApiException('所属治疗计划不存在');
        }

        return $plan;
    }

    private function stageRow(int $stageId): array
    {
        $stage = Db::table('sa_treatment_stage')
            ->where('id', $stageId)
            ->whereNull('delete_time')
            ->find();
        if (!$stage) {
            throw new ApiException('所属治疗阶段不存在');
        }

        return $stage;
    }
}
