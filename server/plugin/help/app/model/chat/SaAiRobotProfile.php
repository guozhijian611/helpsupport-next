<?php

namespace plugin\help\app\model\chat;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * AI 机器人形象配置模型
 */
class SaAiRobotProfile extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_ai_robot_profile';

    public function searchChatModeAttr($query, $value): void
    {
        $query->where('chat_mode', (string) $value);
    }

    public function searchRuntimeModeAttr($query, $value): void
    {
        $query->where('runtime_mode', (string) $value);
    }

    public function searchDisplayNameAttr($query, $value): void
    {
        $query->where('display_name', 'like', '%' . $value . '%');
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
