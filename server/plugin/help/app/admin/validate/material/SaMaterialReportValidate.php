<?php

namespace plugin\help\app\admin\validate\material;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 素材举报验证器
 */
class SaMaterialReportValidate extends BaseValidate
{
    protected $rule = [
        'member_id' => 'require|integer',
        'target_type' => 'require|in:1,2',
        'target_id' => 'require|integer',
        'reason' => 'require|max:100',
        'description' => 'max:500',
        'handle_status' => 'require|in:0,1,2',
        'handle_remark' => 'max:500',
    ];

    protected $message = [
        'member_id' => '举报会员ID必须填写',
        'target_type' => '举报类型必须填写',
        'target_type.in' => '举报类型参数错误',
        'target_id' => '举报目标ID必须填写',
        'reason' => '举报原因必须填写',
        'reason.max' => '举报原因最多100个字符',
        'description.max' => '举报描述最多500个字符',
        'handle_status' => '处理状态必须填写',
        'handle_status.in' => '处理状态参数错误',
        'handle_remark.max' => '处理备注最多500个字符',
    ];

    protected $scene = [
        'save' => ['member_id', 'target_type', 'target_id', 'reason', 'description', 'handle_status', 'handle_remark'],
        'update' => ['member_id', 'target_type', 'target_id', 'reason', 'description', 'handle_status', 'handle_remark'],
    ];
}
