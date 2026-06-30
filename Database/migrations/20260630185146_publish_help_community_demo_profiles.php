<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class PublishHelpCommunityDemoProfiles extends AbstractMigration
{
    private const TABLE = 'sa_help_member_profile';
    private const DEMO_MEMBER_IDS = [
        986170008,
        986170021,
        986170022,
        986170023,
        986170024,
        986170025,
    ];

    public function up(): void
    {
        if (!$this->canUpdateVisibility()) {
            return;
        }

        $memberIds = implode(',', self::DEMO_MEMBER_IDS);
        $this->execute(
            "UPDATE `" . self::TABLE . "`
                SET `community_visibility` = 'public', `update_time` = NOW()
              WHERE `member_id` IN ($memberIds)
                AND `delete_time` IS NULL
                AND `community_visibility` <> 'public'"
        );
    }

    public function down(): void
    {
        if (!$this->canUpdateVisibility()) {
            return;
        }

        $memberIds = implode(',', self::DEMO_MEMBER_IDS);
        $this->execute(
            "UPDATE `" . self::TABLE . "`
                SET `community_visibility` = 'mutual', `update_time` = NOW()
              WHERE `member_id` IN ($memberIds)
                AND `delete_time` IS NULL
                AND `community_visibility` = 'public'"
        );
    }

    private function canUpdateVisibility(): bool
    {
        return $this->hasTable(self::TABLE)
            && $this->table(self::TABLE)->hasColumn('member_id')
            && $this->table(self::TABLE)->hasColumn('community_visibility');
    }
}
