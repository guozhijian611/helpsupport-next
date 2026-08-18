<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpTestflightDownloadLinks extends AbstractMigration
{
    private const GROUP_TABLE = 'sa_system_config_group';
    private const CONFIG_TABLE = 'sa_system_config';
    private const GROUP_CODE = 'help_app_download';
    private const REMARK = 'phinx:20260819020000_add_help_testflight_download_links';

    public function up(): void
    {
        $this->seedConfig();
        $this->clearCaches();
    }

    public function down(): void
    {
        if ($this->hasTable(self::CONFIG_TABLE) && $this->hasTable(self::GROUP_TABLE)) {
            $this->execute(
                'DELETE FROM `' . self::CONFIG_TABLE . '`
                 WHERE `remark` LIKE ' . $this->q(self::REMARK . ':%') . '
                   AND `group_id` IN (
                       SELECT `id` FROM `' . self::GROUP_TABLE . '`
                       WHERE `code` = ' . $this->q(self::GROUP_CODE) . '
                   )'
            );
        }
        $this->clearCaches();
    }

    private function seedConfig(): void
    {
        if (!$this->hasTable(self::GROUP_TABLE) || !$this->hasTable(self::CONFIG_TABLE)) {
            return;
        }

        $this->insertConfigItem(
            'testflight_public_url',
            'TestFlight 公共测试',
            '',
            'input',
            86,
            'iOS TestFlight 公共测试（外部测试）加入链接，通常为 https://testflight.apple.com/join/...'
        );
        $this->insertConfigItem(
            'testflight_internal_url',
            'TestFlight 内部测试',
            '',
            'input',
            85,
            'iOS TestFlight 内部测试加入链接，通常为 https://testflight.apple.com/join/...'
        );
    }

    private function insertConfigItem(
        string $key,
        string $name,
        string $value,
        string $inputType,
        int $sort,
        string $remark
    ): void {
        $this->execute(
            'INSERT INTO `' . self::CONFIG_TABLE . '` (`group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT `id`, ' . $this->q($key) . ', ' . $this->q($value) . ', ' . $this->q($name) . ', ' . $this->q($inputType) . ', NULL, ' . $sort . ', ' . $this->q(self::REMARK . ':' . $remark) . ', 1, 1, NOW(), NOW(), NULL
             FROM `' . self::GROUP_TABLE . '`
             WHERE `code` = ' . $this->q(self::GROUP_CODE) . '
               AND `delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `' . self::CONFIG_TABLE . '`
                   WHERE `group_id` = `' . self::GROUP_TABLE . '`.`id`
                     AND `key` = ' . $this->q($key) . '
                     AND `delete_time` IS NULL
               )
             LIMIT 1'
        );
    }

    private function clearCaches(): void
    {
        if (class_exists(\plugin\saiadmin\app\cache\ConfigCache::class)) {
            \plugin\saiadmin\app\cache\ConfigCache::clearConfig(self::GROUP_CODE);
        }
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
