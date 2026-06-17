<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedMusicDemoLrc extends AbstractMigration
{
    private const DEMO_CONTENT_URL = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
    private const DEMO_LYRIC_URL = '/demo/material/soundhelix-song-1.lrc';

    public function up(): void
    {
        if (!$this->hasTable('sa_content_material')) {
            return;
        }

        $table = $this->table('sa_content_material');
        if (!$table->hasColumn('lyric_url')) {
            return;
        }

        $this->execute(
            'UPDATE `sa_content_material`
            SET `lyric_url` = ' . $this->q(self::DEMO_LYRIC_URL) . ', `update_time` = NOW()
            WHERE `content_url` = ' . $this->q(self::DEMO_CONTENT_URL) . '
              AND (`lyric_url` IS NULL OR `lyric_url` = \'\')'
        );
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_content_material')) {
            return;
        }

        $table = $this->table('sa_content_material');
        if (!$table->hasColumn('lyric_url')) {
            return;
        }

        $this->execute(
            'UPDATE `sa_content_material`
            SET `lyric_url` = NULL, `update_time` = NOW()
            WHERE `content_url` = ' . $this->q(self::DEMO_CONTENT_URL) . '
              AND `lyric_url` = ' . $this->q(self::DEMO_LYRIC_URL)
        );
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
