<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class UpdateCommunityCommentAiReviewStatus extends AbstractMigration
{
    public function up(): void
    {
        if (!$this->hasTable('sa_community_comment')) {
            return;
        }

        $table = $this->table('sa_community_comment');
        if (!$table->hasColumn('audit_status')) {
            return;
        }

        $this->execute(
            "ALTER TABLE `sa_community_comment`
            MODIFY `audit_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '审核状态 0待审核 1已通过 2已拒绝 3AI预审标记'"
        );
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_community_comment')) {
            return;
        }

        $table = $this->table('sa_community_comment');
        if (!$table->hasColumn('audit_status')) {
            return;
        }

        $this->execute(
            "ALTER TABLE `sa_community_comment`
            MODIFY `audit_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '审核状态 0待审核 1已通过 2已拒绝'"
        );
    }
}
