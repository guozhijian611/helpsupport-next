<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpMemberFollowersPrivacyPreference extends AbstractMigration
{
    private const TABLE = 'sa_help_member_profile';
    private const COLUMN = 'privacy_show_followers_list';

    public function up(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        $table = $this->table(self::TABLE);
        if (!$table->hasColumn(self::COLUMN)) {
            $table->addColumn(self::COLUMN, 'integer', [
                'limit' => 1,
                'default' => 2,
                'null' => false,
                'comment' => '允许查看粉丝列表 1是 2否',
                'after' => 'privacy_show_following_list',
            ]);
            $table->update();
        }
    }

    public function down(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        $table = $this->table(self::TABLE);
        if ($table->hasColumn(self::COLUMN)) {
            $table->removeColumn(self::COLUMN);
            $table->update();
        }
    }
}
