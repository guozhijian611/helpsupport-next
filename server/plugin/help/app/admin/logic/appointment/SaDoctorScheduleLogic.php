<?php

namespace plugin\help\app\admin\logic\appointment;

use plugin\help\app\model\appointment\SaDoctorSchedule;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

/**
 * 医生排班逻辑层
 */
class SaDoctorScheduleLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaDoctorSchedule();
        $this->orderField = 'schedule_date';
        $this->orderType = 'DESC';
    }

    public function add(array $data): mixed
    {
        return parent::add($this->normalizeFields($data));
    }

    public function edit($id, array $data): mixed
    {
        $schedule = $this->scheduleRow((int) $id);
        $this->assertUnchangedBookedCount($schedule, $data);
        if (!array_key_exists('booked_count', $data)) {
            $data['booked_count'] = (int) $schedule['booked_count'];
        }

        return parent::edit($id, $this->normalizeFields($data));
    }

    private function normalizeFields(array $data): array
    {
        $meetType = (string) ($data['meet_type'] ?? 'link');
        if (!in_array($meetType, ['link', 'address', 'phone'], true)) {
            throw new ApiException('接诊方式参数错误');
        }
        $data['meet_type'] = $meetType;

        foreach (['start_time', 'end_time', 'meet_link', 'remark'] as $field) {
            if (array_key_exists($field, $data) && $data[$field] === '') {
                $data[$field] = null;
            }
        }

        $data['capacity'] = max(1, (int) ($data['capacity'] ?? 1));
        $data['booked_count'] = max(0, (int) ($data['booked_count'] ?? 0));
        if ($data['booked_count'] > $data['capacity']) {
            throw new ApiException('已预约人数不能大于容量');
        }

        $data['price'] = number_format(max(0, (float) ($data['price'] ?? 0)), 2, '.', '');
        $data['currency'] = strtoupper(trim((string) ($data['currency'] ?? 'USD'))) ?: 'USD';

        return $data;
    }

    private function scheduleRow(int $id): array
    {
        $schedule = Db::table('sa_doctor_schedule')
            ->where('id', $id)
            ->whereNull('delete_time')
            ->find();
        if (!$schedule) {
            throw new ApiException('排班不存在');
        }

        return $schedule;
    }

    private function assertUnchangedBookedCount(array $schedule, array $data): void
    {
        if (!array_key_exists('booked_count', $data)) {
            return;
        }

        if ((int) $data['booked_count'] !== (int) $schedule['booked_count']) {
            throw new ApiException('已预约人数由预约操作自动维护，不能直接编辑');
        }
    }
}
