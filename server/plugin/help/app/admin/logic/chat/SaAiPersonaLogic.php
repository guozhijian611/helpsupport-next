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

        return Db::table('sa_ai_persona')->insertGetId($this->persistPayload($data, true));
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

        Db::table('sa_ai_persona')
            ->where('id', (int) $id)
            ->whereNull('delete_time')
            ->update($this->persistPayload($data, false));

        return true;
    }

    public function destroy($ids): bool
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
        $tagsZh = $this->splitTags($data['tags_zh'] ?? $this->i18nList($data['tags_i18n'] ?? null, 'zh-CN'));
        $tagsEn = $this->splitTags($data['tags_en'] ?? $this->i18nList($data['tags_i18n'] ?? null, 'en'));

        $data['code'] = strtolower(trim((string) ($data['code'] ?? '')));
        $data['is_system'] = (int) ($data['is_system'] ?? 2) === 1 ? 1 : 2;
        $data['title_i18n'] = ['zh-CN' => $titleZh, 'en' => $titleEn];
        $data['description_i18n'] = ['zh-CN' => $descZh, 'en' => $descEn];
        $data['tags_i18n'] = ['zh-CN' => $tagsZh, 'en' => $tagsEn];
        $data['cover'] = trim((string) ($data['cover'] ?? $data['avatar'] ?? ''));
        $data['cover_dark'] = trim((string) ($data['cover_dark'] ?? $data['dark_avatar'] ?? ''));
        $data['icon'] = ChatPersonaCatalog::normalizeIcon((string) ($data['icon'] ?? ''), $data['code']);
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

        unset(
            $data['id'],
            $data['title_zh'],
            $data['title_en'],
            $data['description_zh'],
            $data['description_en'],
            $data['tags_zh'],
            $data['tags_en'],
            $data['avatar'],
            $data['dark_avatar'],
            $data['display_name'],
            $data['display_name_en'],
            $data['chat_mode'],
            $data['description']
        );

        return $data;
    }

    /**
     * @return array<string, mixed>
     */
    private function persistPayload(array $data, bool $creating): array
    {
        $now = date('Y-m-d H:i:s');
        $userId = (int) ((getCurrentInfo() ?: [])['id'] ?? 0);
        $payload = [
            'code' => (string) ($data['code'] ?? ''),
            'is_system' => (int) ($data['is_system'] ?? 2),
            'title_i18n' => $this->jsonColumn($data['title_i18n'] ?? ['zh-CN' => '', 'en' => '']),
            'description_i18n' => $this->jsonColumn($data['description_i18n'] ?? ['zh-CN' => '', 'en' => '']),
            'tags_i18n' => $this->jsonColumn($data['tags_i18n'] ?? ['zh-CN' => [], 'en' => []]),
            'cover' => (string) ($data['cover'] ?? ''),
            'cover_dark' => (string) ($data['cover_dark'] ?? ''),
            'icon' => (string) ($data['icon'] ?? ''),
            'allow_online' => (int) ($data['allow_online'] ?? 1),
            'allow_local' => (int) ($data['allow_local'] ?? 1),
            'allow_realtime' => (int) ($data['allow_realtime'] ?? 2),
            'allow_voice' => (int) ($data['allow_voice'] ?? 1),
            'allow_user_prompt' => (int) ($data['allow_user_prompt'] ?? 1),
            'speech_runtime' => (string) ($data['speech_runtime'] ?? 'online'),
            'online_config_id' => (int) ($data['online_config_id'] ?? 0),
            'realtime_config_id' => (int) ($data['realtime_config_id'] ?? 0),
            'asr_config_id' => (int) ($data['asr_config_id'] ?? 0),
            'tts_config_id' => (int) ($data['tts_config_id'] ?? 0),
            'tts_voice' => (string) ($data['tts_voice'] ?? ''),
            'local_model_id' => (int) ($data['local_model_id'] ?? 0),
            'local_asr_id' => (int) ($data['local_asr_id'] ?? 0),
            'local_tts_id' => (int) ($data['local_tts_id'] ?? 0),
            'sort' => (int) ($data['sort'] ?? 100),
            'status' => (int) ($data['status'] ?? 1),
            'updated_by' => $userId,
            'update_time' => $now,
        ];
        if ($creating) {
            $payload['created_by'] = $userId;
            $payload['create_time'] = $now;
        }

        return $payload;
    }

    private function jsonColumn(mixed $value): string
    {
        if (is_string($value)) {
            $value = trim($value);
            if ($value === '') {
                $value = [];
            } else {
                $decoded = json_decode($value, true);
                $value = json_last_error() === JSON_ERROR_NONE ? $decoded : [];
            }
        }
        if (!is_array($value)) {
            $value = [];
        }

        return json_encode($value, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
    }

    private function i18nList(mixed $value, string $locale): mixed
    {
        if (is_string($value) && $value !== '') {
            $decoded = json_decode($value, true);
            $value = json_last_error() === JSON_ERROR_NONE ? $decoded : [];
        }
        if (!is_array($value)) {
            return [];
        }

        return $value[$locale] ?? [];
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
