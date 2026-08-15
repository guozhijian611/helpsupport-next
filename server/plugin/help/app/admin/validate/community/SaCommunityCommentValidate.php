<?php

namespace plugin\help\app\admin\validate\community;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 社区评论验证器
 */
class SaCommunityCommentValidate extends BaseValidate
{
    protected $rule = [
        'post_id' => 'require',
        'member_id' => 'require',
        'content' => 'require',
        'audit_status' => 'require|in:0,1,2,3',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'post_id' => '帖子ID必须填写',
        'member_id' => '评论会员ID必须填写',
        'content' => '评论内容必须填写',
        'audit_status' => '审核状态 0人工待审 1已通过 2已拒绝 3AI审核中必须填写',
        'audit_status.in' => '审核状态参数错误',
        'status' => '状态必须填写',
        'status.in' => '状态参数错误',
    ];

    protected $scene = [
        'save' => ['post_id', 'member_id', 'content', 'audit_status', 'status'],
        'update' => ['post_id', 'member_id', 'content', 'audit_status', 'status'],
    ];
}
