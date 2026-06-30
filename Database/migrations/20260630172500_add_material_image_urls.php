<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddMaterialImageUrls extends AbstractMigration
{
    public function up(): void
    {
        if (!$this->hasTable('sa_content_material')) {
            return;
        }

        $table = $this->table('sa_content_material');
        if (!$table->hasColumn('image_urls')) {
            $table
                ->addColumn('image_urls', 'json', [
                    'null' => true,
                    'default' => null,
                    'comment' => '图片素材多图地址',
                    'after' => 'content_url',
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
        if ($table->hasColumn('image_urls')) {
            $table->removeColumn('image_urls')->update();
        }
    }
}
