<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddCommunityCommentAuditOperator extends AbstractMigration
{
    public function up(): void
    {
        $table = $this->table('sa_community_comment');
        if (!$table->hasColumn('audit_remark')) {
            $table->addColumn('audit_remark', 'string', [
                'limit' => 500,
                'default' => '',
                'comment' => '审核备注',
                'after' => 'audit_status',
            ]);
        }
        if (!$table->hasColumn('audit_by')) {
            $table->addColumn('audit_by', 'integer', [
                'null' => true,
                'comment' => '审核人',
                'after' => 'audit_remark',
            ]);
        }
        if (!$table->hasColumn('audit_time')) {
            $table->addColumn('audit_time', 'datetime', [
                'null' => true,
                'comment' => '审核时间',
                'after' => 'audit_by',
            ]);
        }
        $table->update();
    }

    public function down(): void
    {
        $table = $this->table('sa_community_comment');
        foreach (['audit_time', 'audit_by', 'audit_remark'] as $column) {
            if ($table->hasColumn($column)) {
                $table->removeColumn($column);
            }
        }
        $table->update();
    }
}
