<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpMemoirLevelTriggerAndMaterials extends AbstractMigration
{
    public function up(): void
    {
        if ($this->hasTable('sa_member_memoir_config')) {
            $table = $this->table('sa_member_memoir_config');
            if (!$table->hasColumn('trigger_mode')) {
                $table
                    ->addColumn('trigger_mode', 'string', [
                        'limit' => 30,
                        'null' => false,
                        'default' => 'level_up',
                        'comment' => '触发模式:level_up/level_interval/cycle/manual',
                        'after' => 'code',
                    ])
                    ->update();
            }
            if (!$table->hasColumn('level_step')) {
                $table
                    ->addColumn('level_step', 'integer', [
                        'signed' => false,
                        'null' => false,
                        'default' => 1,
                        'comment' => '生成等级间隔，1表示每升一级',
                        'after' => 'trigger_mode',
                    ])
                    ->update();
            }
            if (!$table->hasColumn('material_sources')) {
                $table
                    ->addColumn('material_sources', 'json', [
                        'null' => true,
                        'default' => null,
                        'comment' => '回忆录素材来源:journal/task/material_history/material_collect/private_material',
                        'after' => 'source_type',
                    ])
                    ->update();
            }
            if (!$table->hasColumn('min_material_count')) {
                $table
                    ->addColumn('min_material_count', 'integer', [
                        'signed' => false,
                        'null' => false,
                        'default' => 0,
                        'comment' => '最少素材条数',
                        'after' => 'min_journal_count',
                    ])
                    ->update();
            }
            if (!$table->hasIndex(['trigger_mode', 'status'])) {
                $table->addIndex(['trigger_mode', 'status'], ['name' => 'idx_trigger_status'])->update();
            }
        }

        if ($this->hasTable('sa_member_memoir')) {
            $table = $this->table('sa_member_memoir');
            if (!$table->hasColumn('material_count')) {
                $table
                    ->addColumn('material_count', 'integer', [
                        'signed' => false,
                        'null' => false,
                        'default' => 0,
                        'comment' => '素材条数',
                        'after' => 'journal_count',
                    ])
                    ->update();
            }
            if (!$table->hasColumn('source_materials')) {
                $table
                    ->addColumn('source_materials', 'json', [
                        'null' => true,
                        'default' => null,
                        'comment' => '生成时使用的素材内容快照',
                        'after' => 'material_count',
                    ])
                    ->update();
            }
        }
    }

    public function down(): void
    {
        if ($this->hasTable('sa_member_memoir')) {
            $table = $this->table('sa_member_memoir');
            if ($table->hasColumn('source_materials')) {
                $table->removeColumn('source_materials')->update();
            }
            if ($table->hasColumn('material_count')) {
                $table->removeColumn('material_count')->update();
            }
        }

        if ($this->hasTable('sa_member_memoir_config')) {
            $table = $this->table('sa_member_memoir_config');
            if ($table->hasIndex(['trigger_mode', 'status'])) {
                $table->removeIndex(['trigger_mode', 'status'])->update();
            }
            foreach (['min_material_count', 'material_sources', 'level_step', 'trigger_mode'] as $column) {
                if ($table->hasColumn($column)) {
                    $table->removeColumn($column)->update();
                }
            }
        }
    }
}
