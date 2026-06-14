<?php

namespace plugin\help\app\admin\logic\appointment;

use plugin\help\app\model\appointment\SaDoctorAppointment;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;

/**
 * 医生预约逻辑层
 */
class SaDoctorAppointmentLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaDoctorAppointment();
        $this->orderField = 'appoint_date';
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

    public function confirm(int $id, string $meetType, string $meetLink, string $remark): bool
    {
        if ($meetType !== '' && !in_array($meetType, ['link', 'address', 'phone'], true)) {
            throw new ApiException('接诊方式参数错误');
        }

        return (bool) $this->edit($id, [
            'status' => 1,
            'meet_type' => $meetType !== '' ? $meetType : null,
            'meet_link' => $meetLink !== '' ? $meetLink : null,
            'confirm_remark' => $remark,
            'confirmed_at' => date('Y-m-d H:i:s'),
        ]);
    }

    public function finish(int $id): bool
    {
        return (bool) $this->edit($id, [
            'status' => 2,
            'finished_at' => date('Y-m-d H:i:s'),
        ]);
    }

    public function cancel(int $id, string $reason, string $cancelBy = 'system'): bool
    {
        $cancelBy = $cancelBy !== '' ? $cancelBy : 'system';
        if (!in_array($cancelBy, ['member', 'doctor', 'system'], true)) {
            throw new ApiException('取消方参数错误');
        }

        return (bool) $this->edit($id, [
            'status' => 3,
            'cancel_reason' => $reason,
            'cancel_by' => $cancelBy,
            'canceled_at' => date('Y-m-d H:i:s'),
        ]);
    }

    public function reject(int $id, string $remark): bool
    {
        return (bool) $this->edit($id, [
            'status' => 4,
            'confirm_remark' => $remark,
        ]);
    }

    private function normalizeFields(array $data): array
    {
        foreach (['meet_type', 'meet_link', 'confirm_remark', 'cancel_reason', 'cancel_by'] as $field) {
            if (array_key_exists($field, $data) && $data[$field] === '') {
                $data[$field] = null;
            }
        }

        foreach (['confirmed_at', 'finished_at', 'canceled_at'] as $field) {
            if (array_key_exists($field, $data) && $data[$field] === '') {
                $data[$field] = null;
            }
        }

        return $data;
    }
}
