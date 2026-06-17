<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddMaterialLyricUrl extends AbstractMigration
{
    public function up(): void
    {
        if ($this->hasTable('sa_content_material')) {
            $table = $this->table('sa_content_material');
            if (!$table->hasColumn('lyric_url')) {
                $table
                    ->addColumn('lyric_url', 'string', [
                        'limit' => 500,
                        'null' => true,
                        'default' => null,
                        'comment' => 'LRC歌词文件地址',
                        'after' => 'content_url',
                    ])
                    ->update();
            }
        }

        $this->appendUploadExtension('lrc');
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_content_material')) {
            return;
        }

        $table = $this->table('sa_content_material');
        if ($table->hasColumn('lyric_url')) {
            $table->removeColumn('lyric_url')->update();
        }
    }

    private function appendUploadExtension(string $extension): void
    {
        if (!$this->hasTable('sa_system_config') || !$this->hasTable('sa_system_config_group')) {
            return;
        }

        $row = $this->fetchRow(
            'SELECT c.`id`, c.`value`
            FROM `sa_system_config` c
            INNER JOIN `sa_system_config_group` g ON g.`id` = c.`group_id`
            WHERE g.`code` = ' . $this->q('upload_config') . '
              AND c.`key` = ' . $this->q('upload_allow_file') . '
              AND c.`delete_time` IS NULL
              AND g.`delete_time` IS NULL
            LIMIT 1'
        );
        if (!$row) {
            return;
        }

        $extensions = array_values(array_filter(array_map(
            static fn (string $item): string => strtolower(trim($item)),
            explode(',', (string) ($row['value'] ?? ''))
        )));
        if (in_array($extension, $extensions, true)) {
            return;
        }

        $extensions[] = $extension;
        $this->execute(
            'UPDATE `sa_system_config`
            SET `value` = ' . $this->q(implode(',', array_values(array_unique($extensions)))) . ', `update_time` = NOW()
            WHERE `id` = ' . (int) $row['id']
        );
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
