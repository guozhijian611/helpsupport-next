<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\logic\localModel;

use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use plugin\help\app\model\localModel\SaLocalModelPrompt;
use think\facade\Db;

/**
 * 本地模型提示词逻辑层
 */
class SaLocalModelPromptLogic extends BaseLogic
{
    /**
     * 构造函数
     */
    public function __construct()
    {
        $this->model = new SaLocalModelPrompt();
    }

    public function add(array $data): mixed
    {
        $data = $this->normalizeFields($data, true);
        $this->assertModelExists($data);
        $this->assertUnique($data);

        return parent::add($data);
    }

    public function edit($id, array $data): mixed
    {
        $data = $this->normalizeFields($data);
        $this->assertModelExists($data);
        $this->assertUnique($data, (int) $id);

        return parent::edit($id, $data);
    }

    private function normalizeFields(array $data, bool $isCreate = false): array
    {
        if ($isCreate && !array_key_exists('model_id', $data)) {
            $data['model_id'] = null;
        }
        if (array_key_exists('model_id', $data) && ($data['model_id'] === '' || (int) $data['model_id'] === 0)) {
            $data['model_id'] = null;
        }
        if (array_key_exists('chat_mode', $data)) {
            $data['chat_mode'] = trim((string) $data['chat_mode']);
        }
        if (array_key_exists('locale', $data)) {
            $data['locale'] = trim((string) $data['locale']);
        }

        return $data;
    }

    private function assertModelExists(array $data): void
    {
        if (!array_key_exists('model_id', $data) || $data['model_id'] === null) {
            return;
        }

        $exists = Db::table('sa_local_model_catalog')
            ->where('id', (int) $data['model_id'])
            ->whereNull('delete_time')
            ->find();
        if (!$exists) {
            throw new ApiException('关联模型不存在');
        }
    }

    private function assertUnique(array $data, ?int $id = null): void
    {
        $chatMode = trim((string) ($data['chat_mode'] ?? ''));
        $locale = trim((string) ($data['locale'] ?? ''));
        if ($chatMode === '' || $locale === '') {
            return;
        }

        $query = Db::table('sa_local_model_prompt')
            ->where('chat_mode', $chatMode)
            ->where('locale', $locale)
            ->whereNull('delete_time');
        if (($data['model_id'] ?? null) === null) {
            $query->whereNull('model_id');
        } else {
            $query->where('model_id', (int) $data['model_id']);
        }
        if ($id !== null && $id > 0) {
            $query->where('id', '<>', $id);
        }

        if ($query->find()) {
            throw new ApiException('该模型聊天模式和语言的提示词已存在');
        }
    }
}
