<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

/**
 * 互动角色增加「回复自动播放语音」开关，默认关闭，文字优先。
 */
final class AddAiPersonaAutoPlayVoice extends AbstractMigration
{
    public function up(): void
    {
        if (!$this->hasTable('sa_ai_persona')) {
            return;
        }

        $table = $this->table('sa_ai_persona');
        if ($table->hasColumn('auto_play_voice')) {
            return;
        }

        $this->execute(
            "ALTER TABLE `sa_ai_persona`
             ADD COLUMN `auto_play_voice` tinyint(1) NOT NULL DEFAULT 2
             COMMENT '回复自动播放语音 1是 2否，默认文字优先'
             AFTER `speech_runtime`"
        );
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_ai_persona')) {
            return;
        }

        $table = $this->table('sa_ai_persona');
        if ($table->hasColumn('auto_play_voice')) {
            $table->removeColumn('auto_play_voice')->update();
        }
    }
}
