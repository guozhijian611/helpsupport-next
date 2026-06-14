<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SetCommunityCommentPendingDefault extends AbstractMigration
{
    public function up(): void
    {
        $this->execute(
            "ALTER TABLE `sa_community_comment`
            MODIFY `audit_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '审核状态 0待审核 1已通过 2已拒绝'"
        );
    }

    public function down(): void
    {
        $this->execute(
            "ALTER TABLE `sa_community_comment`
            MODIFY `audit_status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '审核状态 0待审核 1已通过 2已拒绝'"
        );
    }
}
