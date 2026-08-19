<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

/**
 * 种子各一个低内存端侧 ASR / TTS，并挂到互动角色。
 */
final class SeedOndeviceSpeechModels extends AbstractMigration
{
    private const ASR_CODE = 'ondevice-asr';
    private const TTS_CODE = 'ondevice-tts';

    public function up(): void
    {
        $this->seedSpeechModel(
            self::ASR_CODE,
            '系统端侧语音识别',
            'On-device speech recognition',
            'asr',
            'System ASR',
            'Apple Speech / Android SpeechRecognizer',
            '系统自带中英识别，不额外下载模型，内存占用最低。',
            'Uses the system speech recognizer. No extra model download, lowest memory.',
            64,
            20
        );
        $this->seedSpeechModel(
            self::TTS_CODE,
            '系统端侧语音合成',
            'On-device speech synthesis',
            'tts',
            'System TTS',
            'AVSpeech / Android TextToSpeech',
            '系统自带中英播报，不额外下载模型，内存占用最低。',
            'Uses the system speech synthesizer. No extra model download, lowest memory.',
            32,
            21
        );
        $this->bindPersonas();
    }

    public function down(): void
    {
        if ($this->hasTable('sa_ai_persona')) {
            $this->execute(
                'UPDATE `sa_ai_persona` p
                 LEFT JOIN `sa_local_model_catalog` asr
                        ON asr.`id` = p.`local_asr_id`
                       AND asr.`code` = ' . $this->q(self::ASR_CODE) . '
                 LEFT JOIN `sa_local_model_catalog` tts
                        ON tts.`id` = p.`local_tts_id`
                       AND tts.`code` = ' . $this->q(self::TTS_CODE) . '
                 SET p.`local_asr_id` = IF(asr.`id` IS NULL, p.`local_asr_id`, 0),
                     p.`local_tts_id` = IF(tts.`id` IS NULL, p.`local_tts_id`, 0),
                     p.`speech_runtime` = IF(p.`speech_runtime` = ' . $this->q('auto') . ', ' . $this->q('online') . ', p.`speech_runtime`)
                 WHERE p.`delete_time` IS NULL'
            );
        }

        $this->execute(
            'DELETE FROM `sa_local_model_catalog`
             WHERE `code` IN (' . $this->q(self::ASR_CODE) . ', ' . $this->q(self::TTS_CODE) . ')
               AND `download_url` = ' . $this->q('') . '
               AND `file_size` = 0'
        );
    }

    private function seedSpeechModel(
        string $code,
        string $nameZh,
        string $nameEn,
        string $capability,
        string $provider,
        string $family,
        string $introZh,
        string $introEn,
        int $minMemoryMb,
        int $sort
    ): void {
        if (!$this->hasTable('sa_local_model_catalog')) {
            return;
        }

        $introI18n = json_encode([
            'zh' => $introZh,
            'en-US' => $introEn,
        ], JSON_UNESCAPED_UNICODE) ?: '{}';

        $columns = '`name`, `code`, `provider`, `model_family`, `quantization`, `file_size`, `download_url`, `sha256`, `intro`, `intro_i18n`, `license`, `min_memory_mb`, `context_size`, `default_temperature`, `default_top_p`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`';
        $capabilitySelect = '';
        $capabilityColumn = '';
        if ($this->table('sa_local_model_catalog')->hasColumn('capability')) {
            $capabilityColumn = ', `capability`';
            $capabilitySelect = ', ' . $this->q($capability);
        }

        $this->execute(
            'INSERT INTO `sa_local_model_catalog` (' . $columns . $capabilityColumn . ')
             SELECT ' . $this->q($nameZh) . ', ' . $this->q($code) . ', ' . $this->q($provider) . ', ' . $this->q($family) . ', ' . $this->q('system') . ', 0, ' . $this->q('') . ', ' . $this->q('') . ', ' . $this->q($introZh) . ', ' . $this->q($introI18n) . ', ' . $this->q('system') . ', ' . $minMemoryMb . ', 0, 0, 0, ' . $sort . ', 1, 1, 1, NOW(), NOW(), NULL' . $capabilitySelect . '
             WHERE NOT EXISTS (
                 SELECT 1 FROM `sa_local_model_catalog`
                 WHERE `code` = ' . $this->q($code) . '
                   AND `delete_time` IS NULL
             )'
        );
    }

    private function bindPersonas(): void
    {
        if (!$this->hasTable('sa_ai_persona') || !$this->hasTable('sa_local_model_catalog')) {
            return;
        }

        $this->execute(
            'UPDATE `sa_ai_persona` p
             LEFT JOIN `sa_local_model_catalog` asr
                    ON asr.`code` = ' . $this->q(self::ASR_CODE) . '
                   AND asr.`delete_time` IS NULL
             LEFT JOIN `sa_local_model_catalog` tts
                    ON tts.`code` = ' . $this->q(self::TTS_CODE) . '
                   AND tts.`delete_time` IS NULL
             SET p.`local_asr_id` = IF(p.`local_asr_id` > 0, p.`local_asr_id`, IFNULL(asr.`id`, 0)),
                 p.`local_tts_id` = IF(p.`local_tts_id` > 0, p.`local_tts_id`, IFNULL(tts.`id`, 0)),
                 p.`speech_runtime` = ' . $this->q('auto') . ',
                 p.`update_time` = NOW()
             WHERE p.`delete_time` IS NULL'
        );

        if ($this->hasTable('saiai_config')) {
            $this->execute(
                'UPDATE `sa_ai_persona`
                 SET `realtime_config_id` = IFNULL((
                     SELECT `id` FROM (
                         SELECT `id` FROM `saiai_config`
                         WHERE `type` = ' . $this->q('realtime') . '
                           AND `status` = 1
                           AND `delete_time` IS NULL
                         ORDER BY `id` ASC
                         LIMIT 1
                     ) AS `realtime_source`
                 ), `realtime_config_id`),
                     `update_time` = NOW()
                 WHERE `code` = ' . $this->q('doctor') . '
                   AND `allow_realtime` = 1
                   AND `realtime_config_id` = 0
                   AND `delete_time` IS NULL'
            );
        }
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
