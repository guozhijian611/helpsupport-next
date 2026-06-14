<?php

namespace plugin\help\app\model\doctor;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 医生任务模板模型
 *
 * sa_doctor_task_template HelpSupport 医生任务模板表
 */
class SaDoctorTaskTemplate extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_doctor_task_template';

    public function searchDoctorIdAttr($query, $value): void
    {
        $query->where('doctor_id', (int) $value);
    }

    public function searchFolderIdAttr($query, $value): void
    {
        $query->where('folder_id', (string) $value);
    }

    public function searchStageAttr($query, $value): void
    {
        $query->where('stage', (string) $value);
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
