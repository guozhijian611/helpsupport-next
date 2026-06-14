<?php

namespace plugin\help\app\model\plan;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 每日任务模型
 *
 * sa_daily_task HelpSupport 每日任务表
 */
class SaDailyTask extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_daily_task';

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchPlanIdAttr($query, $value): void
    {
        $query->where('plan_id', (int) $value);
    }

    public function searchStageIdAttr($query, $value): void
    {
        $query->where('stage_id', (int) $value);
    }

    public function searchTaskDateAttr($query, $value): void
    {
        $query->where('task_date', (string) $value);
    }

    public function searchTitleAttr($query, $value): void
    {
        $query->where('title', 'like', '%' . $value . '%');
    }

    public function searchTaskTypeAttr($query, $value): void
    {
        $query->where('task_type', (string) $value);
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
