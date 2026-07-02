<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpAppDownloadConfig extends AbstractMigration
{
    private const GROUP_TABLE = 'sa_system_config_group';
    private const CONFIG_TABLE = 'sa_system_config';
    private const MENU_TABLE = 'sa_system_menu';
    private const ROLE_TABLE = 'sa_system_role';
    private const ROLE_MENU_TABLE = 'sa_system_role_menu';
    private const GROUP_CODE = 'help_app_download';
    private const MENU_CODE = 'help/config/download';
    private const OPERATOR_ROLE_CODE = 'helpsupport_operator';
    private const REMARK = 'phinx:20260702170000_add_help_app_download_config';

    public function up(): void
    {
        $this->seedConfig();
        $this->insertMenu();
        foreach ($this->permissions() as $permission) {
            $this->insertPermission($permission);
        }
        $this->appendUploadExtension('apk');
        $this->appendUploadExtension('ipa');
        $this->grantExistingConfigRoles();
        $this->grantOperatorRoleMenus();
        $this->clearCaches();
    }

    public function down(): void
    {
        $this->execute(
            'DELETE rm FROM `' . self::ROLE_MENU_TABLE . '` rm
             INNER JOIN `' . self::MENU_TABLE . '` m ON m.`id` = rm.`menu_id`
             WHERE m.`remark` = ' . $this->q(self::REMARK)
        );
        $this->execute('DELETE FROM `' . self::MENU_TABLE . '` WHERE `remark` = ' . $this->q(self::REMARK));
        $this->execute(
            'DELETE FROM `' . self::CONFIG_TABLE . '`
             WHERE `remark` LIKE ' . $this->q(self::REMARK . ':%') . '
               AND `group_id` IN (
                   SELECT `id` FROM `' . self::GROUP_TABLE . '`
                   WHERE `code` = ' . $this->q(self::GROUP_CODE) . '
               )'
        );
        $this->execute(
            'DELETE FROM `' . self::GROUP_TABLE . '`
             WHERE `code` = ' . $this->q(self::GROUP_CODE) . '
               AND `remark` LIKE ' . $this->q(self::REMARK . ':%') . '
               AND NOT EXISTS (
                   SELECT 1 FROM `' . self::CONFIG_TABLE . '`
                   WHERE `' . self::CONFIG_TABLE . '`.`group_id` = `' . self::GROUP_TABLE . '`.`id`
               )'
        );

        // 不回滚 upload_allow_file 中追加的 apk/ipa，避免误删用户已依赖的上传类型。
        $this->clearCaches();
    }

    private function seedConfig(): void
    {
        if (!$this->hasTable(self::GROUP_TABLE) || !$this->hasTable(self::CONFIG_TABLE)) {
            return;
        }

        $this->insertConfigGroup(
            self::GROUP_CODE,
            'App 下载配置',
            'HelpSupport App 商店链接与开发版安装包下载配置。'
        );

        $this->insertConfigItem(
            'google_play_url',
            'Google Play 链接',
            '',
            'input',
            100,
            '用于展示 Android 正式版 Google Play 商店下载地址。'
        );
        $this->insertConfigItem(
            'app_store_url',
            'App Store 链接',
            '',
            'input',
            90,
            '用于展示 iOS 正式版 App Store 商店下载地址。'
        );
        $this->insertConfigItem(
            'dev_apk_url',
            '开发版 APK',
            '',
            'uploadFile',
            80,
            '开发版 Android APK 安装包下载链接，可在后台上传后自动填入。'
        );
        $this->insertConfigItem(
            'dev_ipa_url',
            '开发版 IPA',
            '',
            'uploadFile',
            70,
            '开发版 iOS IPA 安装包下载链接，可在后台上传后自动填入。'
        );
    }

    private function insertConfigGroup(string $code, string $name, string $remark): void
    {
        $this->execute(
            'INSERT INTO `' . self::GROUP_TABLE . '` (`name`, `code`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT ' . $this->q($name) . ', ' . $this->q($code) . ', ' . $this->q(self::REMARK . ':' . $remark) . ', 1, 1, NOW(), NOW(), NULL
             WHERE NOT EXISTS (
                 SELECT 1 FROM `' . self::GROUP_TABLE . '`
                 WHERE `code` = ' . $this->q($code) . '
                   AND `delete_time` IS NULL
             )'
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

    private function insertMenu(): void
    {
        if (!$this->hasTable(self::MENU_TABLE)) {
            return;
        }

        $this->execute(
            'INSERT INTO `' . self::MENU_TABLE . '` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT COALESCE(config_parent.`id`, root.`id`), ' . $this->q('App下载配置') . ', ' . $this->q(self::MENU_CODE) . ', NULL, 2,
                    CASE WHEN config_parent.`id` IS NULL THEN ' . $this->q('config/download') . ' ELSE ' . $this->q('/helpsupport/config/download') . ' END,
                    ' . $this->q('/plugin/help/config/download/index') . ', NULL, ' . $this->q('ri:download-cloud-2-line') . ', 30, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, NULL, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             FROM (SELECT 1) seed
             LEFT JOIN `' . self::MENU_TABLE . '` config_parent ON config_parent.`code` = ' . $this->q('help/config') . ' AND config_parent.`delete_time` IS NULL
             LEFT JOIN `' . self::MENU_TABLE . '` root ON root.`code` = ' . $this->q('HelpSupport') . ' AND root.`delete_time` IS NULL
             WHERE COALESCE(config_parent.`id`, root.`id`) IS NOT NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `' . self::MENU_TABLE . '`
                   WHERE `code` = ' . $this->q(self::MENU_CODE) . '
                     AND `delete_time` IS NULL
               )
             LIMIT 1'
        );
    }

    private function permissions(): array
    {
        return [
            ['name' => '读取', 'slug' => 'help:config:download:read', 'generate_key' => 'read'],
            ['name' => '更新', 'slug' => 'help:config:download:update', 'generate_key' => 'update'],
        ];
    }

    private function insertPermission(array $permission): void
    {
        $this->execute(
            'INSERT INTO `' . self::MENU_TABLE . '` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT `id`, ' . $this->q($permission['name']) . ', ' . $this->q('') . ', ' . $this->q($permission['slug']) . ', 3, ' . $this->q('') . ', ' . $this->q('') . ', NULL, ' . $this->q('') . ', 100, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, ' . $this->q($permission['generate_key']) . ', 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             FROM `' . self::MENU_TABLE . '`
             WHERE `code` = ' . $this->q(self::MENU_CODE) . '
               AND `delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `' . self::MENU_TABLE . '`
                   WHERE `slug` = ' . $this->q($permission['slug']) . '
                     AND `delete_time` IS NULL
               )
             LIMIT 1'
        );
    }

    private function appendUploadExtension(string $extension): void
    {
        if (!$this->hasTable(self::GROUP_TABLE) || !$this->hasTable(self::CONFIG_TABLE)) {
            return;
        }

        $this->execute(
            'UPDATE `' . self::CONFIG_TABLE . '` c
             INNER JOIN `' . self::GROUP_TABLE . '` g ON g.`id` = c.`group_id` AND g.`code` = ' . $this->q('upload_config') . ' AND g.`delete_time` IS NULL
             SET c.`value` = CASE
                 WHEN c.`value` IS NULL OR TRIM(BOTH ' . $this->q(',') . ' FROM c.`value`) = ' . $this->q('') . ' THEN ' . $this->q($extension) . '
                 ELSE CONCAT(TRIM(BOTH ' . $this->q(',') . ' FROM c.`value`), ' . $this->q(',' . $extension) . ')
             END,
                 c.`update_time` = NOW()
             WHERE c.`key` = ' . $this->q('upload_allow_file') . '
               AND c.`delete_time` IS NULL
               AND FIND_IN_SET(' . $this->q($extension) . ', c.`value`) = 0'
        );
    }

    private function grantExistingConfigRoles(): void
    {
        $this->execute(
            'INSERT INTO `' . self::ROLE_MENU_TABLE . '` (`role_id`, `menu_id`)
             SELECT DISTINCT rm.`role_id`, target.`id`
             FROM `' . self::ROLE_MENU_TABLE . '` rm
             INNER JOIN `' . self::MENU_TABLE . '` source ON source.`id` = rm.`menu_id` AND source.`delete_time` IS NULL
             INNER JOIN `' . self::MENU_TABLE . '` target ON target.`delete_time` IS NULL
             LEFT JOIN `' . self::ROLE_MENU_TABLE . '` existing ON existing.`role_id` = rm.`role_id` AND existing.`menu_id` = target.`id`
             WHERE (
                   source.`code` IN (' . $this->quotedList(['help/config', 'help/config/runtime']) . ')
                   OR source.`slug` IN (' . $this->quotedList(['help:config:runtime:read', 'help:config:runtime:update']) . ')
               )
               AND (
                   target.`code` = ' . $this->q(self::MENU_CODE) . '
                   OR target.`slug` IN (' . $this->quotedList($this->permissionSlugs()) . ')
               )
               AND existing.`id` IS NULL'
        );
    }

    private function grantOperatorRoleMenus(): void
    {
        $this->execute(
            'INSERT INTO `' . self::ROLE_MENU_TABLE . '` (`role_id`, `menu_id`)
             SELECT r.`id`, m.`id`
             FROM `' . self::ROLE_TABLE . '` r
             INNER JOIN `' . self::MENU_TABLE . '` m ON m.`delete_time` IS NULL
             LEFT JOIN `' . self::ROLE_MENU_TABLE . '` rm ON rm.`role_id` = r.`id` AND rm.`menu_id` = m.`id`
             WHERE r.`code` = ' . $this->q(self::OPERATOR_ROLE_CODE) . '
               AND r.`delete_time` IS NULL
               AND rm.`id` IS NULL
               AND (
                   m.`code` = ' . $this->q(self::MENU_CODE) . '
                   OR m.`slug` IN (' . $this->quotedList($this->permissionSlugs()) . ')
               )'
        );
    }

    private function permissionSlugs(): array
    {
        return array_map(static fn (array $permission): string => $permission['slug'], $this->permissions());
    }

    private function clearCaches(): void
    {
        if (class_exists(\plugin\saiadmin\app\cache\ConfigCache::class)) {
            \plugin\saiadmin\app\cache\ConfigCache::clearConfig(self::GROUP_CODE);
            \plugin\saiadmin\app\cache\ConfigCache::clearConfig('upload_config');
        }
        if (class_exists(\plugin\saiadmin\app\cache\UserMenuCache::class)) {
            \plugin\saiadmin\app\cache\UserMenuCache::clearMenuCache();
        }
        if (class_exists(\plugin\saiadmin\app\cache\UserAuthCache::class)) {
            \plugin\saiadmin\app\cache\UserAuthCache::clear();
        }
    }

    private function quotedList(array $values): string
    {
        return implode(',', array_map(fn (string $value): string => $this->q($value), $values));
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
