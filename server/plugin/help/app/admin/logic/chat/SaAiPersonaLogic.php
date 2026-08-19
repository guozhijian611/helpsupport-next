<?php

namespace plugin\help\app\admin\logic\chat;

use plugin\help\app\model\chat\SaAiPersona;
use plugin\help\app\service\ChatPersonaCatalog;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

class SaAiPersonaLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaAiPersona();
        $this->orderField = 'sort';
        $this->orderType = 'ASC';
    }

    public function add(array $data): mixed
    {
        $data = $this->normalizeFields($data);
        $this->assertUniqueCode($data['code']);

        return parent::add($data);
    }

    public function edit($id, array $data): mixed
    {
        $current = $this->read($id);
        if (!$current) {
            throw new ApiException('角色不存在');
        }
        $row = is_array($current) ? $current : $current->toArray();
        if ((int) ($row['is_system'] ?? 2) === 1) {
            $data['code'] = (string) $row['code'];
            $data['is_system'] = 1;
        }
        $data = $this->normalizeFields($data);
        $this->assertUniqueCode($data['code'], (int) $id);

        return parent::edit($id, $data);
    }

    public function destroy($ids): mixed
    {
        $idList = is_array($ids) ? $ids : explode(',', (string) $ids);
        $system = Db::table('sa_ai_persona')
            ->whereIn('id', $idList)
            ->where('is_system', 1)
            ->whereNull('delete_time')
            ->count();
        if ((int) $system > 0) {
            throw new ApiException('内置角色不能删除，只能停用');
        }

        return parent::destroy($ids);
    }

    /**
     * @return list<array{label:string,value:string}>
     */
    public function options(): array
    {
        return array_map(static function (array $row): array {
            return [
                'label' => (string) ($row['display_name'] ?: $row['code']),
                'value' => (string) $row['code'],
            ];
        }, ChatPersonaCatalog::enabledRows());
    }

    private function normalizeFields(array $data): array
    {
        $titleZh = trim((string) ($data['title_zh'] ?? $data['display_name'] ?? ''));
        $titleEn = trim((string) ($data['title_en'] ?? $data['display_name_en'] ?? ''));
        $descZh = trim((string) ($data['description_zh'] ?? $data['description'] ?? ''));
        $descEn = trim((string) ($data['description_en'] ?? $data['description_en'] ?? ''));
        $tagsZh = $this->splitTags($data['tags_zh'] ?? ($data['tags_i18n']['zh-CN'] ?? ''));
        $tagsEn = $this->splitTags($data['tags_en'] ?? ($data['tags_i18n']['en'] ?? ''));

        $data['code'] = strtolower(trim((string) ($data['code'] ?? '')));
        $data['is_system'] = (int) ($data['is_system'] ?? 2) === 1 ? 1 : 2;
        $data['title_i18n'] = json_encode(['zh-CN' => $titleZh, 'en' => $titleEn], JSON_UNESCAPED_UNICODE);
        $data['description_i18n'] = json_encode(['zh-CN' => $descZh, 'en' => $descEn], JSON_UNESCAPED_UNICODE);
        $data['tags_i18n'] = json_encode(['zh-CN' => $tagsZh, 'en' => $tagsEn], JSON_UNESCAPED_UNICODE);
        $data['cover'] = trim((string) ($data['cover'] ?? $data['avatar'] ?? ''));
        $data['cover_dark'] = trim((string) ($data['cover_dark'] ?? $data['dark_avatar'] ?? ''));
        foreach (['allow_online', 'allow_local', 'allow_realtime', 'allow_voice', 'allow_user_prompt'] as $field) {
            $data[$field] = (int) ($data[$field] ?? 1) === 2 ? 2 : 1;
        }
        $runtime = trim((string) ($data['speech_runtime'] ?? 'online'));
        $data['speech_runtime'] = in_array($runtime, ['online', 'local', 'auto'], true) ? $runtime : 'online';
        foreach (['online_config_id', 'realtime_config_id', 'asr_config_id', 'tts_config_id', 'local_model_id', 'local_asr_id', 'local_tts_id', 'sort', 'status'] as $field) {
            $data[$field] = (int) ($data[$field] ?? 0);
        }
        $data['tts_voice'] = trim((string) ($data['tts_voice'] ?? ''));
        if ($data['status'] !== 2) {
            $data['status'] = 1;
        }
        if ((int) $data['allow_realtime'] === 1 && $data['realtime_config_id'] <= 0) {
            throw new ApiException('开放实时音视频时必须绑定 realtime 配置');
        }

        unset($data['title_zh'], $data['title_en'], $data['description_zh'], $data['description_en'], $data['tags_zh'], $data['tags_en'], $data['avatar'], $data['dark_avatar'], $data['display_name'], $data['display_name_en']);

        return $data;
    }

    private function assertUniqueCode(string $code, ?int $id = null): void
    {
        $query = Db::table('sa_ai_persona')->where('code', $code)->whereNull('delete_time');
        if ($id !== null && $id > 0) {
            $query->where('id', '<>', $id);
        }
        if ($query->find()) {
            throw new ApiException('角色编码已存在');
        }
    }

    /**
     * @return list<string>
     */
    private function splitTags(mixed $value): array
    {
        if (is_array($value)) {
            $items = $value;
        } else {
            $items = preg_split('/[,，]/', (string) $value) ?: [];
        }
        $result = [];
        foreach ($items as $item) {
            $text = trim((string) $item);
            if ($text !== '') {
                $result[] = $text;
            }
        }

        return array_values(array_unique($result));
    }
}
