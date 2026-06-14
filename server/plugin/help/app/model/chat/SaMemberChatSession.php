<?php

namespace plugin\help\app\model\chat;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 会员聊天会话模型
 */
class SaMemberChatSession extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_member_chat_session';

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchChatModeAttr($query, $value): void
    {
        $query->where('chat_mode', (string) $value);
    }

    public function searchSessionNameAttr($query, $value): void
    {
        $query->where('session_name', 'like', '%' . $value . '%');
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
