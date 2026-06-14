<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

/**
 * HelpSupport 文本风控服务。
 */
class HelpRiskService
{
    private const ACTION_REJECT = 'reject';
    private const ACTION_REPLACE = 'replace';

    private array $rules = [];

    public function filterText(string $scene, string $text): string
    {
        $text = trim($text);
        if ($text === '') {
            return '';
        }

        $matches = $this->matchedRules($scene, $text);
        if ($matches === []) {
            return $text;
        }

        $this->increaseHitCount(array_column($matches, 'id'));
        foreach ($matches as $rule) {
            if ((string) ($rule['action'] ?? '') === self::ACTION_REJECT) {
                throw new ApiException('内容包含敏感信息，请修改后再提交', 400);
            }
        }

        $filtered = $text;
        foreach ($matches as $rule) {
            if ((string) ($rule['action'] ?? '') === self::ACTION_REPLACE) {
                $filtered = $this->replace($filtered, $rule);
            }
        }

        return trim($filtered);
    }

    private function matchedRules(string $scene, string $text): array
    {
        $matches = [];
        foreach ($this->rules($scene) as $rule) {
            if ($this->matches($text, $rule)) {
                $matches[] = $rule;
            }
        }

        return $matches;
    }

    private function rules(string $scene): array
    {
        $scene = trim($scene) !== '' ? trim($scene) : 'all';
        if (isset($this->rules[$scene])) {
            return $this->rules[$scene];
        }

        $this->rules[$scene] = Db::table('sa_sensitive_word_rule')
            ->whereIn('scene', array_values(array_unique([$scene, 'all'])))
            ->where('status', 1)
            ->whereNull('delete_time')
            ->order('risk_level', 'desc')
            ->order('id', 'asc')
            ->select()
            ->toArray();

        return $this->rules[$scene];
    }

    private function matches(string $text, array $rule): bool
    {
        $word = trim((string) ($rule['word'] ?? ''));
        if ($word === '') {
            return false;
        }

        return match ((string) ($rule['match_type'] ?? 'contains')) {
            'exact' => $this->lowerText(trim($text)) === $this->lowerText($word),
            'regex' => $this->regexMatches($text, $word),
            default => str_contains($this->lowerText($text), $this->lowerText($word)),
        };
    }

    private function replace(string $text, array $rule): string
    {
        $word = trim((string) ($rule['word'] ?? ''));
        if ($word === '') {
            return $text;
        }

        $replacement = (string) ($rule['replacement'] ?? '');
        return match ((string) ($rule['match_type'] ?? 'contains')) {
            'exact' => $this->lowerText(trim($text)) === $this->lowerText($word) ? $replacement : $text,
            'regex' => $this->regexReplace($text, $word, $replacement),
            default => str_ireplace($word, $replacement, $text),
        };
    }

    private function regexMatches(string $text, string $pattern): bool
    {
        $regex = $this->regex($pattern);
        return $regex !== '' && @preg_match($regex, $text) === 1;
    }

    private function regexReplace(string $text, string $pattern, string $replacement): string
    {
        $regex = $this->regex($pattern);
        if ($regex === '') {
            return $text;
        }

        $result = @preg_replace($regex, $replacement, $text);
        return is_string($result) ? $result : $text;
    }

    private function regex(string $pattern): string
    {
        $pattern = trim($pattern);
        if ($pattern === '') {
            return '';
        }

        $delimiter = $pattern[0];
        if (!ctype_alnum($delimiter) && $delimiter !== '\\' && strrpos($pattern, $delimiter) > 0) {
            return $pattern;
        }

        return '/' . str_replace('/', '\/', $pattern) . '/u';
    }

    private function increaseHitCount(array $ids): void
    {
        $ids = array_values(array_unique(array_map('intval', $ids)));
        $ids = array_filter($ids, static fn (int $id): bool => $id > 0);
        if ($ids === []) {
            return;
        }

        Db::execute(
            'UPDATE `sa_sensitive_word_rule` SET `hit_count` = `hit_count` + 1, `update_time` = NOW() WHERE `id` IN (' . implode(',', $ids) . ')'
        );
    }

    private function lowerText(string $text): string
    {
        return function_exists('mb_strtolower') ? mb_strtolower($text, 'UTF-8') : strtolower($text);
    }
}
