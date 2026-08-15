<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use plugin\saiadmin\app\cache\ConfigCache;

/**
 * AI 内容审核运行策略。
 */
class HelpAiAuditConfigService
{
    public const GROUP_CODE = 'help_ai_audit';

    public function all(): array
    {
        $config = ConfigCache::getConfig(self::GROUP_CODE, true);

        return [
            'enabled' => (int) ($config['enabled'] ?? 2) === 1,
            'ai_config_id' => max(0, (int) ($config['ai_config_id'] ?? 0)),
            'audit_posts' => (int) ($config['audit_posts'] ?? 1) === 1,
            'audit_comments' => (int) ($config['audit_comments'] ?? 1) === 1,
            'auto_pass_enabled' => (int) ($config['auto_pass_enabled'] ?? 1) === 1,
            'auto_pass_confidence' => $this->floatIn($config['auto_pass_confidence'] ?? 0.95, 0.50, 1.00, 0.95),
            'auto_reject_enabled' => (int) ($config['auto_reject_enabled'] ?? 2) === 1,
            'auto_reject_confidence' => $this->floatIn($config['auto_reject_confidence'] ?? 0.99, 0.80, 1.00, 0.99),
            'max_attempts' => max(1, min(5, (int) ($config['max_attempts'] ?? 3))),
            'retry_delay_seconds' => max(1, min(300, (int) ($config['retry_delay_seconds'] ?? 10))),
            'prompt_policy' => mb_substr(trim((string) ($config['prompt_policy'] ?? '')), 0, 3000),
        ];
    }

    public function enabledFor(string $targetType): bool
    {
        $config = $this->all();
        if (!$config['enabled'] || $config['ai_config_id'] <= 0) {
            return false;
        }

        return match ($targetType) {
            'community_post' => $config['audit_posts'],
            'community_comment' => $config['audit_comments'],
            default => false,
        };
    }

    private function floatIn(mixed $value, float $min, float $max, float $default): float
    {
        if (!is_numeric($value)) {
            return $default;
        }

        return max($min, min($max, (float) $value));
    }
}
