<?php

namespace plugin\help\app\model\community;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 社区评论模型
 *
 * @property int $id
 * @property int $post_id
 * @property int $member_id
 * @property string $content
 * @property int $audit_status
 * @property int $status
 */
class SaCommunityComment extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_community_comment';

    public function searchPostIdAttr($query, $value): void
    {
        $query->where('post_id', (int) $value);
    }

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchContentAttr($query, $value): void
    {
        $query->where('content', 'like', '%' . $value . '%');
    }

    public function searchAuditStatusAttr($query, $value): void
    {
        $query->where('audit_status', (int) $value);
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
