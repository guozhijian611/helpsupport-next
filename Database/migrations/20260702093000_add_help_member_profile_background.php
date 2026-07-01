<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpMemberProfileBackground extends AbstractMigration
{
    private const TABLE = 'sa_help_member_profile';
    private const COLUMN = 'profile_background';

    public function up(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        $table = $this->table(self::TABLE);
        if (!$table->hasColumn(self::COLUMN)) {
            $table->addColumn(self::COLUMN, 'string', [
                'limit' => 500,
                'default' => '',
                'null' => false,
                'comment' => '个人主页背景图',
                'after' => 'bio',
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
