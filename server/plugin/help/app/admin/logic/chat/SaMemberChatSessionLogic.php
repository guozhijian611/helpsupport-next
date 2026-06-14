<?php

namespace plugin\help\app\admin\logic\chat;

use plugin\help\app\model\chat\SaMemberChatSession;
use plugin\saiadmin\basic\think\BaseLogic;

/**
 * 会员聊天会话逻辑层
 */
class SaMemberChatSessionLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberChatSession();
        $this->orderField = 'last_message_time';
        $this->orderType = 'DESC';
    }

    public function add(array $data): mixed
    {
        return parent::add($this->normalizeFields($data));
    }

    public function edit($id, array $data): mixed
    {
        return parent::edit($id, $this->normalizeFields($data));
    }

    private function normalizeFields(array $data): array
    {
        if (array_key_exists('last_message_time', $data) && $data['last_message_time'] === '') {
            $data['last_message_time'] = null;
        }
        foreach (['is_pinned' => 2, 'status' => 1] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        return $data;
    }
}
