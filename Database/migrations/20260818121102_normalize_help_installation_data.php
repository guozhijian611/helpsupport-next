<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

/**
 * 保留该版本号，避免已经执行过此迁移的环境出现迁移历史分叉。
 *
 * HelpSupport 的菜单名称、显示状态和业务/测试数据都属于安装实例数据，
 * 增量迁移不得对它们做规范化覆盖或清理。
 */
final class NormalizeHelpInstallationData extends AbstractMigration
{
    public function up(): void
    {
        // 故意留空：只保留迁移版本，不再修改菜单或删除任何数据。
    }

    public function down(): void
    {
        // 无数据库变更，无需回滚。
    }
}
