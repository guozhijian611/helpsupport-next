<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class RenameSaiaiRealtimePlatformType extends AbstractMigration
{
    public function up(): void
    {
        if (!$this->hasTable('saiai_config')) {
            return;
        }

        $table = $this->table('saiai_config');
        if (!$table->hasColumn('options')) {
            return;
        }

        $this->execute(
            "UPDATE `saiai_config`
             SET `options` = '{\"provider\":\"aliyun_qwen\"}'
             WHERE `type` = 'aliyun_realtime'
               AND (`options` IS NULL OR TRIM(`options`) = '')"
        );

        $this->execute(
            "UPDATE `saiai_config`
             SET `options` = JSON_SET(`options`, '$.provider', 'aliyun_qwen')
             WHERE `type` = 'aliyun_realtime'
               AND IF(JSON_VALID(`options`), JSON_EXTRACT(`options`, '$.provider') IS NULL, false)"
        );

        $this->execute(
            "UPDATE `saiai_config`
             SET `type` = 'realtime'
             WHERE `type` = 'aliyun_realtime'"
        );
    }

    public function down(): void
    {
        if (!$this->hasTable('saiai_config')) {
            return;
        }

        $table = $this->table('saiai_config');
        if (!$table->hasColumn('options')) {
            return;
        }

        $this->execute(
            "UPDATE `saiai_config`
             SET `type` = 'aliyun_realtime'
             WHERE `type` = 'realtime'
               AND IF(JSON_VALID(`options`), JSON_UNQUOTE(JSON_EXTRACT(`options`, '$.provider')) = 'aliyun_qwen', false)"
        );
    }
}
