<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\logic\chat;

use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use plugin\help\app\model\chat\SaMemberChatConfig;
use think\facade\Db;

/**
 * AI聊天配置逻辑层
 */
class SaMemberChatConfigLogic extends BaseLogic
{
    /**
     * 构造函数
     */
    public function __construct()
    {
        $this->model = new SaMemberChatConfig();
    }

    public function add(array $data): mixed
    {
        $data = $this->normalizeFields($data);
        $this->assertUnique($data);

        return parent::add($data);
    }

    public function edit($id, array $data): mixed
    {
        $data = $this->normalizeFields($data);
        $this->assertUnique($data, (int) $id);

        return parent::edit($id, $data);
    }

    private function normalizeFields(array $data): array
    {
        if (array_key_exists('member_id', $data)) {
            $data['member_id'] = (int) $data['member_id'];
        }
        if (array_key_exists('chat_mode', $data)) {
            $data['chat_mode'] = trim((string) $data['chat_mode']);
        }
        if (array_key_exists('online_config_id', $data)) {
            $data['online_config_id'] = max(0, (int) $data['online_config_id']);
        }

        return $data;
    }

    private function assertUnique(array $data, ?int $id = null): void
    {
        $memberId = (int) ($data['member_id'] ?? 0);
        $chatMode = trim((string) ($data['chat_mode'] ?? ''));
        if ($memberId <= 0 || $chatMode === '') {
            return;
        }

        $query = Db::table('sa_member_chat_config')
            ->where('member_id', $memberId)
            ->where('chat_mode', $chatMode)
            ->whereNull('delete_time');
        if ($id !== null && $id > 0) {
            $query->where('id', '<>', $id);
        }

        if ($query->find()) {
            throw new ApiException('该会员的聊天模式配置已存在');
        }
    }
}
