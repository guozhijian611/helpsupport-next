<?php

namespace plugin\help\app\admin\logic\appointment;

use plugin\help\app\model\appointment\SaDoctorAppointment;
use plugin\help\app\service\HelpBadgeService;
use plugin\help\app\service\HelpPointService;
use plugin\help\app\service\HelpPushService;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use think\facade\Db;
use Throwable;

/**
 * 医生预约逻辑层
 */
class SaDoctorAppointmentLogic extends BaseLogic
{
    private const IMMUTABLE_EDIT_FIELDS = [
        'member_id' => '患者会员ID',
        'doctor_id' => '医生会员ID',
        'schedule_id' => '排班ID',
        'appoint_date' => '预约日期',
        'appoint_time_slot' => '预约时间段',
    ];

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
            $data = $this->applyScheduleSnapshotForCreate($data);
            $this->assertNoActiveAppointmentForSchedule(
                (int) ($data['member_id'] ?? 0),
                (int) ($data['schedule_id'] ?? 0)
            );
            $this->reserveScheduleBookedCount((int) ($data['schedule_id'] ?? 0));
            $result = parent::add($data);

            return $result;
        });
    }

    public function edit($id, array $data): mixed
    {
        $appointment = $this->appointmentRow((int) $id);
        if (!$appointment) {
            throw new ApiException('预约不存在');
        }
        $this->assertImmutableEditFields($appointment, $data);

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

        $appointment = $this->assertAppointmentStatus($id, [0], '只有待确认的预约可以确认');
        $result = Db::transaction(function () use ($id, $appointment, $meetType, $meetLink, $remark) {
            $ok = (bool) parent::edit($id, $this->normalizeFields([
                'status' => 1,
                'meet_type' => $meetType !== '' ? $meetType : null,
                'meet_link' => $meetLink !== '' ? $meetLink : null,
                'confirm_remark' => $remark,
                'confirmed_at' => date('Y-m-d H:i:s'),
            ]));
            if ($ok) {
                $this->upsertDoctorPatientRelation((int) $appointment['doctor_id'], (int) $appointment['member_id']);
            }

            return $ok;
        });
        if ($result) {
            $this->notifyAppointmentMember($appointment, 'confirmed');
        }

        return $result;
    }

    public function finish(int $id): bool
    {
        $appointment = $this->assertAppointmentStatus($id, [1], '只有已确认的预约可以完成');
        $result = Db::transaction(function () use ($id, $appointment) {
            $ok = (bool) parent::edit($id, [
                'status' => 2,
                'finished_at' => date('Y-m-d H:i:s'),
            ]);
            if ($ok) {
                (new HelpBadgeService())->awardAppointmentDone((int) $appointment['member_id'], $id);
            }

            return $ok;
        });
        if ($result) {
            $this->notifyAppointmentMember($appointment, 'finished');
        }

        return $result;
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

        $appointment = [];
        $result = Db::transaction(function () use ($id, $reason, $cancelBy, &$appointment) {
            $appointment = $this->assertAppointmentStatus($id, [0, 1], '只有待确认或已确认的预约可以取消');

            return (bool) parent::edit($id, [
                'status' => 3,
                'cancel_reason' => $reason,
                'cancel_by' => $cancelBy,
                'canceled_at' => date('Y-m-d H:i:s'),
            ]) && $this->releaseScheduleBookedCount($appointment) && $this->refundAppointmentPointsIfNeeded($appointment, '后台取消预约退回积分');
        });
        if ($result) {
            $this->notifyAppointmentMember($appointment, 'canceled');
        }

        return $result;
    }

    public function reject(int $id, string $remark): bool
    {
        if ($remark === '') {
            throw new ApiException('拒绝原因必须填写');
        }

        $appointment = [];
        $result = Db::transaction(function () use ($id, $remark, &$appointment) {
            $appointment = $this->assertAppointmentStatus($id, [0], '只有待确认的预约可以拒绝');

            return (bool) parent::edit($id, [
                'status' => 4,
                'confirm_remark' => $remark,
            ]) && $this->releaseScheduleBookedCount($appointment) && $this->refundAppointmentPointsIfNeeded($appointment, '后台拒绝预约退回积分');
        });
        if ($result) {
            $this->notifyAppointmentMember($appointment, 'rejected');
        }

        return $result;
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

        if (array_key_exists('payment_method', $data)) {
            $paymentMethod = trim((string) $data['payment_method']);
            $data['payment_method'] = in_array($paymentMethod, ['cash', 'points'], true) ? $paymentMethod : 'cash';
        }
        foreach (['points_cost', 'points_log_id', 'points_refund_log_id'] as $field) {
            if (array_key_exists($field, $data)) {
                $data[$field] = max(0, (int) $data[$field]);
            }
        }

        return $data;
    }

    private function applyScheduleSnapshotForCreate(array $data): array
    {
        $scheduleId = (int) ($data['schedule_id'] ?? 0);
        if ($scheduleId <= 0) {
            return $data;
        }

        $schedule = $this->lockAvailableSchedule($scheduleId);
        $this->assertScheduleSnapshotMatches($data, $schedule);

        $data['doctor_id'] = (int) $schedule['doctor_id'];
        $data['appoint_date'] = (string) $schedule['schedule_date'];
        $data['appoint_time_slot'] = (string) $schedule['time_slot'];
        $data['price'] = (string) $schedule['price'];
        $data['currency'] = (string) $schedule['currency'];

        if (empty($data['meet_type'])) {
            $data['meet_type'] = (string) $schedule['meet_type'];
        }
        if (empty($data['meet_link']) && !empty($schedule['meet_link'])) {
            $data['meet_link'] = (string) $schedule['meet_link'];
        }

        return $data;
    }

    private function lockAvailableSchedule(int $scheduleId): array
    {
        $schedule = Db::table('sa_doctor_schedule')
            ->where('id', $scheduleId)
            ->where('status', 1)
            ->whereRaw('`booked_count` < `capacity`')
            ->whereNull('delete_time')
            ->lock(true)
            ->find();
        if (!$schedule) {
            throw new ApiException('排班不存在或容量已满');
        }

        return $schedule;
    }

    private function assertScheduleSnapshotMatches(array $data, array $schedule): void
    {
        $checks = [
            'doctor_id' => [(int) ($data['doctor_id'] ?? 0), (int) $schedule['doctor_id'], '预约医生与排班不一致'],
            'appoint_date' => [trim((string) ($data['appoint_date'] ?? '')), (string) $schedule['schedule_date'], '预约日期与排班不一致'],
            'appoint_time_slot' => [trim((string) ($data['appoint_time_slot'] ?? '')), (string) $schedule['time_slot'], '预约时间段与排班不一致'],
        ];

        foreach ($checks as [$input, $expected, $message]) {
            if ($input !== '' && $input !== 0 && $input !== $expected) {
                throw new ApiException($message);
            }
        }
    }

    private function assertImmutableEditFields(array $appointment, array $data): void
    {
        foreach (self::IMMUTABLE_EDIT_FIELDS as $field => $label) {
            if (!array_key_exists($field, $data)) {
                continue;
            }

            $input = $this->normalizeImmutableValue($field, $data[$field]);
            $current = $this->normalizeImmutableValue($field, $appointment[$field] ?? null);
            if ($input !== $current) {
                throw new ApiException($label . '不可直接编辑，请取消后重新预约');
            }
        }
    }

    private function normalizeImmutableValue(string $field, mixed $value): int|string
    {
        if (in_array($field, ['member_id', 'doctor_id', 'schedule_id'], true)) {
            return (int) $value;
        }

        return trim((string) $value);
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

    private function assertNoActiveAppointmentForSchedule(int $memberId, int $scheduleId): void
    {
        if ($memberId <= 0 || $scheduleId <= 0) {
            return;
        }

        $exists = Db::table('sa_doctor_appointment')
            ->where('member_id', $memberId)
            ->where('schedule_id', $scheduleId)
            ->whereIn('status', [0, 1])
            ->whereNull('delete_time')
            ->find();
        if ($exists) {
            throw new ApiException('该患者在此排班已有待处理预约，请勿重复添加');
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

    private function refundAppointmentPointsIfNeeded(array $appointment, string $title): bool
    {
        $config = $this->appointmentPaymentConfig();
        $memberId = (int) ($appointment['member_id'] ?? 0);
        $appointmentId = (int) ($appointment['id'] ?? 0);
        $pointsCost = (int) ($appointment['points_cost'] ?? 0);
        if (
            !$config['refund_on_cancel']
            || $memberId <= 0
            || $appointmentId <= 0
            || (string) ($appointment['payment_method'] ?? '') !== 'points'
            || $pointsCost <= 0
            || (int) ($appointment['points_log_id'] ?? 0) <= 0
            || (int) ($appointment['points_refund_log_id'] ?? 0) > 0
        ) {
            return true;
        }

        $refundLogId = (int) ((new HelpPointService())->addLog([
            'member_id' => $memberId,
            'points' => $pointsCost,
            'change_type' => 'income',
            'source_type' => 'doctor_appointment_refund',
            'source_id' => $appointmentId,
            'title' => $title,
            'remark' => '积分预约未完成，系统自动退回积分',
        ], null) ?? 0);

        if ($refundLogId > 0) {
            Db::table('sa_doctor_appointment')->where('id', $appointmentId)->update([
                'points_refund_log_id' => $refundLogId,
                'update_time' => date('Y-m-d H:i:s'),
            ]);
        }

        return true;
    }

    private function appointmentPaymentConfig(): array
    {
        $rows = Db::table('sa_system_config_group')
            ->alias('g')
            ->leftJoin('sa_system_config c', 'c.group_id = g.id AND c.delete_time IS NULL')
            ->where('g.code', 'help_appointment_payment')
            ->whereNull('g.delete_time')
            ->field('c.key, c.value')
            ->select()
            ->toArray();

        $config = [];
        foreach ($rows as $row) {
            if (!empty($row['key'])) {
                $config[(string) $row['key']] = (string) ($row['value'] ?? '');
            }
        }

        return [
            'refund_on_cancel' => ($config['refund_on_cancel'] ?? '1') === '1',
        ];
    }

    private function upsertDoctorPatientRelation(int $doctorId, int $memberId): void
    {
        if ($doctorId <= 0 || $memberId <= 0) {
            return;
        }

        $now = date('Y-m-d H:i:s');
        $exists = Db::table('sa_doctor_patient')
            ->where('doctor_id', $doctorId)
            ->where('member_id', $memberId)
            ->find();
        if ($exists) {
            Db::table('sa_doctor_patient')->where('id', $exists['id'])->update([
                'status' => 1,
                'bind_source' => 'appointment',
                'bind_time' => $now,
                'unbind_time' => null,
                'delete_time' => null,
                'updated_by' => $doctorId,
                'update_time' => $now,
            ]);
            return;
        }

        Db::table('sa_doctor_patient')->insert([
            'doctor_id' => $doctorId,
            'member_id' => $memberId,
            'status' => 1,
            'bind_source' => 'appointment',
            'bind_time' => $now,
            'created_by' => $doctorId,
            'updated_by' => $doctorId,
            'create_time' => $now,
            'update_time' => $now,
        ]);
    }

    private function notifyAppointmentMember(array $appointment, string $statusText): void
    {
        $memberId = (int) ($appointment['member_id'] ?? 0);
        $appointmentId = (int) ($appointment['id'] ?? 0);
        if ($memberId <= 0 || $appointmentId <= 0) {
            return;
        }

        try {
            (new HelpPushService())->notifyMember($memberId, 'appointment_update', [
                'status_text' => $statusText,
            ], [
                'biz_type' => 'appointment',
                'biz_id' => $appointmentId,
                'route' => '/appointments/mine',
                'payload' => ['appointment_id' => $appointmentId],
            ]);
        } catch (Throwable) {
            // 预约状态已落库，通知失败不阻断后台操作。
        }
    }
}
