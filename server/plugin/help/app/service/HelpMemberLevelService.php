<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use think\facade\Db;

class HelpMemberLevelService
{
    public function enrichMember(array $member): array
    {
        $points = (int) ($member['points_balance'] ?? 0);
        $levels = $this->levels();
        $level = $this->matchLevel($levels, $points);
        $nextLevel = $this->nextLevel($level, $levels);
        $progress = $this->progress($level, $nextLevel, $points);

        $member['member_level_id'] = (int) ($level['id'] ?? ($member['member_level_id'] ?? 0));
        $member['member_level_name'] = (string) ($level['level_name'] ?? '');
        $member['member_level_code'] = (string) ($level['level_code'] ?? '');
        $member['member_level_icon'] = (string) ($level['level_icon'] ?? '');
        $member['member_level_min_points'] = (int) ($level['min_points'] ?? 0);
        $member['member_level_max_points'] = $level['max_points'] ?? null;
        $member['member_level'] = $this->publicLevel($level);
        $member['member_levels'] = array_map(fn (array $row): array => $this->publicLevel($row), $levels);
        $member['member_level_progress'] = $progress;

        return $member;
    }

    public function levelIdForPoints(int $points, int $fallbackId = 0): int
    {
        return (int) ($this->matchLevel($this->levels(), $points)['id'] ?? $fallbackId);
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function levels(): array
    {
        return Db::table('sa_member_level')
            ->where('status', 1)
            ->whereNull('delete_time')
            ->field('id, level_name, level_code, min_points, max_points, level_icon, privileges, sort')
            ->order('min_points', 'asc')
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();
    }

    /**
     * @param list<array<string, mixed>> $levels
     * @return array<string, mixed>
     */
    private function matchLevel(array $levels, int $points): array
    {
        $matched = [];
        foreach ($levels as $level) {
            $minPoints = (int) ($level['min_points'] ?? 0);
            $maxPoints = $level['max_points'] ?? null;
            if ($minPoints <= $points && ($maxPoints === null || $maxPoints === '' || (int) $maxPoints >= $points)) {
                $matched = $level;
            }
        }

        return $matched ?: ($levels[0] ?? []);
    }

    /**
     * @param array<string, mixed> $currentLevel
     * @param list<array<string, mixed>> $levels
     * @return array<string, mixed>
     */
    private function nextLevel(array $currentLevel, array $levels): array
    {
        if ($currentLevel === []) {
            return [];
        }

        $currentMinPoints = (int) ($currentLevel['min_points'] ?? 0);
        foreach ($levels as $level) {
            if ((int) ($level['min_points'] ?? 0) > $currentMinPoints) {
                return $level;
            }
        }

        return [];
    }

    /**
     * @param array<string, mixed> $level
     * @param array<string, mixed> $nextLevel
     * @return array<string, mixed>
     */
    private function progress(array $level, array $nextLevel, int $points): array
    {
        $minPoints = (int) ($level['min_points'] ?? 0);
        $targetPoints = $nextLevel !== []
            ? (int) ($nextLevel['min_points'] ?? $minPoints)
            : $minPoints;
        if ($targetPoints <= $minPoints) {
            $targetPoints = $minPoints;
        }

        $span = max($targetPoints - $minPoints, 1);
        $earned = max($points - $minPoints, 0);
        $percent = $nextLevel === [] ? 1.0 : min($earned / $span, 1.0);

        return [
            'current_points' => $points,
            'current_min_points' => $minPoints,
            'target_points' => $targetPoints,
            'remaining_points' => $nextLevel === [] ? 0 : max($targetPoints - $points, 0),
            'progress_percent' => $percent,
            'next_level_id' => (int) ($nextLevel['id'] ?? 0),
            'next_level_name' => (string) ($nextLevel['level_name'] ?? ''),
            'next_level_code' => (string) ($nextLevel['level_code'] ?? ''),
        ];
    }

    /**
     * @param array<string, mixed> $level
     * @return array<string, mixed>
     */
    private function publicLevel(array $level): array
    {
        if ($level === []) {
            return [];
        }

        return [
            'id' => (int) ($level['id'] ?? 0),
            'level_name' => (string) ($level['level_name'] ?? ''),
            'level_code' => (string) ($level['level_code'] ?? ''),
            'min_points' => (int) ($level['min_points'] ?? 0),
            'max_points' => $level['max_points'] ?? null,
            'level_icon' => (string) ($level['level_icon'] ?? ''),
            'privileges' => (string) ($level['privileges'] ?? ''),
            'sort' => (int) ($level['sort'] ?? 0),
        ];
    }
}
