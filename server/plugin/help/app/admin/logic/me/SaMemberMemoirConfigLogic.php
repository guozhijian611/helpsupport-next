<?php

namespace plugin\help\app\admin\logic\me;

use plugin\help\app\model\me\SaMemberMemoirConfig;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

/**
 * 回忆录配置逻辑层
 */
class SaMemberMemoirConfigLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberMemoirConfig();
        $this->orderField = 'sort';
        $this->orderType = 'ASC';
    }

    public function add(array $data): mixed
    {
        return parent::add($this->normalizeFields($data));
    }

    public function edit($id, array $data): mixed
    {
        return parent::edit($id, $this->normalizeFields($data));
    }

    public function generate(int $configId, int $memberId = 0, string $sourceMonth = ''): array
    {
        if ($configId <= 0) {
            throw new ApiException('请选择回忆录配置');
        }

        $config = Db::table('sa_member_memoir_config')
            ->where('id', $configId)
            ->whereNull('delete_time')
            ->find();
        if (!$config) {
            throw new ApiException('回忆录配置不存在');
        }
        if ((int) ($config['status'] ?? 0) !== 1) {
            throw new ApiException('只能使用启用状态的回忆录配置生成');
        }

        $sourceMonth = $this->normalizeSourceMonth($sourceMonth);
        [$startDate, $endDate] = $this->periodRange($config, $sourceMonth);
        $memberIds = $this->sourceMemberIds($config, $startDate, $endDate, $memberId);
        $adminId = $this->currentAdminId();

        $created = 0;
        $updated = 0;
        $skipped = 0;
        $ids = [];

        foreach ($memberIds as $targetMemberId) {
            $journals = $this->journalRows($targetMemberId, $startDate, $endDate);
            $tasks = $this->taskRows($targetMemberId, $startDate, $endDate);
            if (!$this->canGenerate($config, $journals, $tasks)) {
                $skipped++;
                continue;
            }

            $result = $this->saveGeneratedMemoir(
                $config,
                $targetMemberId,
                $sourceMonth,
                $journals,
                $tasks,
                $adminId
            );
            $ids[] = $result['id'];
            if ($result['created']) {
                $created++;
            } else {
                $updated++;
            }
        }

        return [
            'source_month' => $sourceMonth,
            'period_start' => $startDate,
            'period_end' => $endDate,
            'member_count' => count($memberIds),
            'created' => $created,
            'updated' => $updated,
            'skipped' => $skipped,
            'memoir_ids' => $ids,
        ];
    }

    private function normalizeFields(array $data): array
    {
        foreach (['min_journal_count' => 3, 'start_day' => 1, 'sort' => 100, 'status' => 1] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        return $data;
    }

    private function normalizeSourceMonth(string $sourceMonth): string
    {
        $sourceMonth = trim($sourceMonth);
        if ($sourceMonth === '') {
            return date('Y-m');
        }
        if (!preg_match('/^\d{4}-\d{2}$/', $sourceMonth)) {
            throw new ApiException('来源月份格式必须为YYYY-MM');
        }

        return $sourceMonth;
    }

    private function periodRange(array $config, string $sourceMonth): array
    {
        $cycle = (string) ($config['generation_cycle'] ?? 'monthly');
        $base = new \DateTimeImmutable($sourceMonth . '-01');
        $startDay = max(1, min((int) ($config['start_day'] ?? 1), (int) $base->format('t')));
        $start = $base->setDate((int) $base->format('Y'), (int) $base->format('m'), $startDay);

        if ($cycle === 'weekly') {
            $end = $start->modify('+6 days');
        } elseif ($cycle === 'quarterly') {
            $end = $start->modify('+3 months')->modify('-1 day');
        } else {
            $end = $start->modify('+1 month')->modify('-1 day');
        }

        return [$start->format('Y-m-d'), $end->format('Y-m-d')];
    }

    private function sourceMemberIds(array $config, string $startDate, string $endDate, int $memberId): array
    {
        if ($memberId > 0) {
            return [$memberId];
        }

        $sourceType = $this->sourceType($config);
        $ids = [];
        if (in_array($sourceType, ['journal', 'mixed'], true)) {
            $ids = array_merge($ids, Db::table('sa_member_journal')
                ->where('entry_date', '>=', $startDate)
                ->where('entry_date', '<=', $endDate)
                ->where('status', 1)
                ->whereNull('delete_time')
                ->distinct(true)
                ->column('member_id'));
        }
        if (in_array($sourceType, ['task', 'mixed'], true)) {
            $ids = array_merge($ids, Db::table('sa_daily_task')
                ->where('task_date', '>=', $startDate)
                ->where('task_date', '<=', $endDate)
                ->where('status', 1)
                ->whereNull('delete_time')
                ->distinct(true)
                ->column('member_id'));
        }

        $ids = array_map('intval', $ids);
        $ids = array_values(array_unique(array_filter($ids, fn (int $id): bool => $id > 0)));
        sort($ids);

        return $ids;
    }

    private function journalRows(int $memberId, string $startDate, string $endDate): array
    {
        return Db::table('sa_member_journal')
            ->where('member_id', $memberId)
            ->where('entry_date', '>=', $startDate)
            ->where('entry_date', '<=', $endDate)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->field('entry_date, title, content, mood_score')
            ->order('entry_date', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();
    }

    private function taskRows(int $memberId, string $startDate, string $endDate): array
    {
        return Db::table('sa_daily_task')
            ->where('member_id', $memberId)
            ->where('task_date', '>=', $startDate)
            ->where('task_date', '<=', $endDate)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->field('task_date, title, task_type, completed_time')
            ->order('task_date', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();
    }

    private function canGenerate(array $config, array $journals, array $tasks): bool
    {
        $sourceType = $this->sourceType($config);
        if ($sourceType === 'task') {
            return count($tasks) > 0;
        }

        return count($journals) >= max(0, (int) ($config['min_journal_count'] ?? 0));
    }

    private function saveGeneratedMemoir(
        array $config,
        int $memberId,
        string $sourceMonth,
        array $journals,
        array $tasks,
        ?int $adminId
    ): array {
        $rank = $this->grantLevelRank((int) $config['id'], $sourceMonth);
        $now = date('Y-m-d H:i:s');
        $payload = [
            'member_id' => $memberId,
            'grant_level_id' => (int) $config['id'],
            'grant_level_rank' => $rank,
            'grant_level_name' => (string) $config['name'],
            'title' => $this->memoirTitle($config, $sourceMonth),
            'description' => $this->memoirDescription($journals, $tasks),
            'source_month' => $sourceMonth,
            'journal_count' => count($journals),
            'status' => 1,
            'remark' => '由回忆录配置 ' . (string) $config['code'] . ' 自动生成',
            'updated_by' => $adminId,
            'update_time' => $now,
            'delete_time' => null,
        ];

        $existing = Db::table('sa_member_memoir')
            ->where('member_id', $memberId)
            ->where('grant_level_rank', $rank)
            ->find();

        if ($existing) {
            Db::table('sa_member_memoir')
                ->where('id', (int) $existing['id'])
                ->update($payload);

            return ['id' => (int) $existing['id'], 'created' => false];
        }

        $payload['created_by'] = $adminId;
        $payload['create_time'] = $now;
        $id = (int) Db::table('sa_member_memoir')->insertGetId($payload);

        return ['id' => $id, 'created' => true];
    }

    private function memoirTitle(array $config, string $sourceMonth): string
    {
        return $sourceMonth . ' ' . (string) $config['name'];
    }

    private function memoirDescription(array $journals, array $tasks): string
    {
        $parts = [];
        if ($journals) {
            $parts[] = '本周期共记录 ' . count($journals) . ' 篇康复日记';
            $scores = array_values(array_filter(
                array_map(fn (array $row): int => (int) ($row['mood_score'] ?? 0), $journals),
                fn (int $score): bool => $score > 0
            ));
            if ($scores) {
                $parts[] = '平均心情分 ' . round(array_sum($scores) / count($scores), 1);
            }
            $titles = array_values(array_filter(array_map(
                fn (array $row): string => trim((string) ($row['title'] ?? '')),
                array_slice($journals, 0, 5)
            )));
            if ($titles) {
                $parts[] = '重点记录：' . implode('、', $titles);
            }
        }
        if ($tasks) {
            $parts[] = '完成 ' . count($tasks) . ' 个康复任务';
        }
        if (!$parts) {
            $parts[] = '本周期已有康复记录，可在 App 中查看回忆录。';
        }

        return $this->limitText(implode('；', $parts), 500);
    }

    private function sourceType(array $config): string
    {
        $sourceType = (string) ($config['source_type'] ?? 'journal');

        return in_array($sourceType, ['journal', 'task', 'mixed'], true) ? $sourceType : 'journal';
    }

    private function grantLevelRank(int $configId, string $sourceMonth): int
    {
        return ((int) str_replace('-', '', $sourceMonth) * 1000) + ($configId % 1000);
    }

    private function currentAdminId(): ?int
    {
        if (!function_exists('getCurrentInfo')) {
            return null;
        }
        $info = getCurrentInfo();

        return isset($info['id']) ? (int) $info['id'] : null;
    }

    private function limitText(string $text, int $length): string
    {
        if (function_exists('mb_substr')) {
            return mb_substr($text, 0, $length);
        }

        return substr($text, 0, $length);
    }
}
