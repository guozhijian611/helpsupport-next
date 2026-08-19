<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpLocalModelCover extends AbstractMigration
{
    public function up(): void
    {
        if (!$this->hasTable('sa_local_model_catalog')) {
            return;
        }

        $table = $this->table('sa_local_model_catalog');
        if (!$table->hasColumn('cover_url')) {
            $table->addColumn('cover_url', 'string', [
                'limit' => 1000,
                'default' => '',
                'null' => false,
                'comment' => '封面图地址',
                'after' => 'name',
            ])->update();
        }
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_local_model_catalog')) {
            return;
        }

        $table = $this->table('sa_local_model_catalog');
        if ($table->hasColumn('cover_url')) {
            $table->removeColumn('cover_url')->update();
        }
    }
}
