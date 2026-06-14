<?php

namespace plugin\help\app\admin\validate\push;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 会员推送偏好验证器
 */
class SaMemberPushPreferenceValidate extends BaseValidate
{
    protected $rule = [
        'id' => 'require',
        'member_id' => 'require|integer',
        'is_push_enabled' => 'in:1,2',
        'is_task_reminder_enabled' => 'in:1,2',
        'is_community_enabled' => 'in:1,2',
        'is_appointment_enabled' => 'in:1,2',
        'is_audit_notice_enabled' => 'in:1,2',
        'is_local_companion_enabled' => 'in:1,2',
        'quiet_start_time' => 'max:8',
        'quiet_end_time' => 'max:8',
    ];

    protected $message = [
        'id.require' => '推送偏好ID必须填写',
        'member_id.require' => '会员ID必须填写',
        'member_id.integer' => '会员ID必须为整数',
        'is_push_enabled.in' => '总通知开关只能为1或2',
        'is_task_reminder_enabled.in' => '任务提醒开关只能为1或2',
        'is_community_enabled.in' => '社区互动开关只能为1或2',
        'is_appointment_enabled.in' => '预约提醒开关只能为1或2',
        'is_audit_notice_enabled.in' => '审核通知开关只能为1或2',
        'is_local_companion_enabled.in' => '本地陪伴提醒开关只能为1或2',
        'quiet_start_time.max' => '免打扰开始时间最多8个字符',
        'quiet_end_time.max' => '免打扰结束时间最多8个字符',
    ];

    protected $scene = [
        'save' => [
            'member_id',
            'is_push_enabled',
            'is_task_reminder_enabled',
            'is_community_enabled',
            'is_appointment_enabled',
            'is_audit_notice_enabled',
            'is_local_companion_enabled',
            'quiet_start_time',
            'quiet_end_time',
        ],
        'update' => [
            'id',
            'member_id',
            'is_push_enabled',
            'is_task_reminder_enabled',
            'is_community_enabled',
            'is_appointment_enabled',
            'is_audit_notice_enabled',
            'is_local_companion_enabled',
            'quiet_start_time',
            'quiet_end_time',
        ],
    ];
}
