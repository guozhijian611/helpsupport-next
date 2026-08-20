<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

/**
 * 回忆录按生成配置独立落库，避免多套规则共用同一条记录。
 */
final class AddHelpMemoirConfigId extends AbstractMigration
{
    public function up(): void
    {
        if ($this->hasTable('sa_member_memoir')) {
            $table = $this->table('sa_member_memoir');
            if (!$table->hasColumn('config_id')) {
                $table
                    ->addColumn('config_id', 'integer', [
                        'signed' => false,
                        'null' => false,
                        'default' => 0,
                        'comment' => '回忆录配置ID',
                        'after' => 'member_id',
                    ])
                    ->update();
            }

            if ($this->hasTable('sa_member_memoir_config')) {
                $this->execute(
                    "UPDATE `sa_member_memoir` AS m
                     INNER JOIN `sa_member_memoir_config` AS c
                        ON c.delete_time IS NULL
                       AND m.remark = CONCAT('由回忆录配置 ', c.code, ' 自动生成')
                     SET m.config_id = c.id
                     WHERE m.config_id = 0"
                );
            }

            $table = $this->table('sa_member_memoir');
            if ($table->hasIndexByName('uk_member_level_rank')) {
                $table->removeIndexByName('uk_member_level_rank')->update();
            }
            if (!$table->hasIndexByName('uk_member_config_rank')) {
                $table->addIndex(['member_id', 'config_id', 'grant_level_rank'], [
                    'unique' => true,
                    'name' => 'uk_member_config_rank',
                ])->update();
            }
            if (!$table->hasIndexByName('idx_member_config')) {
                $table->addIndex(['member_id', 'config_id'], [
                    'name' => 'idx_member_config',
                ])->update();
            }
        }

        if ($this->hasTable('sa_member_memoir_config')) {
            $this->execute(
                "UPDATE `sa_member_memoir_config`
                 SET `trigger_mode` = 'cycle'
                 WHERE `code` IN ('demo_weekly_reframe', 'demo_quarterly_milestone')
                   AND `trigger_mode` = 'level_up'
                   AND `delete_time` IS NULL"
            );
        }
    }

    public function down(): void
    {
        if ($this->hasTable('sa_member_memoir_config')) {
            $this->execute(
                "UPDATE `sa_member_memoir_config`
                 SET `trigger_mode` = 'level_up'
                 WHERE `code` IN ('demo_weekly_reframe', 'demo_quarterly_milestone')
                   AND `trigger_mode` = 'cycle'
                   AND `delete_time` IS NULL"
            );
        }

        if (!$this->hasTable('sa_member_memoir')) {
            return;
        }

        $table = $this->table('sa_member_memoir');
        if ($table->hasIndexByName('uk_member_config_rank')) {
            $table->removeIndexByName('uk_member_config_rank')->update();
        }
        if ($table->hasIndexByName('idx_member_config')) {
            $table->removeIndexByName('idx_member_config')->update();
        }
        if (!$table->hasIndexByName('uk_member_level_rank')) {
            $table->addIndex(['member_id', 'grant_level_rank'], [
                'unique' => true,
                'name' => 'uk_member_level_rank',
            ])->update();
        }
        if ($table->hasColumn('config_id')) {
            $table->removeColumn('config_id')->update();
        }
    }
}
