<?php

namespace plugin\help\app\admin\validate\community;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 社区举报验证器
 */
class SaCommunityReportValidate extends BaseValidate
{
    protected $rule = [
        'member_id' => 'require',
        'target_type' => 'require',
        'target_id' => 'require',
        'reason' => 'require',
        'handle_status' => 'require',
    ];

    protected $message = [
        'member_id' => '举报会员ID必须填写',
        'target_type' => '举报类型必须填写',
        'target_id' => '举报目标ID必须填写',
        'reason' => '举报原因必须填写',
        'handle_status' => '处理状态必须填写',
    ];

    protected $scene = [
        'save' => ['member_id', 'target_type', 'target_id', 'reason', 'handle_status'],
        'update' => ['member_id', 'target_type', 'target_id', 'reason', 'handle_status'],
    ];
}
