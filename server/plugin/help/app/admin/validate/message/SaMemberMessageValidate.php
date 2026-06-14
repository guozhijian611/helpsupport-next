<?php

namespace plugin\help\app\admin\validate\message;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 会员消息中心验证器
 */
class SaMemberMessageValidate extends BaseValidate
{
    protected $rule = [
        'id' => 'require',
        'member_id' => 'require|integer',
        'message_type' => 'require|in:1,2,3,4,5',
        'title' => 'require|max:160',
        'content' => 'require|max:1000',
        'device_token' => 'max:255',
        'is_pushed' => 'in:1,2',
        'push_status' => 'in:0,1,2',
        'is_read' => 'in:1,2',
        'biz_type' => 'max:50',
        'biz_id' => 'integer',
        'route' => 'max:500',
        'status' => 'in:1,2',
    ];

    protected $message = [
        'id.require' => '消息ID必须填写',
        'member_id.require' => '接收会员ID必须填写',
        'member_id.integer' => '接收会员ID必须为整数',
        'message_type.require' => '消息类型必须填写',
        'message_type.in' => '消息类型只能为1关注、2回复、3任务、4预约、5系统',
        'title.require' => '消息标题必须填写',
        'title.max' => '消息标题最多160个字符',
        'content.require' => '消息内容必须填写',
        'content.max' => '消息内容最多1000个字符',
        'device_token.max' => '设备推送token最多255个字符',
        'is_pushed.in' => '是否已推送只能为1或2',
        'push_status.in' => '推送状态只能为0、1或2',
        'is_read.in' => '是否已读只能为1或2',
        'biz_type.max' => '业务类型最多50个字符',
        'biz_id.integer' => '业务ID必须为整数',
        'route.max' => '跳转路由最多500个字符',
        'status.in' => '状态只能为1或2',
    ];

    protected $scene = [
        'save' => [
            'member_id',
            'message_type',
            'title',
            'content',
            'device_token',
            'is_pushed',
            'push_status',
            'is_read',
            'biz_type',
            'biz_id',
            'route',
            'status',
        ],
        'update' => [
            'id',
            'member_id',
            'message_type',
            'title',
            'content',
            'device_token',
            'is_pushed',
            'push_status',
            'is_read',
            'biz_type',
            'biz_id',
            'route',
            'status',
        ],
    ];
}
