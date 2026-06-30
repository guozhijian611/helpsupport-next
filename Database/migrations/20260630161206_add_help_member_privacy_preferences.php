<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpMemberPrivacyPreferences extends AbstractMigration
{
    private const TABLE = 'sa_help_member_profile';

    public function up(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        $table = $this->table(self::TABLE);
        $columns = [
            'community_visibility' => [
                'type' => 'string',
                'options' => [
                    'limit' => 20,
                    'default' => 'mutual',
                    'null' => false,
                    'comment' => '社区可见范围 private/mutual/public',
                    'after' => 'onboarding_version',
                ],
            ],
            'privacy_anonymous_posting' => [
                'type' => 'integer',
                'options' => [
                    'limit' => 1,
                    'default' => 1,
                    'null' => false,
                    'comment' => '默认匿名发言 1是 2否',
                    'after' => 'community_visibility',
                ],
            ],
            'privacy_hide_recovery_stage' => [
                'type' => 'integer',
                'options' => [
                    'limit' => 1,
                    'default' => 2,
                    'null' => false,
                    'comment' => '隐藏治疗阶段 1是 2否',
                    'after' => 'privacy_anonymous_posting',
                ],
            ],
            'privacy_show_following_list' => [
                'type' => 'integer',
                'options' => [
                    'limit' => 1,
                    'default' => 2,
                    'null' => false,
                    'comment' => '允许查看关注列表 1是 2否',
                    'after' => 'privacy_hide_recovery_stage',
                ],
            ],
            'privacy_show_signature' => [
                'type' => 'integer',
                'options' => [
                    'limit' => 1,
                    'default' => 1,
                    'null' => false,
                    'comment' => '展示个性签名 1是 2否',
                    'after' => 'privacy_show_following_list',
                ],
            ],
            'privacy_sync_diary_summary' => [
                'type' => 'integer',
                'options' => [
                    'limit' => 1,
                    'default' => 1,
                    'null' => false,
                    'comment' => '允许日记摘要参与进度面板 1是 2否',
                    'after' => 'privacy_show_signature',
                ],
            ],
            'privacy_auto_clear_attachments' => [
                'type' => 'integer',
                'options' => [
                    'limit' => 1,
                    'default' => 2,
                    'null' => false,
                    'comment' => '自动清理附件缓存 1是 2否',
                    'after' => 'privacy_sync_diary_summary',
                ],
            ],
            'privacy_confirm_before_export' => [
                'type' => 'integer',
                'options' => [
                    'limit' => 1,
                    'default' => 1,
                    'null' => false,
                    'comment' => '导出前二次确认 1是 2否',
                    'after' => 'privacy_auto_clear_attachments',
                ],
            ],
        ];

        foreach ($columns as $name => $definition) {
            if ($table->hasColumn($name)) {
                continue;
            }
            $table->addColumn($name, $definition['type'], $definition['options']);
        }

        if (!$table->hasIndexByName('idx_community_visibility')) {
            $table->addIndex(['community_visibility'], [
                'name' => 'idx_community_visibility',
            ]);
        }

        $table->update();
    }

    public function down(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        $table = $this->table(self::TABLE);
        if ($table->hasIndexByName('idx_community_visibility')) {
            $table->removeIndexByName('idx_community_visibility');
        }

        foreach ([
            'privacy_confirm_before_export',
            'privacy_auto_clear_attachments',
            'privacy_sync_diary_summary',
            'privacy_show_signature',
            'privacy_show_following_list',
            'privacy_hide_recovery_stage',
            'privacy_anonymous_posting',
            'community_visibility',
        ] as $column) {
            if ($table->hasColumn($column)) {
                $table->removeColumn($column);
            }
        }

        $table->update();
    }
}
