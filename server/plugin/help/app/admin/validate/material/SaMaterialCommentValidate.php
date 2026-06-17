<?php

namespace plugin\help\app\admin\validate\material;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 素材评论验证器
 */
class SaMaterialCommentValidate extends BaseValidate
{
    protected $rule = [
        'id' => 'require|integer',
        'status' => 'require|in:1,2',
        'audit_status' => 'require|in:1,2',
        'audit_remark' => 'max:500',
    ];

    protected $message = [
        'id.require' => '评论ID必须填写',
        'id.integer' => '评论ID参数错误',
        'status.require' => '状态必须填写',
        'status.in' => '状态参数错误',
        'audit_status.require' => '审核状态必须填写',
        'audit_status.in' => '审核状态参数错误',
        'audit_remark.max' => '审核备注最多500个字符',
    ];

    protected $scene = [
        'status' => ['id', 'status'],
        'audit' => ['id', 'audit_status', 'audit_remark'],
    ];
}
