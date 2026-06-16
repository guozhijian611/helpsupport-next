<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedHelpLocalModelSmollmQ2kTest extends AbstractMigration
{
    private const MODEL_CODE = 'smollm2-135m-instruct-q2-k';
    private const MODEL_URL = 'https://huggingface.co/unsloth/SmolLM2-135M-Instruct-GGUF/resolve/main/SmolLM2-135M-Instruct-Q2_K.gguf';
    private const MODEL_SHA256 = 'c53fe6626c7165ebfd8de5db22edc3f719b813da001e662bc5cb453f2540a076';

    public function up(): void
    {
        $introI18n = json_encode([
            'zh-CN' => '超小 GGUF 测试模型，优先用于验证设备是否能跑通本地 AI，不建议作为正式聊天模型。',
            'en-US' => 'An ultra-small GGUF model intended for device AI smoke tests, not for production-quality chat.',
        ], JSON_UNESCAPED_UNICODE);

        $this->execute(
            'INSERT INTO `sa_local_model_catalog` (`name`, `code`, `provider`, `model_family`, `quantization`, `file_size`, `download_url`, `sha256`, `intro`, `intro_i18n`, `license`, `min_memory_mb`, `context_size`, `default_temperature`, `default_top_p`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT ' . $this->q('SmolLM2 135M Instruct Q2_K') . ', ' . $this->q(self::MODEL_CODE) . ', ' . $this->q('Unsloth') . ', ' . $this->q('SmolLM2') . ', ' . $this->q('Q2_K') . ', 92484403, ' . $this->q(self::MODEL_URL) . ', ' . $this->q(self::MODEL_SHA256) . ', ' . $this->q('Ultra-small GGUF option for on-device AI smoke tests.') . ', ' . $this->q($introI18n ?: '{}') . ', ' . $this->q('apache-2.0') . ', 1024, 2048, 0.70, 0.90, 4, 1, 1, 1, NOW(), NOW(), NULL
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
