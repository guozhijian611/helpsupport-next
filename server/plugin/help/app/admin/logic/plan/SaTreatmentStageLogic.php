<?php

namespace plugin\help\app\admin\logic\plan;

use plugin\help\app\model\plan\SaTreatmentStage;
use plugin\saiadmin\basic\think\BaseLogic;

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
}
