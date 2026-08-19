<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use plugin\saiadmin\exception\ApiException;
use think\facade\Db;
use Throwable;

/**
 * 互动角色目录。表存在时以后台角色为准，否则回退到内置四种模式。
 */
final class ChatPersonaCatalog
{
    public const SYSTEM_CODES = ['doctor', 'companion', 'patient', 'ai_doctor'];

    /**
     * @return list<string>
     */
    public static function enabledCodes(): array
    {
        $rows = self::enabledRows();
        if ($rows === []) {
            return self::SYSTEM_CODES;
        }

        return array_values(array_filter(array_map(
            static fn (array $row): string => trim((string) ($row['code'] ?? '')),
            $rows
        )));
    }

    public static function exists(string $code, bool $enabledOnly = true): bool
    {
        $code = trim($code);
        if ($code === '') {
            return false;
        }
        if (!self::tableExists()) {
            return in_array($code, self::SYSTEM_CODES, true);
        }

        $query = Db::table('sa_ai_persona')
            ->where('code', $code)
            ->whereNull('delete_time');
        if ($enabledOnly) {
            $query->where('status', 1);
        }

        return (bool) $query->find();
    }

    /**
     * @return array<string, mixed>
     */
    public static function find(string $code): array
    {
        $code = trim($code);
        if ($code === '' || !self::tableExists()) {
            return self::fallbackPersona($code !== '' ? $code : 'companion');
        }

        $row = Db::table('sa_ai_persona')
            ->where('code', $code)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->find();

        return $row ? self::normalize($row) : self::fallbackPersona($code);
    }

    /**
     * @return list<array<string, mixed>>
     */
    public static function enabledRows(): array
    {
        if (!self::tableExists()) {
            return array_map(static fn (string $code): array => self::fallbackPersona($code), self::SYSTEM_CODES);
        }

        $rows = Db::table('sa_ai_persona')
            ->where('status', 1)
            ->whereNull('delete_time')
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();

        return array_map(static fn (array $row): array => self::normalize($row), $rows);
    }

    public static function requireCode(mixed $value): string
    {
        $code = trim((string) $value);
        if (!self::exists($code)) {
            throw new ApiException('聊天角色不存在或未启用', 400);
        }

        return $code;
    }

    public static function speechConfigId(string $code, string $kind, int $fallbackId = 0): int
    {
        $persona = self::find($code);
        $field = $kind === 'tts' ? 'tts_config_id' : 'asr_config_id';
        $id = max(0, (int) ($persona[$field] ?? 0));

        return $id > 0 ? $id : max(0, $fallbackId);
    }

    public static function ttsVoice(string $code): string
    {
        return trim((string) (self::find($code)['tts_voice'] ?? ''));
    }

    public static function realtimeConfigId(string $code): int
    {
        return max(0, (int) (self::find($code)['realtime_config_id'] ?? 0));
    }

    public static function systemPrompt(string $code, string $locale, string $runtimeMode = 'online'): string
    {
        $persona = self::find($code);
        $personaId = (int) ($persona['id'] ?? 0);
        if ($personaId > 0 && self::promptTableExists()) {
            $row = Db::table('sa_ai_persona_prompt')
                ->where('persona_id', $personaId)
                ->where('runtime_mode', $runtimeMode)
                ->where('status', 1)
                ->whereNull('delete_time')
                ->whereIn('locale', array_values(array_unique([$locale, self::localeFamily($locale), 'zh-CN', 'en'])))
                ->order('id', 'asc')
                ->select()
                ->toArray();
            $matched = [];
            foreach ([$locale, self::localeFamily($locale), 'zh-CN', 'en'] as $candidate) {
                foreach ($row as $item) {
                    if ((string) ($item['locale'] ?? '') === $candidate) {
                        $matched = $item;
                        break 2;
                    }
                }
            }
            $row = $matched;
            $prompt = trim((string) ($row['system_prompt'] ?? ''));
            if ($prompt !== '') {
                return $prompt;
            }
        }

        return self::fallbackSystemPrompt($code);
    }

