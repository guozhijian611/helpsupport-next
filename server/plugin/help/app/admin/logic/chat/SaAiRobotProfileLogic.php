<?php

namespace plugin\help\app\admin\logic\chat;

use plugin\help\app\model\chat\SaAiRobotProfile;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

/**
 * AI 机器人形象配置逻辑层
 */
class SaAiRobotProfileLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaAiRobotProfile();
        $this->orderField = 'sort';
        $this->orderType = 'ASC';
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
        foreach (['chat_mode', 'runtime_mode', 'display_name', 'display_name_en', 'avatar', 'dark_avatar'] as $field) {
            if (array_key_exists($field, $data)) {
                $data[$field] = trim((string) $data[$field]);
            }
        }
        foreach (['description', 'description_en'] as $field) {
            if (array_key_exists($field, $data)) {
                $data[$field] = trim((string) $data[$field]);
            }
        }
        foreach (['sort', 'status'] as $field) {
            if (array_key_exists($field, $data)) {
                $data[$field] = (int) $data[$field];
            }
        }

        return $data;
    }

    private function assertUnique(array $data, ?int $id = null): void
    {
        $chatMode = trim((string) ($data['chat_mode'] ?? ''));
        $runtimeMode = trim((string) ($data['runtime_mode'] ?? ''));
        if ($chatMode === '' || $runtimeMode === '') {
            return;
        }

        $query = Db::table('sa_ai_robot_profile')
            ->where('chat_mode', $chatMode)
            ->where('runtime_mode', $runtimeMode)
            ->whereNull('delete_time');
        if ($id !== null && $id > 0) {
            $query->where('id', '<>', $id);
        }

        if ($query->find()) {
            throw new ApiException('该聊天模式和运行模式的机器人形象已存在');
        }
    }
}
