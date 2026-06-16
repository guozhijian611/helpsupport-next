<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddEntertainmentMaterialMusicMetadata extends AbstractMigration
{
    public function up(): void
    {
        if (!$this->hasTable('sa_content_material')) {
            return;
        }

        $table = $this->table('sa_content_material');
        if (!$table->hasColumn('artist')) {
            $table
                ->addColumn('artist', 'string', [
                    'limit' => 120,
                    'null' => true,
                    'default' => null,
                    'comment' => '歌手或作者',
                    'after' => 'summary_i18n',
                ])
                ->update();
        }
        if (!$table->hasColumn('album')) {
            $table
                ->addColumn('album', 'string', [
                    'limit' => 120,
                    'null' => true,
                    'default' => null,
                    'comment' => '音乐专辑',
                    'after' => 'artist',
                ])
                ->update();
        }
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_content_material')) {
            return;
        }

        $table = $this->table('sa_content_material');
        if ($table->hasColumn('album')) {
            $table->removeColumn('album')->update();
        }
        if ($table->hasColumn('artist')) {
            $table->removeColumn('artist')->update();
        }
    }
}
