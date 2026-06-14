<?php

namespace plugin\help\app\admin\logic\push;

use plugin\help\app\model\push\SaMemberPushPreference;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

/**
 * 会员推送偏好逻辑层
 */
class SaMemberPushPreferenceLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberPushPreference();
        $this->orderField = 'id';
        $this->orderType = 'DESC';
    }

    public function add(array $data): mixed
    {
        $data = $this->normalizeFields($data, true);
        $this->assertUnique($data);

        return parent::add($data);
    }

    public function edit($id, array $data): mixed
    {
        $data = $this->normalizeFields($data);
        $this->assertUnique($data, (int) $id);

        return parent::edit($id, $data);
    }

    public function enable(string $id): bool
    {
        if ($id === '') {
            throw new ApiException('请选择要启用的推送偏好');
        }

        return (bool) $this->edit($id, ['is_push_enabled' => 1]);
    }

    public function disable(string $id): bool
    {
        if ($id === '') {
            throw new ApiException('请选择要停用的推送偏好');
        }

        return (bool) $this->edit($id, ['is_push_enabled' => 2]);
    }

    private function normalizeFields(array $data, bool $isCreate = false): array
    {
        foreach ([
            'is_push_enabled' => 1,
            'is_task_reminder_enabled' => 1,
            'is_community_enabled' => 1,
            'is_appointment_enabled' => 1,
            'is_audit_notice_enabled' => 1,
            'is_local_companion_enabled' => 1,
        ] as $field => $default) {
            if ($isCreate && (!array_key_exists($field, $data) || $data[$field] === '')) {
                $data[$field] = $default;
                continue;
            }
            if (!$isCreate && array_key_exists($field, $data) && $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        foreach (['quiet_start_time', 'quiet_end_time'] as $field) {
            if (array_key_exists($field, $data) && $data[$field] === '') {
                $data[$field] = null;
            }
        }

        return $data;
    }

    private function assertUnique(array $data, ?int $id = null): void
    {
        $memberId = (int) ($data['member_id'] ?? 0);
        if ($memberId <= 0) {
            return;
        }

        $query = Db::table('sa_member_push_preference')
            ->where('member_id', $memberId)
            ->whereNull('delete_time');
        if ($id !== null && $id > 0) {
            $query->where('id', '<>', $id);
        }

        if ($query->find()) {
            throw new ApiException('该会员的推送偏好已存在');
        }
    }
}
