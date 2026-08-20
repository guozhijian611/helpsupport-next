<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

/**
 * 会员聊天会话保存上游模型 session，便于后续 /v1/chat/completions 复用。
 */
final class AddMemberChatModelSession extends AbstractMigration
{
    public function up(): void
    {
        if (!$this->hasTable('sa_member_chat_session')) {
            return;
        }

        $table = $this->table('sa_member_chat_session');
        if (!$table->hasColumn('model_session')) {
            $this->execute(
                "ALTER TABLE `sa_member_chat_session`
                 ADD COLUMN `model_session` varchar(191) NOT NULL DEFAULT ''
                 COMMENT '上游模型会话ID，对应 chat/completions 的 session 字段'
                 AFTER `is_pinned`"
            );
        }
        if (!$table->hasColumn('model_session_config_id')) {
            $this->execute(
                "ALTER TABLE `sa_member_chat_session`
                 ADD COLUMN `model_session_config_id` int(11) NOT NULL DEFAULT 0
                 COMMENT '写入 model_session 时使用的 saiai 配置ID'
                 AFTER `model_session`"
            );
        }
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_member_chat_session')) {
            return;
        }

        $table = $this->table('sa_member_chat_session');
        if ($table->hasColumn('model_session_config_id')) {
            $table->removeColumn('model_session_config_id')->update();
        }
        if ($table->hasColumn('model_session')) {
            $table->removeColumn('model_session')->update();
        }
    }
}
