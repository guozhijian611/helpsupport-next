<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\model\community;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 社区内容审核模型
 *
 * sa_community_post 社区帖子表
 *
 * @property  $id 主键
 * @property  $member_id 发帖会员ID
 * @property  $content 帖子内容
 * @property  $images 图片URL数组
 * @property  $link_url 链接
 * @property  $tags 标签数组
 * @property  $is_anonymous 是否匿名 1是 2否
 * @property  $is_doctor_post 是否医生帖 1是 2否
 * @property  $view_count 浏览数
 * @property  $like_count 点赞数
 * @property  $comment_count 评论数
 * @property  $collect_count 收藏数
 * @property  $is_top 是否置顶 1是 2否
 * @property  $audit_status 审核状态 0待审核 1已通过 2已拒绝 3AI预审标记
 * @property  $audit_remark 审核备注
 * @property  $audit_by 审核人
 * @property  $audit_time 审核时间
 * @property  $status 状态 1正常 2隐藏 3封禁
 * @property  $created_by 创建者
 * @property  $updated_by 更新者
 * @property  $create_time 创建时间
 * @property  $update_time 修改时间
 */
class SaCommunityPost extends BaseModel
{
    /**
     * 数据表主键
     * @var string
     */
    protected $pk = 'id';

    /**
     * 数据库表名称
     * @var string
     */
    protected $table = 'sa_community_post';

}
