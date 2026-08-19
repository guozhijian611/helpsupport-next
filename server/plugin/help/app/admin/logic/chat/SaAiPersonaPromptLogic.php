<?php

namespace plugin\help\app\admin\logic\chat;

use plugin\help\app\model\chat\SaAiPersonaPrompt;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

class SaAiPersonaPromptLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaAiPersonaPrompt();
        $this->orderField = 'id';
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
        $data['persona_id'] = (int) ($data['persona_id'] ?? 0);
        $data['runtime_mode'] = trim((string) ($data['runtime_mode'] ?? 'online'));
        $data['locale'] = trim((string) ($data['locale'] ?? 'zh-CN'));
        $data['title'] = trim((string) ($data['title'] ?? ''));
        $data['system_prompt'] = trim((string) ($data['system_prompt'] ?? ''));
        $data['first_message'] = trim((string) ($data['first_message'] ?? ''));
        $data['safety_prompt'] = trim((string) ($data['safety_prompt'] ?? ''));
        $data['status'] = (int) ($data['status'] ?? 1) === 2 ? 2 : 1;

        return $data;
    }

    private function assertUnique(array $data, ?int $id = null): void
    {
        $query = Db::table('sa_ai_persona_prompt')
            ->where('persona_id', (int) $data['persona_id'])
            ->where('runtime_mode', (string) $data['runtime_mode'])
            ->where('locale', (string) $data['locale'])
            ->whereNull('delete_time');
        if ($id !== null && $id > 0) {
            $query->where('id', '<>', $id);
        }
        if ($query->find()) {
            throw new ApiException('该角色在同一语言和运行模式下已有预设提示词');
        }
    }
}
