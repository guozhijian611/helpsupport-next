<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\validate\community;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 社区内容审核验证器
 */
class SaCommunityPostValidate extends BaseValidate
{
    /**
     * 定义验证规则
     */
    protected $rule =   [
        'member_id' => 'require',
        'content' => 'require',
        'link_url' => 'require',
        'is_anonymous' => 'require',
        'is_doctor_post' => 'require',
        'view_count' => 'require',
        'like_count' => 'require',
        'comment_count' => 'require',
        'collect_count' => 'require',
        'is_top' => 'require',
        'audit_status' => 'require',
        'audit_remark' => 'require',
        'status' => 'require',
    ];

    /**
     * 定义错误信息
     */
    protected $message  =   [
        'member_id' => '发帖会员ID必须填写',
        'content' => '帖子内容必须填写',
        'link_url' => '链接必须填写',
        'is_anonymous' => '是否匿名 1是 2否必须填写',
        'is_doctor_post' => '是否医生帖 1是 2否必须填写',
        'view_count' => '浏览数必须填写',
        'like_count' => '点赞数必须填写',
        'comment_count' => '评论数必须填写',
        'collect_count' => '收藏数必须填写',
        'is_top' => '是否置顶 1是 2否必须填写',
        'audit_status' => '审核状态 0人工待审 1已通过 2已拒绝 3AI审核中必须填写',
        'audit_remark' => '审核备注必须填写',
        'status' => '状态 1正常 2隐藏 3封禁必须填写',
    ];

    /**
     * 定义场景
     */
    protected $scene = [
        'save' => [
            'member_id',
            'content',
            'link_url',
            'is_anonymous',
            'is_doctor_post',
            'view_count',
            'like_count',
            'comment_count',
            'collect_count',
            'is_top',
            'audit_status',
            'audit_remark',
            'status',
        ],
        'update' => [
            'member_id',
            'content',
            'link_url',
            'is_anonymous',
            'is_doctor_post',
            'view_count',
            'like_count',
            'comment_count',
            'collect_count',
            'is_top',
            'audit_status',
            'audit_remark',
            'status',
        ],
    ];

}
