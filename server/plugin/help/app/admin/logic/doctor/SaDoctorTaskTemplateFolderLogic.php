<?php

namespace plugin\help\app\admin\logic\doctor;

use plugin\help\app\model\doctor\SaDoctorTaskTemplateFolder;
use plugin\saiadmin\basic\think\BaseLogic;

/**
 * 医生任务模板文件夹逻辑层
 */
class SaDoctorTaskTemplateFolderLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaDoctorTaskTemplateFolder();
        $this->orderField = 'sort';
        $this->orderType = 'ASC';
    }

    public function add(array $data): mixed
    {
        return parent::add($this->normalizeFields($data, true));
    }

    public function edit($id, array $data): mixed
    {
        return parent::edit($id, $this->normalizeFields($data));
    }

    private function normalizeFields(array $data, bool $isCreate = false): array
    {
        if ($isCreate && empty($data['id'])) {
            $data['id'] = bin2hex(random_bytes(16));
        }

        if (!array_key_exists('doctor_id', $data) || $data['doctor_id'] === '') {
            $data['doctor_id'] = 0;
        }

        if (!array_key_exists('sort', $data) || $data['sort'] === '') {
            $data['sort'] = 100;
        }

        return $data;
    }
}
