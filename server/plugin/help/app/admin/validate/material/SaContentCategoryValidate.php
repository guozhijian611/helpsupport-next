<?php

namespace plugin\help\app\admin\validate\material;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 内容分类验证器
 */
class SaContentCategoryValidate extends BaseValidate
{
    protected $rule = [
        'parent_id' => 'integer',
        'name' => 'require|max:80',
        'type' => 'require|in:education,entertainment,private',
        'sort' => 'integer',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'parent_id.integer' => '父级分类ID必须为整数',
        'name.require' => '分类名称必须填写',
        'name.max' => '分类名称不能超过80个字符',
        'type.require' => '分类类型必须填写',
        'type.in' => '分类类型参数错误',
        'sort.integer' => '排序必须为整数',
        'status.require' => '状态必须填写',
        'status.in' => '状态参数错误',
    ];

    protected $scene = [
        'save' => ['parent_id', 'name', 'type', 'sort', 'status'],
        'update' => ['parent_id', 'name', 'type', 'sort', 'status'],
    ];
}
