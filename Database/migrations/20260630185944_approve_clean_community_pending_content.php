<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class ApproveCleanCommunityPendingContent extends AbstractMigration
{
    private const AUTO_APPROVE_REMARK = '系统自动通过历史待审内容';

    public function up(): void
    {
        $this->approveCleanPendingRows('sa_community_post');
        $this->approveCleanPendingRows('sa_community_comment');
    }

    public function down(): void
    {
        $this->restoreAutoApprovedRows('sa_community_post');
        $this->restoreAutoApprovedRows('sa_community_comment');
    }

    private function approveCleanPendingRows(string $tableName): void
    {
        if (!$this->canUpdateAuditStatus($tableName)) {
            return;
        }

        $remark = addslashes(self::AUTO_APPROVE_REMARK);
        $this->execute(
            "UPDATE `{$tableName}`
                SET `audit_status` = 1,
                    `audit_remark` = '{$remark}',
                    `audit_time` = COALESCE(`audit_time`, NOW()),
                    `update_time` = NOW()
              WHERE `status` = 1
                AND `delete_time` IS NULL
                AND `audit_status` = 0
                AND COALESCE(`audit_remark`, '') = ''"
        );
    }

    private function restoreAutoApprovedRows(string $tableName): void
    {
        if (!$this->canUpdateAuditStatus($tableName)) {
            return;
        }

        $remark = addslashes(self::AUTO_APPROVE_REMARK);
        $this->execute(
            "UPDATE `{$tableName}`
                SET `audit_status` = 0,
                    `audit_remark` = '',
                    `audit_time` = NULL,
                    `update_time` = NOW()
              WHERE `status` = 1
                AND `delete_time` IS NULL
                AND `audit_status` = 1
                AND `audit_remark` = '{$remark}'"
        );
    }

    private function canUpdateAuditStatus(string $tableName): bool
    {
        if (!$this->hasTable($tableName)) {
            return false;
        }

        $table = $this->table($tableName);
        foreach (['audit_status', 'audit_remark', 'audit_time', 'status', 'delete_time'] as $column) {
            if (!$table->hasColumn($column)) {
                return false;
            }
        }

        return true;
    }
}
