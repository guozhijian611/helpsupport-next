<?php

namespace plugin\help\app\model\community;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 社区举报模型
 *
 * @property int $id
 * @property int $member_id
 * @property int $target_type
 * @property int $target_id
 * @property string $reason
 * @property int $handle_status
 */
class SaCommunityReport extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_community_report';

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchTargetTypeAttr($query, $value): void
    {
        $query->where('target_type', (int) $value);
    }

    public function searchTargetIdAttr($query, $value): void
    {
        $query->where('target_id', (int) $value);
    }

    public function searchReasonAttr($query, $value): void
    {
        $query->where('reason', 'like', '%' . $value . '%');
    }

    public function searchHandleStatusAttr($query, $value): void
    {
        $query->where('handle_status', (int) $value);
    }
}
