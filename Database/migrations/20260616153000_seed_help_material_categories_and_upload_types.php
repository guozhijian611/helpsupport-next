<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedHelpMaterialCategoriesAndUploadTypes extends AbstractMigration
{
    private const REMARK = 'phinx:20260616153000_seed_help_material_categories_and_upload_types';
    private const UPLOAD_EXTENSIONS = ['epub', 'mov', 'mp3'];

    /**
     * @var array<int, array{type: string, name: string, en: string, icon: string, sort: int, legacy?: array<int, string>}>
     */
    private const CATEGORIES = [
        ['type' => 'education', 'name' => '入门', 'en' => 'Getting Started', 'icon' => 'ri:seedling-line', 'sort' => 10, 'legacy' => ['正念睡眠']],
        ['type' => 'education', 'name' => '动机与认知', 'en' => 'Motivation and Cognition', 'icon' => 'ri:brain-line', 'sort' => 20, 'legacy' => ['情绪调节']],
        ['type' => 'education', 'name' => '应对技能', 'en' => 'Coping Skills', 'icon' => 'ri:hand-heart-line', 'sort' => 30, 'legacy' => ['医生沟通']],
        ['type' => 'education', 'name' => '复发预防', 'en' => 'Relapse Prevention', 'icon' => 'ri:shield-check-line', 'sort' => 40],
        ['type' => 'education', 'name' => '家属指南', 'en' => 'Family Guide', 'icon' => 'ri:group-line', 'sort' => 50, 'legacy' => ['家庭支持']],
        ['type' => 'entertainment', 'name' => '书籍', 'en' => 'Books', 'icon' => 'ri:book-2-line', 'sort' => 10],
        ['type' => 'entertainment', 'name' => '电影', 'en' => 'Movies', 'icon' => 'ri:movie-2-line', 'sort' => 20],
        ['type' => 'entertainment', 'name' => '音乐', 'en' => 'Music', 'icon' => 'ri:music-2-line', 'sort' => 30],
        ['type' => 'entertainment', 'name' => '游戏', 'en' => 'Games', 'icon' => 'ri:gamepad-line', 'sort' => 40],
        ['type' => 'private', 'name' => '私人素材', 'en' => 'Private Materials', 'icon' => 'ri:lock-line', 'sort' => 10],
    ];

    public function up(): void
    {
        $this->seedCategories();
        $this->appendUploadExtensions();
    }

    public function down(): void
    {
        $this->removeUnreferencedSeedCategories();
        $this->removeUploadExtensions();
    }

    private function seedCategories(): void
    {
        if (!$this->hasTable('sa_content_category')) {
            return;
        }

        foreach (self::CATEGORIES as $category) {
            $nameI18n = $this->jsonName($category['name'], $category['en']);
            foreach ($category['legacy'] ?? [] as $legacyName) {
                $this->execute(
                    'UPDATE `sa_content_category`
                    SET `name` = ' . $this->q($category['name']) . ',
                        `name_i18n` = ' . $this->q($nameI18n) . ',
                        `icon` = ' . $this->q($category['icon']) . ',
                        `sort` = ' . (int) $category['sort'] . ',
                        `update_time` = NOW()
                    WHERE `type` = ' . $this->q($category['type']) . '
                      AND `name` = ' . $this->q($legacyName) . '
                      AND `delete_time` IS NULL
                      AND NOT EXISTS (
                          SELECT 1 FROM (
                              SELECT `id` FROM `sa_content_category`
                              WHERE `type` = ' . $this->q($category['type']) . '
                                AND `name` = ' . $this->q($category['name']) . '
                                AND `delete_time` IS NULL
                          ) target_category
                      )'
                );
            }

            $this->execute(
                'INSERT INTO `sa_content_category` (`parent_id`, `name`, `name_i18n`, `type`, `icon`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                SELECT 0, ' . $this->q($category['name']) . ', ' . $this->q($nameI18n) . ', ' . $this->q($category['type']) . ', ' . $this->q($category['icon']) . ', ' . (int) $category['sort'] . ', 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
                WHERE NOT EXISTS (
                    SELECT 1 FROM `sa_content_category`
                    WHERE `type` = ' . $this->q($category['type']) . '
                      AND `name` = ' . $this->q($category['name']) . '
                      AND `delete_time` IS NULL
                )'
            );

            $this->execute(
                'UPDATE `sa_content_category`
                SET `name_i18n` = ' . $this->q($nameI18n) . ', `update_time` = NOW()
                WHERE `type` = ' . $this->q($category['type']) . '
                  AND `name` = ' . $this->q($category['name']) . '
                  AND `delete_time` IS NULL
                  AND `name_i18n` IS NULL'
            );
        }
    }

    private function appendUploadExtensions(): void
    {
        if (!$this->hasTable('sa_system_config') || !$this->hasTable('sa_system_config_group')) {
            return;
        }

        $row = $this->uploadAllowFileRow();
        if (!$row) {
            return;
        }

        $extensions = $this->extensionList((string) ($row['value'] ?? ''));
        $next = array_values(array_unique(array_merge($extensions, self::UPLOAD_EXTENSIONS)));
        if ($next === $extensions) {
            return;
        }

        $this->execute(
            'UPDATE `sa_system_config`
            SET `value` = ' . $this->q(implode(',', $next)) . ', `update_time` = NOW()
            WHERE `id` = ' . (int) $row['id']
        );
    }

    private function removeUnreferencedSeedCategories(): void
    {
        if (!$this->hasTable('sa_content_category')) {
            return;
        }

        if (!$this->hasTable('sa_content_material')) {
            $this->execute('DELETE FROM `sa_content_category` WHERE `remark` = ' . $this->q(self::REMARK));
            return;
        }

        $this->execute(
            'DELETE c FROM `sa_content_category` c
            LEFT JOIN `sa_content_material` m ON m.`category_id` = c.`id` AND m.`delete_time` IS NULL
            WHERE c.`remark` = ' . $this->q(self::REMARK) . '
              AND m.`id` IS NULL'
        );
    }

    private function removeUploadExtensions(): void
    {
        // 无法可靠区分 epub/mov/mp3 是本迁移新增还是管理员原有配置，回滚时不自动移除上传白名单，避免误删用户配置。
    }

    /**
     * @return array<string, mixed>|false
     */
    private function uploadAllowFileRow(): array|false
    {
        return $this->fetchRow(
            'SELECT c.`id`, c.`value`
            FROM `sa_system_config` c
            INNER JOIN `sa_system_config_group` g ON g.`id` = c.`group_id`
            WHERE g.`code` = ' . $this->q('upload_config') . '
              AND c.`key` = ' . $this->q('upload_allow_file') . '
              AND c.`delete_time` IS NULL
              AND g.`delete_time` IS NULL
            LIMIT 1'
        );
    }

    /**
     * @return array<int, string>
     */
    private function extensionList(string $value): array
    {
        return array_values(array_filter(array_map(
            static fn (string $item): string => strtolower(trim($item)),
            explode(',', $value)
        )));
    }

    private function jsonName(string $zh, string $en): string
    {
        return (string) json_encode([
            'zh' => $zh,
            'zh-CN' => $zh,
            'en' => $en,
            'en-US' => $en,
        ], JSON_UNESCAPED_UNICODE);
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
