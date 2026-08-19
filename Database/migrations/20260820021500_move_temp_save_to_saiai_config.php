<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class MoveTempSaveToSaiaiConfig extends AbstractMigration
{
    public function up(): void
    {
        $this->addSaiaiTempSave();
        $this->addMemberOnlineConfigId();
        $this->copyMemberTempSaveToOnlineConfigId();
        $this->removeMemberTempSave();
    }

    public function down(): void
    {
        $this->restoreMemberTempSave();
        $this->copyOnlineConfigIdToMemberTempSave();
        $this->removeMemberOnlineConfigId();
        $this->removeSaiaiTempSave();
    }

    private function addSaiaiTempSave(): void
    {
        if (!$this->hasTable('saiai_config')) {
            return;
        }

        $table = $this->table('saiai_config');
        if (!$table->hasColumn('temp_save')) {
            $table->addColumn('temp_save', 'string', [
                'limit' => 500,
                'default' => '',
                'null' => false,
                'comment' => '后台临时字符串配置，供 App 读取',
                'after' => 'remark',
            ])->update();
        }
    }

    private function removeSaiaiTempSave(): void
    {
        if (!$this->hasTable('saiai_config')) {
            return;
        }

        $table = $this->table('saiai_config');
        if ($table->hasColumn('temp_save')) {
            $table->removeColumn('temp_save')->update();
        }
    }

    private function addMemberOnlineConfigId(): void
    {
        if (!$this->hasTable('sa_member_chat_config')) {
            return;
        }

        $table = $this->table('sa_member_chat_config');
        if (!$table->hasColumn('online_config_id')) {
            $table->addColumn('online_config_id', 'integer', [
                'default' => 0,
                'null' => false,
                'comment' => '会员最近选择的在线 AI 配置ID',
                'after' => 'prompt_text',
            ])->update();
        }
    }

    private function removeMemberOnlineConfigId(): void
    {
        if (!$this->hasTable('sa_member_chat_config')) {
            return;
        }

        $table = $this->table('sa_member_chat_config');
        if ($table->hasColumn('online_config_id')) {
            $table->removeColumn('online_config_id')->update();
        }
    }

    private function copyMemberTempSaveToOnlineConfigId(): void
    {
        if (!$this->hasTable('sa_member_chat_config')) {
            return;
        }

        $table = $this->table('sa_member_chat_config');
        if (!$table->hasColumn('temp_save') || !$table->hasColumn('online_config_id')) {
            return;
        }

        $this->execute(
            "UPDATE `sa_member_chat_config`
             SET `online_config_id` = CAST(`temp_save` AS UNSIGNED)
             WHERE `temp_save` REGEXP '^[1-9][0-9]*$'"
        );
    }

    private function copyOnlineConfigIdToMemberTempSave(): void
    {
        if (!$this->hasTable('sa_member_chat_config')) {
            return;
        }

        $table = $this->table('sa_member_chat_config');
        if (!$table->hasColumn('temp_save') || !$table->hasColumn('online_config_id')) {
            return;
        }

        $this->execute(
            "UPDATE `sa_member_chat_config`
             SET `temp_save` = CASE
                 WHEN `online_config_id` > 0 THEN CAST(`online_config_id` AS CHAR)
                 ELSE ''
             END"
        );
    }

    private function removeMemberTempSave(): void
    {
        if (!$this->hasTable('sa_member_chat_config')) {
            return;
        }

        $table = $this->table('sa_member_chat_config');
        if ($table->hasColumn('temp_save')) {
            $table->removeColumn('temp_save')->update();
        }
    }

    private function restoreMemberTempSave(): void
    {
        if (!$this->hasTable('sa_member_chat_config')) {
            return;
        }

        $table = $this->table('sa_member_chat_config');
        if (!$table->hasColumn('temp_save')) {
            $table->addColumn('temp_save', 'string', [
                'limit' => 500,
                'default' => '',
                'null' => false,
                'comment' => '临时字符串配置，在线聊天保存最近选择的模型配置ID',
                'after' => 'prompt_text',
            ])->update();
        }
    }
}
