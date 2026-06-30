<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedHelpSensitiveWordRules extends AbstractMigration
{
    private const TABLE = 'sa_sensitive_word_rule';
    private const REMARK = '系统预设敏感词';

    public function up(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        foreach ($this->rules() as $rule) {
            $this->insertRuleIfMissing($rule);
        }
    }

    public function down(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        $remark = $this->quote(self::REMARK);
        $this->execute("DELETE FROM `" . self::TABLE . "` WHERE `remark` LIKE '{$remark}%' AND `delete_time` IS NULL");
    }

    private function rules(): array
    {
        return [
            ['all', '自杀', 'contains', 'review', '', 3, '自伤危机表达，进入人工审核'],
            ['all', '轻生', 'contains', 'review', '', 3, '自伤危机表达，进入人工审核'],
            ['all', '割腕', 'contains', 'review', '', 3, '自伤危机表达，进入人工审核'],
            ['all', 'suicide', 'contains', 'review', '', 3, 'Self-harm crisis wording, send to review'],
            ['all', 'kill myself', 'contains', 'review', '', 3, 'Self-harm crisis wording, send to review'],
            ['all', 'self harm', 'contains', 'review', '', 3, 'Self-harm crisis wording, send to review'],
            ['all', 'self-harm', 'contains', 'review', '', 3, 'Self-harm crisis wording, send to review'],
            ['all', 'overdose', 'contains', 'review', '', 3, 'Self-harm or medication abuse wording, send to review'],

            ['all', '代开发票', 'contains', 'reject', '', 3, '欺诈或非法交易，直接拒绝'],
            ['all', '裸贷', 'contains', 'reject', '', 3, '高风险金融诱导，直接拒绝'],
            ['all', '买卖账号', 'contains', 'reject', '', 2, '账号交易风险，直接拒绝'],
            ['all', 'fake invoice', 'contains', 'reject', '', 3, 'Fraud wording, reject directly'],
            ['all', 'sell account', 'contains', 'reject', '', 2, 'Account trading risk, reject directly'],
            ['all', 'nude loan', 'contains', 'reject', '', 3, 'High-risk loan abuse wording, reject directly'],

            ['all', '傻逼', 'contains', 'replace', '***', 2, '辱骂内容，替换展示'],
            ['all', 'fuck', 'contains', 'replace', '***', 2, 'Profanity, replace before saving'],

            ['community', '加微信', 'contains', 'replace', '[联系方式]', 1, '社区引流联系方式，替换展示'],
            ['community', '私加我', 'contains', 'replace', '[联系方式]', 1, '社区引流联系方式，替换展示'],
            ['community', 'contact me on telegram', 'contains', 'replace', '[contact]', 1, 'Community off-platform contact, replace before saving'],
            ['community', 'dm me', 'contains', 'replace', '[contact]', 1, 'Community off-platform contact, replace before saving'],
        ];
    }

    private function insertRuleIfMissing(array $rule): void
    {
        [$scene, $word, $matchType, $action, $replacement, $riskLevel, $extraRemark] = $rule;
        $scene = $this->quote((string) $scene);
        $word = $this->quote((string) $word);
        $matchType = $this->quote((string) $matchType);
        $action = $this->quote((string) $action);
        $replacement = $this->quote((string) $replacement);
        $extraRemark = $this->quote((string) $extraRemark);
        $remark = $this->quote(self::REMARK);
        $riskLevel = (int) $riskLevel;

        $this->execute(
            "INSERT INTO `" . self::TABLE . "`
                (`scene`, `word`, `match_type`, `action`, `replacement`, `risk_level`, `hit_count`, `remark`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT '{$scene}', '{$word}', '{$matchType}', '{$action}', '{$replacement}', {$riskLevel}, 0, '{$remark}', 1, 1, 1, NOW(), NOW(), NULL
             WHERE NOT EXISTS (
                SELECT 1
                  FROM `" . self::TABLE . "`
                 WHERE `scene` = '{$scene}'
                   AND `word` = '{$word}'
                   AND `match_type` = '{$matchType}'
                   AND `delete_time` IS NULL
             )"
        );

        $this->execute(
            "UPDATE `" . self::TABLE . "`
                SET `remark` = CONCAT(`remark`, CASE WHEN `remark` = '' THEN '' ELSE '；' END, '{$extraRemark}')
              WHERE `scene` = '{$scene}'
                AND `word` = '{$word}'
                AND `match_type` = '{$matchType}'
                AND `remark` = '{$remark}'
                AND `delete_time` IS NULL"
        );
    }

    private function quote(string $value): string
    {
        return str_replace("'", "''", $value);
    }
}
