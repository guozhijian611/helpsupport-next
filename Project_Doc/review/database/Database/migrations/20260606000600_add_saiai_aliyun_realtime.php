<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddSaiaiAliyunRealtime extends AbstractMigration
{
    private const REMARK = 'phinx:20260606000600_add_saiai_aliyun_realtime';

    public function up(): void
    {
        if ($this->hasTable('saiai_config')) {
            $table = $this->table('saiai_config');
            if (!$table->hasColumn('ai_url')) {
                $table->addColumn('ai_url', 'string', [
                    'limit' => 255,
                    'null' => false,
                    'default' => '',
                    'after' => 'type',
                    'comment' => 'API URL',
                ])->update();

                if ($table->hasColumn('base_url')) {
                    $this->execute("UPDATE `saiai_config` SET `ai_url` = COALESCE(`base_url`, '') WHERE `ai_url` = ''");
                }
            }

            $table = $this->table('saiai_config');
            if (!$table->hasColumn('options')) {
                $table->addColumn('options', 'text', [
                    'null' => true,
                    'after' => 'model',
                    'comment' => '扩展配置JSON',
                ])->update();
            }
        }

        $this->execute(
            "INSERT INTO `saiai_config` (`name`, `type`, `ai_url`, `ai_key`, `model`, `options`, `is_default`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT '阿里云实时语音（北京）', 'aliyun_realtime', 'wss://dashscope.aliyuncs.com/api-ws/v1/realtime', '', 'qwen3-omni-flash-realtime-2025-12-01',
                   '{\"region\":\"cn-beijing\",\"compatible_base_url\":\"https://dashscope.aliyuncs.com/compatible-mode/v1\",\"modalities\":[\"text\",\"audio\"],\"voice\":\"Ethan\"}',
                   2, 2, '" . self::REMARK . "', 1, 1, NOW(), NOW(), NULL
            WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'saiai_config')
              AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'saiai_config' AND column_name = 'ai_url')
              AND NOT EXISTS (
                SELECT 1 FROM `saiai_config`
                WHERE `type` = 'aliyun_realtime'
                  AND `model` = 'qwen3-omni-flash-realtime-2025-12-01'
                  AND `delete_time` IS NULL
              )"
        );

        $this->insertMenu('实时测试', 'saiai/realtime/test', 'realtime/test', '/plugin/saiai/realtime/test/index', 'ri:voiceprint-line', 90);
        $this->insertPermission('saiai/realtime/test', '打开实时测试', 'saiai:realtime:test');
    }

    public function down(): void
    {
        $this->execute("DELETE FROM `sa_system_menu` WHERE `remark` = '" . self::REMARK . "'");
        $this->execute(
            "DELETE FROM `saiai_config`
            WHERE `type` = 'aliyun_realtime'
              AND `model` = 'qwen3-omni-flash-realtime-2025-12-01'
              AND `ai_key` = ''
              AND `remark` = '" . self::REMARK . "'"
        );

        // 保留 ai_url/options 字段，避免回滚时误删已迁移的旧配置或用户后续保存的实时模型扩展配置。
    }

    private function insertMenu(string $name, string $code, string $path, string $component, string $icon, int $sort): void
    {
        $this->execute(
            "INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT `id`, '{$name}', '{$code}', '', 2, '{$path}', '{$component}', NULL, '{$icon}', {$sort}, '', 2, 2, 2, 2, 2, 0, NULL, 1, '" . self::REMARK . "', 1, 1, NOW(), NOW(), NULL
            FROM `sa_system_menu`
            WHERE `code` = 'SaiManage'
              AND `delete_time` IS NULL
              AND NOT EXISTS (SELECT 1 FROM `sa_system_menu` WHERE `code` = '{$code}' AND `delete_time` IS NULL)
            LIMIT 1"
        );
    }

    private function insertPermission(string $parentCode, string $name, string $slug): void
    {
        $this->execute(
            "INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT `id`, '{$name}', '', '{$slug}', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, '" . self::REMARK . "', 1, 1, NOW(), NOW(), NULL
            FROM `sa_system_menu`
            WHERE `code` = '{$parentCode}'
              AND `delete_time` IS NULL
              AND NOT EXISTS (SELECT 1 FROM `sa_system_menu` WHERE `slug` = '{$slug}' AND `delete_time` IS NULL)
            LIMIT 1"
        );
    }
}
