<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpOauthRuntimeStrategies extends AbstractMigration
{
    private const REMARK = 'phinx:20260615070000_add_help_oauth_runtime_strategies';
    private const DEFAULT_CALLBACK_STRATEGY = 'id_token';
    private const DEFAULT_BINDING_STRATEGY = 'verified_email_or_create';

    public function up(): void
    {
        foreach (['help_google_oauth', 'help_apple_oauth'] as $groupCode) {
            $this->insertConfigItem(
                $groupCode,
                'callback_strategy',
                '回调策略',
                self::DEFAULT_CALLBACK_STRATEGY,
                'select',
                65,
                'Flutter 默认提交 ID Token，服务端直接校验第三方签名和 aud。',
                [
                    ['label' => 'ID Token 直连', 'value' => 'id_token'],
                ]
            );
            $this->insertConfigItem(
                $groupCode,
                'binding_strategy',
                '绑定策略',
                self::DEFAULT_BINDING_STRATEGY,
                'select',
                55,
                '控制第三方账号首次登录时是否按已验证邮箱绑定现有会员。',
                [
                    ['label' => '已验证邮箱优先绑定，否则新建账号', 'value' => 'verified_email_or_create'],
                    ['label' => '始终按第三方身份新建或复用账号', 'value' => 'create_new'],
                    ['label' => '仅允许绑定已验证邮箱账号', 'value' => 'verified_email_only'],
                ]
            );
        }
    }

    public function down(): void
    {
        foreach ([
            'callback_strategy' => self::DEFAULT_CALLBACK_STRATEGY,
            'binding_strategy' => self::DEFAULT_BINDING_STRATEGY,
        ] as $key => $defaultValue) {
            $this->execute(
                'DELETE FROM `sa_system_config`
                 WHERE `key` = ' . $this->q($key) . '
                   AND `value` = ' . $this->q($defaultValue) . '
                   AND `remark` LIKE ' . $this->q(self::REMARK . ':%') . '
                   AND `group_id` IN (
                       SELECT `id` FROM `sa_system_config_group`
                       WHERE `code` IN (' . $this->q('help_google_oauth') . ', ' . $this->q('help_apple_oauth') . ')
                         AND `delete_time` IS NULL
                   )'
            );
        }
    }

    /**
     * @param array<int, array{label: string, value: string}> $options
     */
    private function insertConfigItem(
        string $groupCode,
        string $key,
        string $name,
        string $value,
        string $inputType,
        int $sort,
        string $remark,
        array $options
    ): void {
        $this->execute(
            'INSERT INTO `sa_system_config` (`group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT `id`, ' . $this->q($key) . ', ' . $this->q($value) . ', ' . $this->q($name) . ', ' . $this->q($inputType) . ', ' . $this->q($this->json($options)) . ', ' . $sort . ', ' . $this->q(self::REMARK . ':' . $remark) . ', 1, 1, NOW(), NOW(), NULL
             FROM `sa_system_config_group`
             WHERE `code` = ' . $this->q($groupCode) . '
               AND `delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_system_config`
                   WHERE `group_id` = `sa_system_config_group`.`id`
                     AND `key` = ' . $this->q($key) . '
                     AND `delete_time` IS NULL
               )
             LIMIT 1'
        );
    }

    /**
     * @param array<int, array{label: string, value: string}> $value
     */
    private function json(array $value): string
    {
        return json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?: '[]';
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
