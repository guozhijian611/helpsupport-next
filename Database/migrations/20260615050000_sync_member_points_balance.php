<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SyncMemberPointsBalance extends AbstractMigration
{
    public function up(): void
    {
        if (!$this->hasTable('sa_member') || !$this->hasTable('sa_member_point_log')) {
            return;
        }

        $this->execute(<<<'SQL'
UPDATE `sa_member` AS `m`
LEFT JOIN (
    SELECT `member_id`, COALESCE(SUM(`points`), 0) AS `balance`
    FROM `sa_member_point_log`
    WHERE `delete_time` IS NULL
    GROUP BY `member_id`
) AS `p` ON `p`.`member_id` = `m`.`id`
SET `m`.`points_balance` = COALESCE(`p`.`balance`, 0),
    `m`.`update_time` = NOW()
WHERE `m`.`delete_time` IS NULL
SQL);
    }

    public function down(): void
    {
        // 历史 points_balance 原值无法可靠还原；回滚时保留按流水修正后的余额。
    }
}
