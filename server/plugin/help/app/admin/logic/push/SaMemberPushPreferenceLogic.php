<?php

namespace plugin\help\app\admin\logic\push;

use plugin\help\app\model\push\SaMemberPushPreference;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;

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
        return parent::add($this->normalizeFields($data));
    }

    public function edit($id, array $data): mixed
    {
        return parent::edit($id, $this->normalizeFields($data));
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

    private function normalizeFields(array $data): array
    {
        foreach ([
            'is_push_enabled' => 1,
            'is_task_reminder_enabled' => 1,
            'is_community_enabled' => 1,
            'is_appointment_enabled' => 1,
            'is_audit_notice_enabled' => 1,
            'is_local_companion_enabled' => 1,
        ] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
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
}
