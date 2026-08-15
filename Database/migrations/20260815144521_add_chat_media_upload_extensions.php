<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddChatMediaUploadExtensions extends AbstractMigration
{
    private const FILE_EXTENSIONS = ['m4a', 'aac', 'mp3', 'wav', 'ogg', 'webm'];
    private const IMAGE_EXTENSIONS = ['webp', 'gif'];

    public function up(): void
    {
        $this->appendExtensions('upload_allow_file', self::FILE_EXTENSIONS);
        $this->appendExtensions('upload_allow_image', self::IMAGE_EXTENSIONS);
    }

    public function down(): void
    {
        // 上传白名单是管理员可编辑配置，无法判断回滚时的同名扩展是否已被其他业务依赖。
        // 为避免回滚误删用户配置，本迁移不自动移除已追加的扩展名。
    }

    /**
     * @param array<int, string> $extensions
     */
    private function appendExtensions(string $key, array $extensions): void
    {
        if (!$this->hasTable('sa_system_config') || !$this->hasTable('sa_system_config_group')) {
            return;
        }

        $row = $this->fetchRow(
            'SELECT c.`id`, c.`value`
             FROM `sa_system_config` c
             INNER JOIN `sa_system_config_group` g ON g.`id` = c.`group_id`
             WHERE g.`code` = ' . $this->q('upload_config') . '
               AND c.`key` = ' . $this->q($key) . '
               AND c.`delete_time` IS NULL
               AND g.`delete_time` IS NULL
             LIMIT 1'
        );
        if (!$row) {
            return;
        }

        $current = array_values(array_filter(array_map(
            static fn (string $item): string => strtolower(trim($item)),
            explode(',', (string) ($row['value'] ?? ''))
        )));
        $next = array_values(array_unique(array_merge($current, $extensions)));
        if ($next === $current) {
            return;
        }

        $this->execute(
            'UPDATE `sa_system_config`
             SET `value` = ' . $this->q(implode(',', $next)) . ', `update_time` = NOW()
             WHERE `id` = ' . (int) $row['id']
        );
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
