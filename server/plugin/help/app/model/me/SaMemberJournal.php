<?php

namespace plugin\help\app\model\me;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 会员日记模型
 */
class SaMemberJournal extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_member_journal';

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchEntryDateAttr($query, $value): void
    {
        $query->where('entry_date', (string) $value);
    }

    public function searchTitleAttr($query, $value): void
    {
        $query->where('title', 'like', '%' . $value . '%');
    }

    public function searchIsPrivateAttr($query, $value): void
    {
        $query->where('is_private', (int) $value);
    }

    public function searchAiAccessAttr($query, $value): void
    {
        $query->where('ai_access', (int) $value);
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