    /**
     * @return array<string, mixed>
     */
    public static function normalize(array $row): array
    {
        $code = trim((string) ($row['code'] ?? $row['chat_mode'] ?? 'companion'));
        $fallback = self::fallbackPersona($code);
        $title = self::decodeI18n($row['title_i18n'] ?? null, $fallback['title_i18n']);
        $description = self::decodeI18n($row['description_i18n'] ?? null, $fallback['description_i18n']);
        $tags = self::decodeI18nList($row['tags_i18n'] ?? null);

        return [
            'id' => (int) ($row['id'] ?? 0),
            'code' => $code,
            'chat_mode' => $code,
            'is_system' => (int) ($row['is_system'] ?? ($fallback['is_system'] ?? 2)),
            'title_i18n' => $title,
            'description_i18n' => $description,
            'tags_i18n' => $tags,
            'cover' => trim((string) ($row['cover'] ?? $row['avatar'] ?? '')),
            'cover_dark' => trim((string) ($row['cover_dark'] ?? $row['dark_avatar'] ?? '')),
            'icon' => self::normalizeIcon((string) ($row['icon'] ?? ''), $code),
            'allow_online' => self::flag($row['allow_online'] ?? $fallback['allow_online']),
            'allow_local' => self::flag($row['allow_local'] ?? $fallback['allow_local']),
            'allow_realtime' => self::flag($row['allow_realtime'] ?? $fallback['allow_realtime']),
            'allow_voice' => self::flag($row['allow_voice'] ?? $fallback['allow_voice']),
            'allow_user_prompt' => self::flag($row['allow_user_prompt'] ?? $fallback['allow_user_prompt']),
            'speech_runtime' => self::speechRuntime($row['speech_runtime'] ?? 'online'),
            'online_config_id' => max(0, (int) ($row['online_config_id'] ?? 0)),
            'realtime_config_id' => max(0, (int) ($row['realtime_config_id'] ?? 0)),
            'asr_config_id' => max(0, (int) ($row['asr_config_id'] ?? 0)),
            'tts_config_id' => max(0, (int) ($row['tts_config_id'] ?? 0)),
            'tts_voice' => trim((string) ($row['tts_voice'] ?? '')),
            'local_model_id' => max(0, (int) ($row['local_model_id'] ?? 0)),
            'local_asr_id' => max(0, (int) ($row['local_asr_id'] ?? 0)),
            'local_tts_id' => max(0, (int) ($row['local_tts_id'] ?? 0)),
            'sort' => (int) ($row['sort'] ?? 100),
            'status' => (int) ($row['status'] ?? 1),
            'display_name' => (string) ($title['zh-CN'] ?? $fallback['title_i18n']['zh-CN']),
            'display_name_en' => (string) ($title['en'] ?? $fallback['title_i18n']['en']),
            'description' => (string) ($description['zh-CN'] ?? $fallback['description_i18n']['zh-CN']),
            'description_en' => (string) ($description['en'] ?? $fallback['description_i18n']['en']),
            'avatar' => trim((string) ($row['cover'] ?? $row['avatar'] ?? '')),
            'dark_avatar' => trim((string) ($row['cover_dark'] ?? $row['dark_avatar'] ?? '')),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public static function fallbackPersona(string $code): array
    {
        $code = in_array($code, self::SYSTEM_CODES, true) ? $code : 'companion';
        $titles = [
            'doctor' => ['zh-CN' => 'AI 心理医生', 'en' => 'AI doctor'],
            'companion' => ['zh-CN' => 'AI 心理陪伴', 'en' => 'AI companion'],
            'patient' => ['zh-CN' => 'AI 模拟病人', 'en' => 'AI patient'],
            'ai_doctor' => ['zh-CN' => 'AI 医生', 'en' => 'AI clinician'],
        ];
        $descriptions = [
            'doctor' => ['zh-CN' => '谨慎、温和的心理支持助手', 'en' => 'Careful and gentle mental health support'],
            'companion' => ['zh-CN' => '稳定、耐心的陪伴式支持助手', 'en' => 'Steady and patient companion support'],
            'patient' => ['zh-CN' => '用于角色演练和沟通练习的模拟病人', 'en' => 'A simulated patient for role-play and communication practice'],
            'ai_doctor' => ['zh-CN' => '帮助整理健康问题、症状和就诊准备的 AI 助手', 'en' => 'An AI assistant for organizing health concerns, symptoms, and visit preparation'],
        ];

        return [
            'id' => 0,
            'code' => $code,
            'chat_mode' => $code,
            'is_system' => 1,
            'title_i18n' => $titles[$code],
            'description_i18n' => $descriptions[$code],
            'tags_i18n' => ['zh-CN' => [], 'en' => []],
            'cover' => '',
            'cover_dark' => '',
            'icon' => self::defaultIcon($code),
            'allow_online' => 1,
            'allow_local' => $code === 'doctor' ? 2 : 1,
            'allow_realtime' => $code === 'doctor' ? 1 : 2,
            'allow_voice' => 1,
            'allow_user_prompt' => $code === 'doctor' ? 2 : 1,
            'speech_runtime' => 'online',
            'online_config_id' => 0,
            'realtime_config_id' => 0,
            'asr_config_id' => 0,
            'tts_config_id' => 0,
            'tts_voice' => '',
            'local_model_id' => 0,
            'local_asr_id' => 0,
            'local_tts_id' => 0,
            'sort' => 100,
            'status' => 1,
            'display_name' => $titles[$code]['zh-CN'],
            'display_name_en' => $titles[$code]['en'],
            'description' => $descriptions[$code]['zh-CN'],
            'description_en' => $descriptions[$code]['en'],
            'avatar' => '',
            'dark_avatar' => '',
        ];
    }

    public static function fallbackSystemPrompt(string $code): string
    {
        return match ($code) {
            'doctor' => '你是一位谨慎、温和的 AI 心理医生助手。请优先安抚情绪、澄清问题、给出可执行建议。你不能冒充真实执业诊断，不要给出绝对化结论。如用户出现自伤、自杀、伤人、幻觉、失控等高风险信号，必须明确建议立刻联系家属、当地急救电话或尽快前往线下精神心理专科就医。',
            'patient' => '你是一位帮助用户整理病情和感受的 AI 助手。请帮助用户梳理症状、情绪、诱因和需要补充给医生的信息。',
            'ai_doctor' => '你是一位谨慎的 AI 健康信息助手。请帮助用户整理症状、持续时间、诱因、用药情况和需要向医生询问的问题，并提供可靠的健康常识。你不能做诊断、开药、调整处方或替代真实医生。如出现呼吸困难、胸痛、意识异常、大量出血、自伤风险或其他紧急情况，必须明确建议立即联系当地急救服务并尽快线下就医。',
            default => '你是一位温柔、稳定、耐心的 AI 心理陪伴助手。请多倾听、多共情，避免说教，并帮助用户把当下感受表达清楚。',
        };
    }

    /**
     * @return array<string, string>
     */
    public static function defaultIcon(string $code): string
    {
        return match ($code) {
            'doctor' => 'smart_toy_rounded',
            'ai_doctor' => 'medical_services_rounded',
            'patient' => 'healing_rounded',
            default => 'volunteer_activism_rounded',
        };
    }

    /**
     * @return list<string>
     */
    public static function allowedIcons(): array
    {
        return [
            'smart_toy_rounded',
            'psychology_rounded',
            'self_improvement_rounded',
            'spa_rounded',
            'volunteer_activism_rounded',
            'favorite_rounded',
            'mood_rounded',
            'sentiment_satisfied_alt_rounded',
            'support_agent_rounded',
            'chat_rounded',
            'forum_rounded',
            'record_voice_over_rounded',
            'medical_services_rounded',
            'local_hospital_rounded',
            'healing_rounded',
            'health_and_safety_rounded',
            'monitor_heart_rounded',
            'medication_rounded',
            'emergency_rounded',
            'bloodtype_rounded',
            'accessibility_new_rounded',
            'elderly_rounded',
            'child_care_rounded',
            'family_restroom_rounded',
            'groups_rounded',
            'handshake_rounded',
            'person_rounded',
            'face_rounded',
            'nightlight_rounded',
            'wb_sunny_rounded',
            'park_rounded',
            'eco_rounded',
            'water_drop_rounded',
            'coffee_rounded',
            'music_note_rounded',
            'auto_awesome_rounded',
            'lightbulb_rounded',
            'menu_book_rounded',
            'school_rounded',
            'assignment_rounded',
            'checklist_rounded',
            'flag_rounded',
            'balance_rounded',
            'privacy_tip_rounded',
            'shield_rounded',
            'home_rounded',
            'pets_rounded',
            'sports_esports_rounded',
            'palette_rounded',
        ];
    }

    public static function normalizeIcon(string $icon, string $code = ''): string
    {
        $icon = strtolower(trim($icon));
        if ($icon !== '' && in_array($icon, self::allowedIcons(), true)) {
            return $icon;
        }

        return self::defaultIcon($code);
    }

    private static function decodeI18n(mixed $value, array $fallback): array
    {
        $decoded = self::decodeJson($value);
        $result = $fallback;
        foreach (['zh-CN', 'en', 'en-US'] as $locale) {
            $text = trim((string) ($decoded[$locale] ?? ''));
            if ($text !== '') {
                $result[$locale === 'en-US' ? 'en' : $locale] = $text;
            }
        }

        return $result;
    }

    /**
     * @return array<string, list<string>>
     */
    private static function decodeI18nList(mixed $value): array
    {
        $decoded = self::decodeJson($value);

        return [
            'zh-CN' => self::stringList($decoded['zh-CN'] ?? []),
            'en' => self::stringList($decoded['en'] ?? $decoded['en-US'] ?? []),
        ];
    }

    /**
     * @return list<string>
     */
    private static function stringList(mixed $value): array
    {
        if (is_string($value)) {
            $value = preg_split('/[,，]/', $value) ?: [];
        }
        if (!is_array($value)) {
            return [];
        }

        $items = [];
        foreach ($value as $item) {
            $text = trim((string) $item);
            if ($text !== '') {
                $items[] = $text;
            }
        }

        return array_values(array_unique($items));
    }

    /**
     * @return array<string, mixed>
     */
    private static function decodeJson(mixed $value): array
    {
        if (is_array($value)) {
            return $value;
        }
        if (!is_string($value) || trim($value) === '') {
            return [];
        }
        $decoded = json_decode($value, true);

        return is_array($decoded) ? $decoded : [];
    }

    private static function flag(mixed $value): int
    {
        return (int) $value === 2 ? 2 : 1;
    }

    private static function speechRuntime(mixed $value): string
    {
        $value = trim((string) $value);

        return in_array($value, ['online', 'local', 'auto'], true) ? $value : 'online';
    }

    private static function localeFamily(string $locale): string
    {
        $locale = strtolower(str_replace('_', '-', trim($locale)));
        if (str_starts_with($locale, 'zh')) {
            return 'zh-CN';
        }

        return 'en';
    }

    private static function tableExists(): bool
    {
        return self::hasTable('sa_ai_persona');
    }

    private static function promptTableExists(): bool
    {
        return self::hasTable('sa_ai_persona_prompt');
    }

    private static function hasTable(string $table): bool
    {
        static $cache = [];
        if (array_key_exists($table, $cache)) {
            return $cache[$table];
        }
        if (!preg_match('/^[a-zA-Z0-9_]+$/', $table)) {
            $cache[$table] = false;
            return false;
        }
        try {
            $cache[$table] = Db::query("SHOW TABLES LIKE '{$table}'") !== [];
        } catch (Throwable) {
            $cache[$table] = false;
        }

        return $cache[$table];
    }
}
