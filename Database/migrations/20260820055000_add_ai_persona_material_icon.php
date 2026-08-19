<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddAiPersonaMaterialIcon extends AbstractMigration
{
    public function up(): void
    {
        if (!$this->hasTable('sa_ai_persona')) {
            return;
        }

        $table = $this->table('sa_ai_persona');
        if (!$table->hasColumn('icon')) {
            $table->addColumn('icon', 'string', [
                'limit' => 64,
                'default' => '',
                'null' => false,
                'comment' => '首页卡片 Material 图标，对应 Flutter Icons 名称',
                'after' => 'code',
            ])->update();
        }

        $defaults = [
            'doctor' => 'smart_toy_rounded',
            'ai_doctor' => 'medical_services_rounded',
            'patient' => 'healing_rounded',
            'companion' => 'volunteer_activism_rounded',
        ];
        foreach ($defaults as $code => $icon) {
            $this->execute(
                'UPDATE `sa_ai_persona`
                 SET `icon` = ' . $this->q($icon) . '
                 WHERE `code` = ' . $this->q($code) . "
                   AND (`icon` = '' OR `icon` IS NULL)"
            );
        }
        $this->execute(
            "UPDATE `sa_ai_persona`
             SET `icon` = 'volunteer_activism_rounded'
             WHERE (`icon` = '' OR `icon` IS NULL)"
        );
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_ai_persona')) {
            return;
        }

        $table = $this->table('sa_ai_persona');
        if ($table->hasColumn('icon')) {
            $table->removeColumn('icon')->update();
        }
    }

    private function q(string $value): string
    {
        return $this->getAdapter()->getConnection()->quote($value);
    }
}
