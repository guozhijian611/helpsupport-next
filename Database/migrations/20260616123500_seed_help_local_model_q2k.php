<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedHelpLocalModelQ2k extends AbstractMigration
{
    private const MODEL_CODE = 'qwen2.5-0.5b-instruct-q2-k';
    private const MODEL_URL = 'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/9217f5db79a29953eb74d5343926648285ec7e67/qwen2.5-0.5b-instruct-q2_k.gguf';
    private const MODEL_SHA256 = '9ee36184e616dfc76df4f5dd66f908dbde6979524ae36e6cefb67f532f798cb8';

    public function up(): void
    {
        $introI18n = json_encode([
            'zh-CN' => '当前最小的验证用 GGUF，适合先测试设备能否跑通本地 AI。',
            'en-US' => 'The smallest verified GGUF option for quick on-device AI smoke tests.',
        ], JSON_UNESCAPED_UNICODE);

        $this->execute(
            'INSERT INTO `sa_local_model_catalog` (`name`, `code`, `provider`, `model_family`, `quantization`, `file_size`, `download_url`, `sha256`, `intro`, `intro_i18n`, `license`, `min_memory_mb`, `context_size`, `default_temperature`, `default_top_p`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT ' . $this->q('Qwen2.5 0.5B Instruct Q2_K') . ', ' . $this->q(self::MODEL_CODE) . ', ' . $this->q('Qwen') . ', ' . $this->q('Qwen2.5') . ', ' . $this->q('Q2_K') . ', 415182688, ' . $this->q(self::MODEL_URL) . ', ' . $this->q(self::MODEL_SHA256) . ', ' . $this->q('Smallest verified GGUF option for quick device AI smoke tests.') . ', ' . $this->q($introI18n ?: '{}') . ', ' . $this->q('apache-2.0') . ', 1536, 2048, 0.70, 0.90, 5, 1, 1, 1, NOW(), NOW(), NULL
            WHERE NOT EXISTS (
                SELECT 1 FROM `sa_local_model_catalog`
                WHERE `code` = ' . $this->q(self::MODEL_CODE) . '
                  AND `delete_time` IS NULL
            )'
        );
    }

    public function down(): void
    {
        $this->execute(
            'DELETE FROM `sa_local_model_catalog`
            WHERE `code` = ' . $this->q(self::MODEL_CODE) . '
              AND `download_url` = ' . $this->q(self::MODEL_URL) . '
              AND `sha256` = ' . $this->q(self::MODEL_SHA256)
        );
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
