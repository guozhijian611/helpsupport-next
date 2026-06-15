<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddMemberProtocolLocale extends AbstractMigration
{
    public function up(): void
    {
        if (!$this->hasTable('sa_member_protocol')) {
            return;
        }

        $table = $this->table('sa_member_protocol');
        if (!$table->hasColumn('locale')) {
            $table
                ->addColumn('locale', 'string', [
                    'limit' => 20,
                    'default' => 'zh-CN',
                    'null' => false,
                    'comment' => '语言',
                    'after' => 'protocol_type',
                ])
                ->addIndex(['protocol_type', 'locale'], [
                    'name' => 'idx_protocol_type_locale',
                ])
                ->update();
        }

        $this->execute("UPDATE `sa_member_protocol` SET `locale` = 'zh-CN' WHERE `locale` IS NULL OR `locale` = ''");
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_member_protocol')) {
            return;
        }

        $table = $this->table('sa_member_protocol');
        if ($table->hasColumn('locale')) {
            $table->removeColumn('locale')->update();
        }
    }
}
