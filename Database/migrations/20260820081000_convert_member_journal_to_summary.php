<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

/**
 * 将会员日记改为仅存非原文摘要。
 *
 * 不可逆：up() 会清空已有 title/content/media 原文，回滚只能删除新增字段，无法恢复被擦除的日记正文。
 */
final class ConvertMemberJournalToSummary extends AbstractMigration
{
    public function up(): void
    {
        if (!$this->hasTable('sa_member_journal')) {
            return;
        }

        $table = $this->table('sa_member_journal');
        if (!$table->hasColumn('local_id')) {
            $table->addColumn('local_id', 'biginteger', [
                'signed' => false,
                'null' => false,
                'default' => 0,
                'comment' => '客户端本地日记ID',
                'after' => 'member_id',
            ]);
        }
        if (!$table->hasColumn('summary')) {
            $table->addColumn('summary', 'string', [
                'limit' => 255,
                'null' => false,
                'default' => '',
                'comment' => '非原文摘要',
                'after' => 'content',
            ]);
        }
        if (!$table->hasColumn('word_count')) {
            $table->addColumn('word_count', 'integer', [
                'signed' => false,
                'null' => false,
                'default' => 0,
                'comment' => '日记字数',
                'after' => 'summary',
            ]);
        }
        $table->update();

        $this->execute(
            "UPDATE `sa_member_journal`
             SET `local_id` = IF(`local_id` > 0, `local_id`, `id`),
                 `summary` = IF(`summary` <> '', `summary`, '历史日记摘要已清除原文'),
                 `word_count` = IF(`word_count` > 0, `word_count`, 0),
                 `title` = '',
                 `content` = '',
                 `media` = NULL"
        );

        $table = $this->table('sa_member_journal');
        if (!$table->hasIndexByName('uk_member_journal_local')) {
            $table->addIndex(['member_id', 'local_id'], [
                'unique' => true,
                'name' => 'uk_member_journal_local',
            ])->update();
        }
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_member_journal')) {
            return;
        }

        $table = $this->table('sa_member_journal');
        if ($table->hasIndexByName('uk_member_journal_local')) {
            $table->removeIndexByName('uk_member_journal_local')->update();
        }
        if ($table->hasColumn('word_count')) {
            $table->removeColumn('word_count');
        }
        if ($table->hasColumn('summary')) {
            $table->removeColumn('summary');
        }
        if ($table->hasColumn('local_id')) {
            $table->removeColumn('local_id');
        }
        $table->update();
    }
}
