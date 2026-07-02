<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class UpdateDefaultUploadLimitTo500m extends AbstractMigration
{
    private const GROUP_TABLE = 'sa_system_config_group';
    private const CONFIG_TABLE = 'sa_system_config';
    private const GROUP_CODE = 'upload_config';
    private const OLD_DEFAULT_BYTES = '52428800';
    private const NEW_DEFAULT_BYTES = '524288000';
    private const REMARK = 'phinx:20260702183000_update_default_upload_limit_to_500m';

    public function up(): void
    {
        if (!$this->hasTable(self::GROUP_TABLE) || !$this->hasTable(self::CONFIG_TABLE)) {
            return;
        }

        $this->execute(
            'UPDATE `' . self::CONFIG_TABLE . '` c
             INNER JOIN `' . self::GROUP_TABLE . '` g
                ON g.`id` = c.`group_id`
               AND g.`code` = ' . $this->q(self::GROUP_CODE) . '
               AND g.`delete_time` IS NULL
             SET c.`value` = ' . $this->q(self::NEW_DEFAULT_BYTES) . ',
                 c.`update_time` = NOW()
             WHERE c.`key` = ' . $this->q('upload_size') . '
               AND c.`delete_time` IS NULL
               AND (c.`value` IS NULL OR c.`value` = ' . $this->q('') . ' OR c.`value` = ' . $this->q(self::OLD_DEFAULT_BYTES) . ')'
        );

        $this->execute(
            'INSERT INTO `' . self::CONFIG_TABLE . '` (`group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT g.`id`, ' . $this->q('upload_size') . ', ' . $this->q(self::NEW_DEFAULT_BYTES) . ', ' . $this->q('上传大小') . ', ' . $this->q('input') . ', NULL, 88, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             FROM `' . self::GROUP_TABLE . '` g
             WHERE g.`code` = ' . $this->q(self::GROUP_CODE) . '
               AND g.`delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `' . self::CONFIG_TABLE . '` c
                   WHERE c.`group_id` = g.`id`
                     AND c.`key` = ' . $this->q('upload_size') . '
                     AND c.`delete_time` IS NULL
               )
             LIMIT 1'
        );

        $this->clearUploadConfigCache();
    }

    public function down(): void
    {
        if (!$this->hasTable(self::GROUP_TABLE) || !$this->hasTable(self::CONFIG_TABLE)) {
            return;
        }

        $this->execute(
            'DELETE c FROM `' . self::CONFIG_TABLE . '` c
             INNER JOIN `' . self::GROUP_TABLE . '` g
                ON g.`id` = c.`group_id`
               AND g.`code` = ' . $this->q(self::GROUP_CODE) . '
             WHERE c.`key` = ' . $this->q('upload_size') . '
               AND c.`value` = ' . $this->q(self::NEW_DEFAULT_BYTES) . '
               AND c.`remark` = ' . $this->q(self::REMARK)
        );

        $this->execute(
            'UPDATE `' . self::CONFIG_TABLE . '` c
             INNER JOIN `' . self::GROUP_TABLE . '` g
                ON g.`id` = c.`group_id`
               AND g.`code` = ' . $this->q(self::GROUP_CODE) . '
               AND g.`delete_time` IS NULL
             SET c.`value` = ' . $this->q(self::OLD_DEFAULT_BYTES) . ',
                 c.`update_time` = NOW()
             WHERE c.`key` = ' . $this->q('upload_size') . '
               AND c.`delete_time` IS NULL
               AND c.`value` = ' . $this->q(self::NEW_DEFAULT_BYTES)
        );

        $this->clearUploadConfigCache();
    }

    private function clearUploadConfigCache(): void
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
