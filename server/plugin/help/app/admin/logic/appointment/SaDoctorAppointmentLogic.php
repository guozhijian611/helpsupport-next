<?php

namespace plugin\help\app\admin\logic\appointment;

use plugin\help\app\model\appointment\SaDoctorAppointment;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

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
        $data = $this->normalizeFields($data);

        return Db::transaction(function () use ($data) {
            $this->reserveScheduleBookedCount((int) ($data['schedule_id'] ?? 0));
            $result = parent::add($data);

            return $result;
        });
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

        $appointment = $this->appointmentRow($id);
        return (bool) $this->edit($id, [
            'status' => 3,
            'cancel_reason' => $reason,
            'cancel_by' => $cancelBy,
            'canceled_at' => date('Y-m-d H:i:s'),
        ]) && $this->releaseScheduleBookedCount($appointment);
    }

    public function reject(int $id, string $remark): bool
    {
        $appointment = $this->appointmentRow($id);
        return (bool) $this->edit($id, [
            'status' => 4,
            'confirm_remark' => $remark,
        ]) && $this->releaseScheduleBookedCount($appointment);
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

    private function appointmentRow(int $id): array
    {
        return Db::table('sa_doctor_appointment')
            ->where('id', $id)
            ->whereNull('delete_time')
            ->find() ?: [];
    }

    private function reserveScheduleBookedCount(int $scheduleId): void
    {
        if ($scheduleId <= 0) {
            return;
        }

        $affected = Db::execute(
            'UPDATE `sa_doctor_schedule`
            SET `booked_count` = `booked_count` + 1, `update_time` = NOW()
            WHERE `id` = ' . $scheduleId . '
              AND `status` = 1
              AND `booked_count` < `capacity`
              AND `delete_time` IS NULL'
        );
        if ($affected < 1) {
            throw new ApiException('排班不存在或容量已满');
        }
    }

    private function releaseScheduleBookedCount(array $appointment): bool
    {
        $scheduleId = (int) ($appointment['schedule_id'] ?? 0);
        if ($scheduleId <= 0 || !in_array((int) ($appointment['status'] ?? -1), [0, 1], true)) {
            return true;
        }

        Db::execute(
            'UPDATE `sa_doctor_schedule`
            SET `booked_count` = IF(`booked_count` > 0, `booked_count` - 1, 0), `update_time` = NOW()
            WHERE `id` = ' . $scheduleId
        );

        return true;
    }
}
