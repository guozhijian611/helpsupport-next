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
        $data['status'] = 0;

        return Db::transaction(function () use ($data) {
            $this->reserveScheduleBookedCount((int) ($data['schedule_id'] ?? 0));
            $result = parent::add($data);

            return $result;
        });
    }

    public function edit($id, array $data): mixed
    {
        if (array_key_exists('status', $data)) {
            $this->assertUnchangedStatus((int) $id, $data['status']);
        }

        return parent::edit($id, $this->normalizeFields($data));
    }

    public function confirm(int $id, string $meetType, string $meetLink, string $remark): bool
    {
        if ($meetType !== '' && !in_array($meetType, ['link', 'address', 'phone'], true)) {
            throw new ApiException('接诊方式参数错误');
        }

        $this->assertAppointmentStatus($id, [0], '只有待确认的预约可以确认');

        return (bool) parent::edit($id, $this->normalizeFields([
            'status' => 1,
            'meet_type' => $meetType !== '' ? $meetType : null,
            'meet_link' => $meetLink !== '' ? $meetLink : null,
            'confirm_remark' => $remark,
            'confirmed_at' => date('Y-m-d H:i:s'),
        ]));
    }

    public function finish(int $id): bool
    {
        $this->assertAppointmentStatus($id, [1], '只有已确认的预约可以完成');

        return (bool) parent::edit($id, [
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
        if ($reason === '') {
            throw new ApiException('取消原因必须填写');
        }

        return Db::transaction(function () use ($id, $reason, $cancelBy) {
            $appointment = $this->assertAppointmentStatus($id, [0, 1], '只有待确认或已确认的预约可以取消');

            return (bool) parent::edit($id, [
                'status' => 3,
                'cancel_reason' => $reason,
                'cancel_by' => $cancelBy,
                'canceled_at' => date('Y-m-d H:i:s'),
            ]) && $this->releaseScheduleBookedCount($appointment);
        });
    }

    public function reject(int $id, string $remark): bool
    {
        if ($remark === '') {
            throw new ApiException('拒绝原因必须填写');
        }

        return Db::transaction(function () use ($id, $remark) {
            $appointment = $this->assertAppointmentStatus($id, [0], '只有待确认的预约可以拒绝');

            return (bool) parent::edit($id, [
                'status' => 4,
                'confirm_remark' => $remark,
            ]) && $this->releaseScheduleBookedCount($appointment);
        });
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

    private function assertAppointmentStatus(int $id, array $allowedStatuses, string $message): array
    {
        $appointment = $this->appointmentRow($id);
        if (!$appointment) {
            throw new ApiException('预约不存在');
        }
        if (!in_array((int) ($appointment['status'] ?? -1), $allowedStatuses, true)) {
            throw new ApiException($message);
        }

        return $appointment;
    }

    private function assertUnchangedStatus(int $id, mixed $status): void
    {
        if (!is_numeric($status)) {
            throw new ApiException('预约状态参数错误');
        }

        $appointment = $this->assertAppointmentStatus($id, [0, 1, 2, 3, 4], '预约状态参数错误');
        if ((int) $status !== (int) ($appointment['status'] ?? -1)) {
            throw new ApiException('请通过确认、完成、取消或拒绝操作变更预约状态');
        }
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
