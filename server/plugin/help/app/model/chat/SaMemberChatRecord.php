<?php

namespace plugin\help\app\model\chat;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 会员聊天记录模型
 */
class SaMemberChatRecord extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_member_chat_record';

    public function searchSessionIdAttr($query, $value): void
    {
        $query->where('session_id', (int) $value);
    }

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchChatModeAttr($query, $value): void
    {
        $query->where('chat_mode', (string) $value);
    }

    public function searchRoleAttr($query, $value): void
    {
        $query->where('role', (string) $value);
    }

    public function searchContentAttr($query, $value): void
    {
        $query->where('content', 'like', '%' . $value . '%');
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
