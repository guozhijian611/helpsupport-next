<?php

namespace plugin\help\app\admin\logic\plan;

use plugin\help\app\model\plan\SaTreatmentStage;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

/**
 * 治疗阶段逻辑层
 */
class SaTreatmentStageLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaTreatmentStage();
        $this->orderField = 'sort';
        $this->orderType = 'ASC';
    }

    public function add(array $data): mixed
    {
        $this->assertPlanMember($data);

        return parent::add($data);
    }

    public function edit($id, array $data): mixed
    {
        $this->assertPlanMember($data);

        return parent::edit($id, $data);
    }

    private function assertPlanMember(array $data): void
    {
        $planId = (int) ($data['plan_id'] ?? 0);
        $memberId = (int) ($data['member_id'] ?? 0);
        if ($planId <= 0 || $memberId <= 0) {
            return;
        }

        $plan = Db::table('sa_treatment_plan')
            ->where('id', $planId)
            ->whereNull('delete_time')
            ->find();
        if (!$plan) {
            throw new ApiException('所属治疗计划不存在');
        }
        if ((int) $plan['member_id'] !== $memberId) {
            throw new ApiException('治疗阶段患者与所属计划患者不一致');
        }
    }
}
