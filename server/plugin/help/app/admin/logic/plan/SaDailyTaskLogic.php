<?php

namespace plugin\help\app\admin\logic\plan;

use plugin\help\app\model\plan\SaDailyTask;
use plugin\saiadmin\basic\think\BaseLogic;

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
        return parent::add($this->normalizeFields($data));
    }

    public function edit($id, array $data): mixed
    {
        return parent::edit($id, $this->normalizeFields($data));
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
            }
        }

        return $data;
    }
}
