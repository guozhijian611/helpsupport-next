<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddMaterialAuditOperator extends AbstractMigration
{
    public function up(): void
    {
        $table = $this->table('sa_content_material');
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
        $table = $this->table('sa_content_material');
        if ($table->hasColumn('audit_time')) {
            $table->removeColumn('audit_time');
        }
        if ($table->hasColumn('audit_by')) {
            $table->removeColumn('audit_by');
        }
        $table->update();
    }
}
