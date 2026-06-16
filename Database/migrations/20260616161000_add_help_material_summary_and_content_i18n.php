<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpMaterialSummaryAndContentI18n extends AbstractMigration
{
    private const REMARK = 'phinx:20260616161000_add_help_material_summary_and_content_i18n';
    private const PREVIOUS_CATEGORY_REMARK = 'phinx:20260616153000_seed_help_material_categories_and_upload_types';
    private const DEMO_CATEGORY_REMARK = 'demo:help-comprehensive:category';

    /**
     * @var array<int, array{type: string, name: string, en: string, icon: string, sort: int, preferred_id?: int, restore?: array{name: string, en: string, icon: string, sort: int}}>
     */
    private const CATEGORIES = [
        [
            'type' => 'education',
            'name' => '入门',
            'en' => 'Getting Started',
            'icon' => 'ri:seedling-line',
            'sort' => 10,
            'preferred_id' => 8901,
            'restore' => ['name' => '睡眠科学', 'en' => 'Sleep Science', 'icon' => 'i-tabler-moon-stars', 'sort' => 10],
        ],
        [
            'type' => 'education',
            'name' => '动机与认知',
            'en' => 'Motivation and Cognition',
            'icon' => 'ri:brain-line',
            'sort' => 20,
            'preferred_id' => 8902,
            'restore' => ['name' => '情绪调节', 'en' => 'Emotion Regulation', 'icon' => 'i-tabler-heart', 'sort' => 20],
        ],
        [
            'type' => 'education',
            'name' => '应对技能',
            'en' => 'Coping Skills',
            'icon' => 'ri:hand-heart-line',
            'sort' => 30,
            'preferred_id' => 8903,
            'restore' => ['name' => '医生沟通', 'en' => 'Doctor Communication', 'icon' => 'i-tabler-stethoscope', 'sort' => 30],
        ],
        ['type' => 'education', 'name' => '复发预防', 'en' => 'Relapse Prevention', 'icon' => 'ri:shield-check-line', 'sort' => 40],
        [
            'type' => 'education',
            'name' => '家属指南',
            'en' => 'Family Guide',
            'icon' => 'ri:group-line',
            'sort' => 50,
            'preferred_id' => 8904,
            'restore' => ['name' => '家庭支持', 'en' => 'Family Support', 'icon' => 'i-tabler-home-heart', 'sort' => 40],
        ],
        ['type' => 'entertainment', 'name' => '书籍', 'en' => 'Books', 'icon' => 'ri:book-2-line', 'sort' => 10],
        ['type' => 'entertainment', 'name' => '电影', 'en' => 'Movies', 'icon' => 'ri:movie-2-line', 'sort' => 20],
        ['type' => 'entertainment', 'name' => '音乐', 'en' => 'Music', 'icon' => 'ri:music-2-line', 'sort' => 30],
        ['type' => 'entertainment', 'name' => '游戏', 'en' => 'Games', 'icon' => 'ri:gamepad-line', 'sort' => 40],
        ['type' => 'private', 'name' => '私人素材', 'en' => 'Private Materials', 'icon' => 'ri:lock-line', 'sort' => 10],
    ];

    /**
     * @var array<int, array{summary: array{zh: string, en: string}, content: array{zh: string, en: string}}>
     */
    private const DEMO_MATERIAL_I18N = [
        8911 => [
            'summary' => [
                'zh' => '一套适合睡前快速降噪的身体扫描步骤。',
                'en' => 'A short body-scan routine for quieting the mind before sleep.',
            ],
            'content' => [
                'zh' => '<p>把注意力从脚底一路带回头顶，不急着放松，只做观察。</p><p>当你发现又开始想事情，就轻轻回到身体感觉。</p>',
                'en' => '<p>Move attention from the soles of your feet back toward the top of your head. Do not force relaxation; just observe.</p><p>When thoughts return, gently come back to body sensations.</p>',
            ],
        ],
        8912 => [
            'summary' => [
                'zh' => '适合夜间醒来后快速降低警觉水平的短音频。',
                'en' => 'A brief audio practice for lowering alertness after waking at night.',
            ],
            'content' => [
                'zh' => '<p>这段音频会带你把注意力放回呼吸和身体接触面。</p>',
                'en' => '<p>This audio guides attention back to breathing and the body contact points.</p>',
            ],
        ],
        8913 => [
            'summary' => [
                'zh' => '解释为什么晨间光照会影响午后困意和入睡时间。',
                'en' => 'Explains why morning light affects afternoon sleepiness and bedtime.',
            ],
            'content' => [
                'zh' => '<p>内容包括晨间光照、午后困意、咖啡窗口三个关键点。</p>',
                'en' => '<p>This material covers morning light, afternoon sleepiness, and caffeine timing.</p>',
            ],
        ],
        8914 => [
            'summary' => [
                'zh' => '帮助你在复诊前用同一结构整理症状变化、疑问和目标。',
                'en' => 'Helps organize symptom changes, questions, and goals before a follow-up visit.',
            ],
            'content' => [
                'zh' => '<p>按“变化、触发点、想问医生的事”三栏填写。</p>',
                'en' => '<p>Use three columns: changes, triggers, and questions for the doctor.</p>',
            ],
        ],
        8915 => [
            'summary' => [
                'zh' => '针对夜班后的补觉节律给出几个更可执行的窗口建议。',
                'en' => 'Gives practical recovery-sleep windows after night shifts.',
            ],
            'content' => [
                'zh' => '<p>核心不是“补够所有觉”，而是先保护最关键的恢复窗口。</p>',
                'en' => '<p>The goal is not to recover every hour of sleep immediately, but to protect the most important recovery window first.</p>',
            ],
        ],
        8916 => [
            'summary' => [
                'zh' => '把睡眠、情绪、家属支持相关的外部帮助资源放到一个入口里。',
                'en' => 'Collects external sleep, mood, and family-support resources in one place.',
            ],
            'content' => [
                'zh' => '<p>适合把家庭支持、情绪支持和热线资源统一收藏。</p>',
                'en' => '<p>Useful for saving family support, emotional support, and hotline resources together.</p>',
            ],
        ],
        8917 => [
            'summary' => [
                'zh' => '用 3 个问题把散乱感受整理成医生能快速抓住的线索。',
                'en' => 'Uses three questions to turn scattered feelings into clues a doctor can read quickly.',
            ],
            'content' => [
                'zh' => '<p>建议从“最明显的变化、最稳定的触发点、最想知道的问题”三个角度来写。</p>',
                'en' => '<p>Write from three angles: the clearest change, the most stable trigger, and the question you most want answered.</p>',
            ],
        ],
        8918 => [
            'summary' => [
                'zh' => '把注意力从脑内反复转回到五感和当下环境。',
                'en' => 'Shifts attention from repetitive thoughts back to the five senses and the current environment.',
            ],
            'content' => [
                'zh' => '<p>适合在情绪开始往上冲的时候立刻使用，帮助身体先降一点速。</p>',
                'en' => '<p>Use this as soon as emotions begin to surge so the body can slow down first.</p>',
            ],
        ],
    ];

    public function up(): void
    {
        $this->addMaterialI18nColumns();
        $this->normalizeMaterialCategories();
        $this->seedDemoMaterialI18n();
    }

    public function down(): void
    {
        $this->dropMaterialI18nColumns();
        $this->restoreDemoCategories();
        $this->deleteUnreferencedSelfCategories();
    }

    private function addMaterialI18nColumns(): void
    {
        if (!$this->hasTable('sa_content_material')) {
            return;
        }

        if (!$this->table('sa_content_material')->hasColumn('summary_i18n')) {
            $this->execute('ALTER TABLE `sa_content_material` ADD COLUMN `summary_i18n` json DEFAULT NULL COMMENT ' . $this->q('多语言摘要') . ' AFTER `summary`');
        }

        if (!$this->table('sa_content_material')->hasColumn('content_text_i18n')) {
            $this->execute('ALTER TABLE `sa_content_material` ADD COLUMN `content_text_i18n` json DEFAULT NULL COMMENT ' . $this->q('多语言富文本内容') . ' AFTER `content_text`');
        }
    }

    private function dropMaterialI18nColumns(): void
    {
        if (!$this->hasTable('sa_content_material')) {
            return;
        }

        $table = $this->table('sa_content_material');
        if ($table->hasColumn('content_text_i18n')) {
            $table->removeColumn('content_text_i18n')->update();
        }
        if ($this->table('sa_content_material')->hasColumn('summary_i18n')) {
            $this->table('sa_content_material')->removeColumn('summary_i18n')->update();
        }
    }

    private function normalizeMaterialCategories(): void
    {
        if (!$this->hasTable('sa_content_category')) {
            return;
        }

        foreach (self::CATEGORIES as $category) {
            if (!empty($category['preferred_id']) && $this->categoryExists((int) $category['preferred_id'])) {
                $this->execute(
                    'UPDATE `sa_content_category`
                    SET `name` = ' . $this->q($category['name']) . ',
                        `name_i18n` = ' . $this->q($this->i18nJson($category['name'], $category['en'])) . ',
                        `icon` = ' . $this->q($category['icon']) . ',
                        `sort` = ' . (int) $category['sort'] . ',
                        `update_time` = NOW()
                    WHERE `id` = ' . (int) $category['preferred_id'] . '
                      AND `delete_time` IS NULL'
                );
            }

            $this->ensureCategory($category);
            $this->mergeDuplicateCategory(
                $category['type'],
                $category['name'],
                isset($category['preferred_id']) ? (int) $category['preferred_id'] : 0
            );
        }
    }

    /**
     * @param array{type: string, name: string, en: string, icon: string, sort: int} $category
     */
    private function ensureCategory(array $category): void
    {
        $this->execute(
            'INSERT INTO `sa_content_category` (`parent_id`, `name`, `name_i18n`, `type`, `icon`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT 0, ' . $this->q($category['name']) . ', ' . $this->q($this->i18nJson($category['name'], $category['en'])) . ', ' . $this->q($category['type']) . ', ' . $this->q($category['icon']) . ', ' . (int) $category['sort'] . ', 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
            WHERE NOT EXISTS (
                SELECT 1 FROM `sa_content_category`
                WHERE `type` = ' . $this->q($category['type']) . '
                  AND `name` = ' . $this->q($category['name']) . '
                  AND `delete_time` IS NULL
            )'
        );
    }

    private function mergeDuplicateCategory(string $type, string $name, int $preferredId): void
    {
        $rows = $this->fetchAll(
            'SELECT `id`, `remark`
            FROM `sa_content_category`
            WHERE `type` = ' . $this->q($type) . '
              AND `name` = ' . $this->q($name) . '
              AND `delete_time` IS NULL
            ORDER BY `id` ASC'
        );
        if (count($rows) <= 1) {
            return;
        }

        $ids = array_map(static fn (array $row): int => (int) $row['id'], $rows);
        $keepId = in_array($preferredId, $ids, true) ? $preferredId : $ids[0];
        foreach ($rows as $row) {
            $id = (int) $row['id'];
            if ($id === $keepId) {
                continue;
            }
            if ($this->hasTable('sa_content_material')) {
                $this->execute('UPDATE `sa_content_material` SET `category_id` = ' . $keepId . ' WHERE `category_id` = ' . $id);
            }

            if (in_array((string) ($row['remark'] ?? ''), [self::REMARK, self::PREVIOUS_CATEGORY_REMARK], true)) {
                $this->execute('DELETE FROM `sa_content_category` WHERE `id` = ' . $id);
            }
        }
    }

    private function seedDemoMaterialI18n(): void
    {
        if (!$this->hasTable('sa_content_material')) {
            return;
        }
        if (!$this->table('sa_content_material')->hasColumn('summary_i18n')
            || !$this->table('sa_content_material')->hasColumn('content_text_i18n')) {
            return;
        }

        foreach (self::DEMO_MATERIAL_I18N as $id => $i18n) {
            $this->execute(
                'UPDATE `sa_content_material`
                SET `summary_i18n` = ' . $this->q($this->i18nJson($i18n['summary']['zh'], $i18n['summary']['en'])) . ',
                    `content_text_i18n` = ' . $this->q($this->i18nJson($i18n['content']['zh'], $i18n['content']['en'])) . ',
                    `update_time` = NOW()
                WHERE `id` = ' . (int) $id . '
                  AND `delete_time` IS NULL'
            );
        }
    }

    private function restoreDemoCategories(): void
    {
        if (!$this->hasTable('sa_content_category')) {
            return;
        }

        foreach (self::CATEGORIES as $category) {
            if (empty($category['preferred_id']) || empty($category['restore'])) {
                continue;
            }
            $restore = $category['restore'];
            $this->execute(
                'UPDATE `sa_content_category`
                SET `name` = ' . $this->q($restore['name']) . ',
                    `name_i18n` = ' . $this->q($this->i18nJson($restore['name'], $restore['en'])) . ',
                    `icon` = ' . $this->q($restore['icon']) . ',
                    `sort` = ' . (int) $restore['sort'] . ',
                    `update_time` = NOW()
                WHERE `id` = ' . (int) $category['preferred_id'] . '
                  AND `remark` = ' . $this->q(self::DEMO_CATEGORY_REMARK) . '
                  AND `name` = ' . $this->q($category['name']) . '
                  AND `delete_time` IS NULL'
            );
        }
    }

    private function deleteUnreferencedSelfCategories(): void
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

    private function categoryExists(int $id): bool
    {
        return (bool) $this->fetchRow(
            'SELECT `id`
            FROM `sa_content_category`
            WHERE `id` = ' . $id . '
              AND `delete_time` IS NULL
            LIMIT 1'
        );
    }

    private function i18nJson(string $zh, string $en): string
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
