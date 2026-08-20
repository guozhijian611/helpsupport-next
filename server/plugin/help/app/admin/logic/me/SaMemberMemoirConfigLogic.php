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
    private const DEFAULT_MATERIAL_SOURCES = ['journal', 'task', 'material_history', 'material_collect', 'private_material'];
    private const LEVEL_TRIGGER_MODES = ['level_up', 'level_interval'];

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
            $level = $this->memberLevelSnapshot($targetMemberId);
            if (!$this->canTriggerForMember($config, $level)) {
                $skipped++;
                continue;
            }

            $materials = $this->sourceMaterials($config, $targetMemberId, $startDate, $endDate);
            if (!$this->canGenerate($config, $materials)) {
                $skipped++;
                continue;
            }

            $result = $this->saveGeneratedMemoir(
                $config,
                $targetMemberId,
                $sourceMonth,
                $materials,
                $level,
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

    public function generationOpportunity(array $config, int $memberId, string $sourceMonth = ''): array
    {
        if ($memberId <= 0) {
            return [
                'can_generate' => false,
                'reason' => '会员ID无效',
                'target_level' => null,
                'existing_memoir_id' => 0,
                'material_count' => 0,
            ];
        }
        if ((int) ($config['status'] ?? 0) !== 1) {
            return [
                'can_generate' => false,
                'reason' => '配置未启用',
                'target_level' => null,
                'existing_memoir_id' => 0,
                'material_count' => 0,
            ];
        }

        $sourceMonth = $this->normalizeSourceMonth($sourceMonth);
        [$startDate, $endDate] = $this->periodRange($config, $sourceMonth);
        $level = $this->memberLevelSnapshot($memberId);
        if (!$this->canTriggerForMember($config, $level)) {
            return [
                'can_generate' => false,
                'reason' => $this->isLevelTrigger($config) ? '当前会员等级未达到生成间隔' : '未达到生成条件',
                'target_level' => $level ?: null,
                'existing_memoir_id' => 0,
                'material_count' => 0,
            ];
        }

        $rank = $this->grantLevelRank($config, (int) ($config['id'] ?? 0), $sourceMonth, $level);
        $existing = $this->findExistingMemoir($config, $memberId, $rank);
        if ($existing) {
            return [
                'can_generate' => false,
                'reason' => $this->isLevelTrigger($config) ? '当前等级回忆录已生成' : '本周期回忆录已生成',
                'target_level' => $level ?: null,
                'existing_memoir_id' => (int) ($existing['id'] ?? 0),
                'material_count' => 0,
            ];
        }

        $materials = $this->sourceMaterials($config, $memberId, $startDate, $endDate);
        if (!$this->canGenerate($config, $materials)) {
            return [
                'can_generate' => false,
                'reason' => '可用素材数量未达到配置要求',
                'target_level' => $level ?: null,
                'existing_memoir_id' => 0,
                'material_count' => $this->materialCount($materials),
            ];
        }

        return [
            'can_generate' => true,
            'reason' => '',
            'target_level' => $level ?: null,
            'existing_memoir_id' => 0,
            'material_count' => $this->materialCount($materials),
        ];
    }

    public function presentConfig(array $config, int $memberId, string $sourceMonth = ''): array
    {
        $config['material_sources'] = $this->materialSources($config);

        return array_merge($config, $this->generationOpportunity($config, $memberId, $sourceMonth));
    }

    /**
     * @param array<int, array<string, mixed>> $rows
     * @return array<int, array<string, mixed>>
     */
    public function presentMemoirs(array $rows): array
    {
        $configIds = [];
        foreach ($rows as $row) {
            $configId = (int) ($row['config_id'] ?? 0);
            if ($configId > 0) {
                $configIds[$configId] = $configId;
            }
        }

        $configs = [];
        if ($configIds !== []) {
            $list = Db::table('sa_member_memoir_config')
                ->whereIn('id', array_values($configIds))
                ->select()
                ->toArray();
            foreach ($list as $config) {
                $configs[(int) ($config['id'] ?? 0)] = $config;
            }
        }

        return array_map(function (array $row) use ($configs): array {
            $configId = (int) ($row['config_id'] ?? 0);

            return $this->presentMemoir($row, $configs[$configId] ?? []);
        }, $rows);
    }

    public function presentMemoir(array $memoir, array $config = []): array
    {
        $configId = (int) ($memoir['config_id'] ?? 0);
        if ($config === [] && $configId > 0) {
            $config = Db::table('sa_member_memoir_config')
                ->where('id', $configId)
                ->find() ?: [];
        }

        $memoir['config_id'] = $configId;
        $memoir['config_name'] = (string) ($config['name'] ?? '');
        $materials = $this->decodeMaterials($memoir['source_materials'] ?? null);
        $memoir['source_materials'] = $materials;
        if ($this->isAutoGenerated($memoir)) {
            if ($config !== []) {
                $memoir['title'] = $this->memoirTitle(
                    $config,
                    (string) ($memoir['source_month'] ?? ''),
                    ['name' => (string) ($memoir['grant_level_name'] ?? '')]
                );
            }
            if ($this->materialCount($materials) > 0) {
                $memoir['description'] = $this->memoirDescription($materials);
            }
        }

        return $memoir;
    }

    private function normalizeFields(array $data): array
    {
        foreach ([
            'trigger_mode' => 'level_up',
            'level_step' => 1,
            'generation_cycle' => 'monthly',
            'source_type' => 'mixed',
            'min_journal_count' => 0,
            'min_material_count' => 0,
            'start_day' => 1,
            'sort' => 100,
            'status' => 1,
        ] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }
        $data['material_sources'] = $this->encodeMaterialSources($data['material_sources'] ?? null);

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

        if ($this->isLevelTrigger($config)) {
            return array_map('intval', Db::table('sa_member')
                ->where('member_level_id', '>', 0)
                ->where('status', 1)
                ->whereNull('delete_time')
                ->distinct(true)
                ->column('id'));
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
            ->field('id, entry_date, summary, word_count, mood_score')
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
            ->field('id, task_date, title, task_type, completed_time')
            ->order('task_date', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();
    }

    private function materialHistoryRows(int $memberId, string $startDate, string $endDate): array
    {
        return Db::table('sa_member_content_history')
            ->where('member_id', $memberId)
            ->where('content_type', 'material')
            ->where('viewed_at', '>=', $startDate . ' 00:00:00')
            ->where('viewed_at', '<=', $endDate . ' 23:59:59')
            ->whereNull('delete_time')
            ->field('id, content_id, title, author_name, route, progress, duration_seconds, viewed_at')
            ->order('viewed_at', 'desc')
            ->order('id', 'desc')
            ->limit(10)
            ->select()
            ->toArray();
    }

    private function materialCollectRows(int $memberId): array
    {
        return Db::table('sa_material_collect')
            ->alias('c')
            ->leftJoin('sa_content_material m', 'm.id = c.material_id AND m.delete_time IS NULL')
            ->where('c.member_id', $memberId)
            ->whereNull('c.delete_time')
            ->where('m.status', 1)
            ->field('c.id, c.material_id, c.create_time, m.title, m.material_type, m.media_type, m.cover_url, m.content_url')
            ->order('c.create_time', 'desc')
            ->order('c.id', 'desc')
            ->limit(10)
            ->select()
            ->toArray();
    }

    private function privateMaterialRows(int $memberId): array
    {
        return Db::table('sa_content_material')
            ->where('member_id', $memberId)
            ->where('material_type', 'private')
            ->where('status', 1)
            ->whereIn('audit_status', [1, 2])
            ->whereNull('delete_time')
            ->field('id, title, summary, media_type, cover_url, content_url, create_time')
            ->order('create_time', 'desc')
            ->order('id', 'desc')
            ->limit(10)
            ->select()
            ->toArray();
    }

    private function sourceMaterials(array $config, int $memberId, string $startDate, string $endDate): array
    {
        $sources = $this->materialSources($config);

        return [
            'journals' => in_array('journal', $sources, true) ? $this->journalRows($memberId, $startDate, $endDate) : [],
            'tasks' => in_array('task', $sources, true) ? $this->taskRows($memberId, $startDate, $endDate) : [],
            'material_history' => in_array('material_history', $sources, true) ? $this->materialHistoryRows($memberId, $startDate, $endDate) : [],
            'material_collect' => in_array('material_collect', $sources, true) ? $this->materialCollectRows($memberId) : [],
            'private_materials' => in_array('private_material', $sources, true) ? $this->privateMaterialRows($memberId) : [],
        ];
    }

    private function canGenerate(array $config, array $materials): bool
    {
        $journalCount = count($materials['journals'] ?? []);
        $materialCount = $this->materialCount($materials);
        $minJournals = max(0, (int) ($config['min_journal_count'] ?? 0));
        $minMaterials = max(0, (int) ($config['min_material_count'] ?? 0));
        if ($journalCount < $minJournals) {
            return false;
        }

        return $materialCount >= $minMaterials;
    }

    private function saveGeneratedMemoir(
        array $config,
        int $memberId,
        string $sourceMonth,
        array $materials,
        array $level,
        ?int $adminId
    ): array {
        $rank = $this->grantLevelRank($config, (int) $config['id'], $sourceMonth, $level);
        $now = date('Y-m-d H:i:s');
        $cover = $this->firstCover($materials);
        $payload = [
            'member_id' => $memberId,
            'config_id' => (int) ($config['id'] ?? 0),
            'grant_level_id' => (int) ($level['id'] ?? 0) ?: (int) $config['id'],
            'grant_level_rank' => $rank,
            'grant_level_name' => (string) ($level['name'] ?? '') ?: (string) $config['name'],
            'title' => $this->memoirTitle($config, $sourceMonth, $level),
            'description' => $this->memoirDescription($materials),
            'source_month' => $sourceMonth,
            'journal_count' => count($materials['journals'] ?? []),
            'material_count' => $this->materialCount($materials),
            'source_materials' => $this->encodeJson($this->sourceMaterialsSnapshot($materials)),
            'status' => 1,
            'remark' => '由回忆录配置 ' . (string) $config['code'] . ' 自动生成',
            'updated_by' => $adminId,
            'update_time' => $now,
            'delete_time' => null,
        ];
        if ($cover !== '') {
            $payload['cover'] = $cover;
        }

        $existing = $this->findExistingMemoir($config, $memberId, $rank, true);

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

    private function memoirTitle(array $config, string $sourceMonth, array $level): string
    {
        $configName = trim((string) ($config['name'] ?? ''));
        $levelName = trim((string) ($level['name'] ?? ''));
        if ($this->isLevelTrigger($config) && $levelName !== '') {
            if ($configName !== '') {
                return $sourceMonth . ' ' . $levelName . ' · ' . $configName;
            }

            return $sourceMonth . ' ' . $levelName . '回忆录';
        }

        return $sourceMonth . ' ' . ($configName !== '' ? $configName : '回忆录');
    }

    private function memoirDescription(array $materials): string
    {
        $parts = [];
        $journals = $materials['journals'] ?? [];
        $tasks = $materials['tasks'] ?? [];
        $history = $materials['material_history'] ?? [];
        $collects = $materials['material_collect'] ?? [];
        $privateMaterials = $materials['private_materials'] ?? [];
        if ($journals) {
            $parts[] = '本周期共记录 ' . count($journals) . ' 篇康复日记';
            $scores = array_values(array_filter(
                array_map(fn (array $row): int => (int) ($row['mood_score'] ?? 0), $journals),
                fn (int $score): bool => $score > 0
            ));
            if ($scores) {
                $parts[] = '平均心情分 ' . round(array_sum($scores) / count($scores), 1);
            }
            $summaries = array_values(array_filter(array_map(
                fn (array $row): string => trim((string) ($row['summary'] ?? '')),
                array_slice($journals, 0, 5)
            )));
            if ($summaries) {
                $uniqueSummaries = array_values(array_unique($summaries));
                $parts[] = '日记摘要：' . implode('、', $uniqueSummaries);
            }
        }
        if ($tasks) {
            $parts[] = '完成 ' . count($tasks) . ' 个康复任务';
        }
        if ($history) {
            $parts[] = '学习 ' . count($history) . ' 条素材';
        }
        if ($collects) {
            $parts[] = '收藏 ' . count($collects) . ' 条素材';
        }
        if ($privateMaterials) {
            $parts[] = '沉淀 ' . count($privateMaterials) . ' 条私人素材';
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

    private function triggerMode(array $config): string
    {
        $mode = (string) ($config['trigger_mode'] ?? 'level_up');

        return in_array($mode, ['level_up', 'level_interval', 'cycle', 'manual'], true) ? $mode : 'level_up';
    }

    private function isLevelTrigger(array $config): bool
    {
        return in_array($this->triggerMode($config), self::LEVEL_TRIGGER_MODES, true);
    }

    private function grantLevelRank(array $config, int $configId, string $sourceMonth, array $level): int
    {
        if ($this->isLevelTrigger($config)) {
            return max(0, (int) ($level['rank'] ?? 0));
        }

        return ((int) str_replace('-', '', $sourceMonth) * 1000) + ($configId % 1000);
    }

    private function memberLevelSnapshot(int $memberId): array
    {
        $member = Db::table('sa_member')
            ->where('id', $memberId)
            ->whereNull('delete_time')
            ->field('id, member_level_id, points_balance')
            ->find();
        $levelId = (int) ($member['member_level_id'] ?? 0);
        if ($levelId <= 0) {
            return [];
        }

        $levels = Db::table('sa_member_level')
            ->whereNull('delete_time')
            ->where('status', 1)
            ->field('id, level_name, min_points, sort')
            ->order('min_points', 'asc')
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();
        foreach ($levels as $index => $level) {
            if ((int) ($level['id'] ?? 0) === $levelId) {
                return [
                    'id' => $levelId,
                    'rank' => $index + 1,
                    'name' => (string) ($level['level_name'] ?? ''),
                    'points_balance' => (int) ($member['points_balance'] ?? 0),
                ];
            }
        }

        $level = Db::table('sa_member_level')
            ->where('id', $levelId)
            ->whereNull('delete_time')
            ->field('id, level_name')
            ->find();

        return [
            'id' => $levelId,
            'rank' => $levelId,
            'name' => (string) ($level['level_name'] ?? ('等级 ' . $levelId)),
            'points_balance' => (int) ($member['points_balance'] ?? 0),
        ];
    }

    private function canTriggerForMember(array $config, array $level): bool
    {
        if (!$this->isLevelTrigger($config)) {
            return true;
        }
        $rank = (int) ($level['rank'] ?? 0);
        if ($rank <= 0) {
            return false;
        }
        $step = $this->triggerMode($config) === 'level_up' ? 1 : max(1, (int) ($config['level_step'] ?? 1));
        if ($step > 1 && $rank % $step !== 0) {
            return false;
        }

        return true;
    }

    private function materialSources(array $config): array
    {
        $value = $config['material_sources'] ?? null;
        if (is_string($value) && trim($value) !== '') {
            $decoded = json_decode($value, true);
            if (is_array($decoded)) {
                $value = $decoded;
            }
        }
        if (!is_array($value) || $value === []) {
            return match ($this->sourceType($config)) {
                'journal' => ['journal'],
                'task' => ['task'],
                default => self::DEFAULT_MATERIAL_SOURCES,
            };
        }

        $allowed = self::DEFAULT_MATERIAL_SOURCES;
        $sources = array_values(array_unique(array_filter(array_map(
            static fn (mixed $item): string => trim((string) $item),
            $value
        ), static fn (string $item): bool => in_array($item, $allowed, true))));

        return $sources !== [] ? $sources : self::DEFAULT_MATERIAL_SOURCES;
    }

    private function encodeMaterialSources(mixed $value): string
    {
        if (is_string($value) && trim($value) !== '') {
            $decoded = json_decode($value, true);
            if (is_array($decoded)) {
                return $this->encodeJson($this->materialSources(['material_sources' => $decoded, 'source_type' => 'mixed']));
            }
        }
        if (is_array($value)) {
            return $this->encodeJson($this->materialSources(['material_sources' => $value, 'source_type' => 'mixed']));
        }

        return $this->encodeJson(self::DEFAULT_MATERIAL_SOURCES);
    }

    private function materialCount(array $materials): int
    {
        return count($materials['journals'] ?? [])
            + count($materials['tasks'] ?? [])
            + count($materials['material_history'] ?? [])
            + count($materials['material_collect'] ?? [])
            + count($materials['private_materials'] ?? []);
    }

    private function sourceMaterialsSnapshot(array $materials): array
    {
        $journals = [];
        foreach ($this->mapRows($materials['journals'] ?? [], ['id', 'entry_date', 'summary', 'word_count', 'mood_score']) as $row) {
            $date = trim((string) ($row['entry_date'] ?? ''));
            $summary = trim((string) ($row['summary'] ?? ''));
            if ($date !== '' && $summary !== '') {
                $row['title'] = $date . ' · ' . $summary;
            } else {
                $row['title'] = $date !== '' ? $date : $summary;
            }
            $journals[] = $row;
        }

        return [
            'journals' => $journals,
            'tasks' => $this->mapRows($materials['tasks'] ?? [], ['id', 'task_date', 'title', 'task_type', 'completed_time']),
            'material_history' => $this->mapRows($materials['material_history'] ?? [], ['id', 'content_id', 'title', 'author_name', 'route', 'progress', 'viewed_at']),
            'material_collect' => $this->mapRows($materials['material_collect'] ?? [], ['id', 'material_id', 'title', 'material_type', 'media_type', 'cover_url', 'content_url']),
            'private_materials' => $this->mapRows($materials['private_materials'] ?? [], ['id', 'title', 'summary', 'media_type', 'cover_url', 'content_url']),
        ];
    }

    /**
     * @return array<string, mixed>|null
     */
    private function findExistingMemoir(array $config, int $memberId, int $rank, bool $includeDeleted = false): ?array
    {
        $configId = (int) ($config['id'] ?? 0);
        $code = trim((string) ($config['code'] ?? ''));
        $query = Db::table('sa_member_memoir')
            ->where('member_id', $memberId)
            ->where('grant_level_rank', $rank)
            ->field('id, config_id, remark');
        if (!$includeDeleted) {
            $query->whereNull('delete_time');
        }
        $rows = $query->select()->toArray();
        foreach ($rows as $row) {
            if ((int) ($row['config_id'] ?? 0) === $configId) {
                return $row;
            }
        }
        if ($code === '') {
            return null;
        }
        foreach ($rows as $row) {
            $rowConfigId = (int) ($row['config_id'] ?? 0);
            $remark = (string) ($row['remark'] ?? '');
            if ($rowConfigId === 0 && str_contains($remark, $code)) {
                return $row;
            }
        }

        return null;
    }

    /**
     * @return array<string, array<int, array<string, mixed>>>
     */
    private function decodeMaterials(mixed $value): array
    {
        if (is_array($value)) {
            $decoded = $value;
        } elseif (is_string($value) && trim($value) !== '') {
            $decoded = json_decode($value, true);
            $decoded = is_array($decoded) ? $decoded : [];
        } else {
            $decoded = [];
        }

        $result = [];
        foreach (['journals', 'tasks', 'material_history', 'material_collect', 'private_materials'] as $group) {
            $rows = $decoded[$group] ?? [];
            $result[$group] = [];
            if (!is_array($rows)) {
                continue;
            }
            foreach ($rows as $row) {
                if (is_array($row)) {
                    $result[$group][] = $row;
                }
            }
        }
        foreach ($result['journals'] as $index => $row) {
            if (trim((string) ($row['title'] ?? '')) !== '') {
                continue;
            }
            $date = trim((string) ($row['entry_date'] ?? ''));
            $summary = trim((string) ($row['summary'] ?? ''));
            if ($date !== '' && $summary !== '') {
                $result['journals'][$index]['title'] = $date . ' · ' . $summary;
            } elseif ($date !== '') {
                $result['journals'][$index]['title'] = $date;
            } elseif ($summary !== '') {
                $result['journals'][$index]['title'] = $summary;
            }
        }

        return $result;
    }

    private function isAutoGenerated(array $memoir): bool
    {
        return str_starts_with(trim((string) ($memoir['remark'] ?? '')), '由回忆录配置');
    }

    private function mapRows(array $rows, array $fields): array
    {
        return array_map(static function (array $row) use ($fields): array {
            $next = [];
            foreach ($fields as $field) {
                $next[$field] = $row[$field] ?? null;
            }

            return $next;
        }, $rows);
    }

    private function firstCover(array $materials): string
    {
        foreach (['material_collect', 'private_materials'] as $group) {
            foreach ($materials[$group] ?? [] as $row) {
                $cover = trim((string) ($row['cover_url'] ?? ''));
                if ($cover !== '') {
                    return $cover;
                }
            }
        }

        return '';
    }

    private function encodeJson(array $value): string
    {
        return json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?: '[]';
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
