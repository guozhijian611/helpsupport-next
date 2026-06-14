<?php

namespace plugin\help\app\model\doctor;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 医生任务模板文件夹模型
 *
 * sa_doctor_task_template_folder HelpSupport 医生任务模板文件夹表
 */
class SaDoctorTaskTemplateFolder extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_doctor_task_template_folder';

    public function searchDoctorIdAttr($query, $value): void
    {
        $query->where('doctor_id', (int) $value);
    }

    public function searchNameAttr($query, $value): void
    {
        $query->where('name', 'like', '%' . $value . '%');
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
