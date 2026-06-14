<?php

namespace plugin\help\app\admin\logic\doctor;

use plugin\help\app\model\doctor\SaDoctorPatient;
use plugin\saiadmin\basic\think\BaseLogic;

/**
 * 医生患者绑定关系逻辑层
 */
class SaDoctorPatientLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaDoctorPatient();
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
        if (!array_key_exists('bind_time', $data) || $data['bind_time'] === '') {
            $data['bind_time'] = date('Y-m-d H:i:s');
        }

        if (array_key_exists('unbind_time', $data) && $data['unbind_time'] === '') {
            $data['unbind_time'] = null;
        }

        return $data;
    }
}
