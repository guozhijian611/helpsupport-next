<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class FixHelpOauthEnabledConfigOptions extends AbstractMigration
{
    private const OPTIONS = [
        ['label' => '启用', 'value' => '1'],
        ['label' => '禁用', 'value' => '2'],
    ];

    public function up(): void
    {
        $this->execute(
            'UPDATE `sa_system_config` AS `c`
             INNER JOIN `sa_system_config_group` AS `g` ON `g`.`id` = `c`.`group_id`
             SET `c`.`config_select_data` = ' . $this->q($this->json(self::OPTIONS)) . ',
                 `c`.`update_time` = NOW()
             WHERE `g`.`code` IN (' . $this->q('help_google_oauth') . ', ' . $this->q('help_apple_oauth') . ', ' . $this->q('help_firebase_push') . ')
               AND `g`.`delete_time` IS NULL
               AND `c`.`key` = ' . $this->q('enabled') . '
               AND `c`.`input_type` = ' . $this->q('radio') . '
               AND `c`.`delete_time` IS NULL
               AND (`c`.`config_select_data` IS NULL OR `c`.`config_select_data` = ' . $this->q('') . ' OR `c`.`config_select_data` = ' . $this->q('[]') . ')'
        );
    }

    public function down(): void
    {
        $this->execute(
            'UPDATE `sa_system_config` AS `c`
             INNER JOIN `sa_system_config_group` AS `g` ON `g`.`id` = `c`.`group_id`
             SET `c`.`config_select_data` = NULL,
                 `c`.`update_time` = NOW()
             WHERE `g`.`code` IN (' . $this->q('help_google_oauth') . ', ' . $this->q('help_apple_oauth') . ', ' . $this->q('help_firebase_push') . ')
               AND `g`.`delete_time` IS NULL
               AND `c`.`key` = ' . $this->q('enabled') . '
               AND `c`.`input_type` = ' . $this->q('radio') . '
               AND `c`.`delete_time` IS NULL
               AND `c`.`config_select_data` = ' . $this->q($this->json(self::OPTIONS))
        );
    }

    private function json(array $value): string
    {
        return json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?: '[]';
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
