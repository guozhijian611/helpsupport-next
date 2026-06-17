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
    ];

    protected $message = [
        'id.require' => '评论ID必须填写',
        'id.integer' => '评论ID参数错误',
        'status.require' => '状态必须填写',
        'status.in' => '状态参数错误',
    ];

    protected $scene = [
        'status' => ['id', 'status'],
    ];
}
