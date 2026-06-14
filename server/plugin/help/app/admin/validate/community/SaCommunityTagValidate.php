<?php

namespace plugin\help\app\admin\validate\community;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 社区标签验证器
 */
class SaCommunityTagValidate extends BaseValidate
{
    protected $rule = [
        'tag_name' => 'require|max:50',
        'color' => 'max:20',
        'sort' => 'integer',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'tag_name.require' => '标签名称必须填写',
        'tag_name.max' => '标签名称最多50个字符',
        'status.require' => '状态必须填写',
        'status.in' => '状态参数错误',
    ];

    protected $scene = [
        'save' => ['tag_name', 'color', 'sort', 'status'],
        'update' => ['tag_name', 'color', 'sort', 'status'],
    ];
}
