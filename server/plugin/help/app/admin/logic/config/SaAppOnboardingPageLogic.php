<?php

declare(strict_types=1);

namespace plugin\help\app\admin\logic\config;

use plugin\help\app\model\config\SaAppOnboardingPage;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;

/**
 * App引导页配置逻辑层
 */
class SaAppOnboardingPageLogic extends BaseLogic
{
    private const COPY_FIELDS = [
        'locale',
        'title',
        'description',
        'image',
        'button_text',
        'action_type',
        'action_value',
        'sort',
        'status',
        'start_time',
        'end_time',
    ];

    public function __construct()
    {
        $this->model = new SaAppOnboardingPage();
        $this->orderField = 'sort';
        $this->orderType = 'ASC';
    }

    /**
     * 删除引导页。已软删的记录不再假装成功。
     */
    public function destroy($ids): bool
    {
        $idList = $this->normalizeIds($ids);
        if ($idList === []) {
            throw new ApiException('请选择要删除的数据');
        }

        $alive = (int) $this->model->whereIn($this->model->getPk(), $idList)->count();
        if ($alive === 0) {
            throw new ApiException('要删除的数据不存在或已删除');
        }

        return parent::destroy($idList);
    }

    /**
     * 按场景 + 版本组装故事板，并附带全部流程摘要
     *
     * @return array{
     *     scene: string,
     *     version: string,
     *     locales: array<int, string>,
     *     next_sort: int,
     *     slides: array<int, array{sort: int, locales: array<string, array<string, mixed>>}>,
     *     flows: array<int, array{scene: string, version: string, slide_count: int, locales: array<int, string>, is_current: bool}>
     * }
     */
    public function storyboard(string $scene, string $version): array
    {
        $scene = $scene !== '' ? $scene : 'first_launch';

        $rows = $this->flowQuery($scene, $version)
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();

        $slides = $this->groupSlides($rows);
        $locales = [];
        foreach ($slides as $slide) {
            foreach (array_keys($slide['locales']) as $locale) {
                $locales[$locale] = true;
            }
        }

        return [
            'scene' => $scene,
            'version' => $version,
            'locales' => array_values(array_keys($locales)),
            'next_sort' => $this->nextSort($slides),
            'slides' => $slides,
            'flows' => $this->listFlows(),
        ];
    }

    /**
     * 按播放顺序重写同一流程下所有语言行的 sort
     *
     * @param array<int, mixed> $slideIds 每张幻灯片的代表记录 ID，顺序即新的播放顺序
     */
    public function reorder(string $scene, string $version, array $slideIds): bool
    {
        $scene = $scene !== '' ? $scene : 'first_launch';
        $ids = [];
        foreach ($slideIds as $slideId) {
            $id = (int) $slideId;
            if ($id > 0 && !in_array($id, $ids, true)) {
                $ids[] = $id;
            }
        }
        if ($ids === []) {
            throw new ApiException('请提供播放顺序');
        }

        return (bool) $this->transaction(function () use ($scene, $version, $ids) {
            $rows = $this->flowQuery($scene, $version)
                ->order('sort', 'asc')
                ->order('id', 'asc')
                ->select();

            $byId = [];
            foreach ($rows as $row) {
                $byId[(int) $row->id] = $row;
            }

            $groups = [];
            $usedSorts = [];
            foreach ($ids as $id) {
                if (!isset($byId[$id])) {
                    throw new ApiException('幻灯片不存在或不属于当前流程');
                }
                $sort = (int) $byId[$id]->sort;
                if (isset($usedSorts[$sort])) {
                    continue;
                }
                $usedSorts[$sort] = true;
                $groups[] = $this->siblingsBySort($rows, $sort);
            }

            foreach ($rows as $row) {
                $sort = (int) $row->sort;
                if (isset($usedSorts[$sort])) {
                    continue;
                }
                $usedSorts[$sort] = true;
                $groups[] = $this->siblingsBySort($rows, $sort);
            }

            $sortValue = 10;
            foreach ($groups as $siblings) {
                foreach ($siblings as $row) {
                    $row->sort = $sortValue;
                    $row->save();
                }
                $sortValue += 10;
            }

            return true;
        });
    }

    /**
     * 把当前流程复制到新的场景 + 版本
     */
    public function copyFlow(string $sourceScene, string $sourceVersion, string $scene, string $version): int
    {
        $sourceScene = $sourceScene !== '' ? $sourceScene : 'first_launch';
        $scene = $scene !== '' ? $scene : 'first_launch';
        $sourceVersion = $this->normalizeVersion($sourceVersion, true);
        $version = $this->normalizeVersion($version, true);

        $exists = (int) $this->flowQuery($scene, $version)->count();
        if ($exists > 0) {
            throw new ApiException('目标流程已存在页面，请换一个版本号');
        }

        $rows = $this->flowQuery($sourceScene, $sourceVersion)
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();
        if ($rows === []) {
            throw new ApiException('当前流程没有可复制的页面');
        }

        return (int) $this->transaction(function () use ($rows, $scene, $version) {
            $count = 0;
            foreach ($rows as $row) {
                $payload = [
                    'scene' => $scene,
                    'version' => $version,
                ];
                foreach (self::COPY_FIELDS as $field) {
                    $payload[$field] = $row[$field] ?? '';
                }
                $payload['sort'] = (int) ($row['sort'] ?? 10);
                $payload['status'] = (int) ($row['status'] ?? 1);
                if (($payload['start_time'] ?? '') === '' || ($payload['start_time'] ?? '') === '0000-00-00 00:00:00') {
                    $payload['start_time'] = null;
                }
                if (($payload['end_time'] ?? '') === '' || ($payload['end_time'] ?? '') === '0000-00-00 00:00:00') {
                    $payload['end_time'] = null;
                }
                $this->add($payload);
                $count++;
            }

            return $count;
        });
    }

    /**
     * 把指定版本发布为 App 正在使用的默认版本（version 空值）
     */
    public function publishFlow(string $scene, string $version): string
    {
        $scene = $scene !== '' ? $scene : 'first_launch';
        $version = $this->normalizeVersion($version, false);
        if ((int) $this->flowQuery($scene, $version)->count() === 0) {
            throw new ApiException('要发布的版本没有页面');
        }

        return (string) $this->transaction(function () use ($scene, $version) {
            $archive = $this->nextArchiveVersion($scene);
            $defaults = $this->flowQuery($scene, '')->select();
            foreach ($defaults as $row) {
                $row->version = $archive;
                $row->save();
            }

            $source = $this->flowQuery($scene, $version)->select();
            foreach ($source as $row) {
                $row->version = '';
                $row->save();
            }

            return $archive;
        });
    }

    /**
     * 重命名草稿版本号，不能改 App 正在使用的默认版本
     */
    public function renameFlow(string $scene, string $version, string $newVersion): int
    {
        $scene = $scene !== '' ? $scene : 'first_launch';
        $version = $this->normalizeVersion($version, false);
        $newVersion = $this->normalizeVersion($newVersion, false);
        if ($version === $newVersion) {
            throw new ApiException('新版本号与当前相同');
        }
        if ((int) $this->flowQuery($scene, $version)->count() === 0) {
            throw new ApiException('要改名的版本没有页面');
        }
        if ((int) $this->flowQuery($scene, $newVersion)->count() > 0) {
            throw new ApiException('目标版本号已存在');
        }

        $ids = $this->flowIds($scene, $version);

        return (int) $this->transaction(function () use ($ids, $newVersion) {
            $count = 0;
            foreach ($this->model->whereIn($this->model->getPk(), $ids)->select() as $row) {
                $row->version = $newVersion;
                $row->save();
                $count++;
            }

            return $count;
        });
    }

    /**
     * 删除某个场景下的整套版本
     */
    public function destroyFlow(string $scene, string $version): int
    {
        $scene = $scene !== '' ? $scene : 'first_launch';
        $version = $this->normalizeVersion($version, true);
        $ids = $this->flowIds($scene, $version);
        if ($ids === []) {
            throw new ApiException('该版本没有可删除的页面');
        }
        $this->destroy($ids);

        return count($ids);
    }

    /**
     * @param array<int, array<string, mixed>> $rows
     * @return array<int, array{sort: int, locales: array<string, array<string, mixed>>}>
     */
    private function groupSlides(array $rows): array
    {
        $groups = [];
        foreach ($rows as $row) {
            $sort = (int) ($row['sort'] ?? 0);
            if (!isset($groups[$sort])) {
                $groups[$sort] = [
                    'sort' => $sort,
                    'locales' => [],
                ];
            }
            $locale = (string) ($row['locale'] ?? '');
            if ($locale === '') {
                continue;
            }
            $groups[$sort]['locales'][$locale] = $row;
        }
        ksort($groups, SORT_NUMERIC);

        return array_values($groups);
    }

    /**
     * @param array<int, array{sort: int, locales: array<string, array<string, mixed>>}> $slides
     */
    private function nextSort(array $slides): int
    {
        $max = 0;
        foreach ($slides as $slide) {
            $max = max($max, (int) ($slide['sort'] ?? 0));
        }

        return $max > 0 ? $max + 10 : 10;
    }

    /**
     * @return array<int, array{scene: string, version: string, slide_count: int, locales: array<int, string>, is_current: bool}>
     */
    private function listFlows(): array
    {
        $rows = $this->model
            ->field(['id', 'scene', 'version', 'locale', 'sort'])
            ->order('scene', 'asc')
            ->order('version', 'asc')
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();

        $flows = [];
        foreach ($rows as $row) {
            $scene = (string) ($row['scene'] ?? 'first_launch');
            $version = (string) ($row['version'] ?? '');
            $key = $scene . "\0" . $version;
            if (!isset($flows[$key])) {
                $flows[$key] = [
                    'scene' => $scene,
                    'version' => $version,
                    'slide_count' => 0,
                    'locales' => [],
                    'is_current' => $version === '',
                    '_sorts' => [],
                ];
            }
            $sort = (int) ($row['sort'] ?? 0);
            if (!isset($flows[$key]['_sorts'][$sort])) {
                $flows[$key]['_sorts'][$sort] = true;
                $flows[$key]['slide_count']++;
            }
            $locale = (string) ($row['locale'] ?? '');
            if ($locale !== '' && !in_array($locale, $flows[$key]['locales'], true)) {
                $flows[$key]['locales'][] = $locale;
            }
        }

        $result = [];
        foreach ($flows as $flow) {
            unset($flow['_sorts']);
            $result[] = $flow;
        }

        usort($result, static function (array $left, array $right): int {
            $sceneCmp = strcmp((string) $left['scene'], (string) $right['scene']);
            if ($sceneCmp !== 0) {
                return $sceneCmp;
            }
            $leftVersion = (string) $left['version'];
            $rightVersion = (string) $right['version'];
            if ($leftVersion === '' && $rightVersion !== '') {
                return -1;
            }
            if ($rightVersion === '' && $leftVersion !== '') {
                return 1;
            }
            $leftArchived = str_starts_with($leftVersion, 'archived-');
            $rightArchived = str_starts_with($rightVersion, 'archived-');
            if ($leftArchived !== $rightArchived) {
                return $leftArchived ? 1 : -1;
            }

            return strcmp($leftVersion, $rightVersion);
        });

        return $result;
    }

    /**
     * @return array<int, int>
     */
    private function flowIds(string $scene, string $version): array
    {
        $rows = $this->flowQuery($scene, $version)
            ->field($this->model->getPk())
            ->select()
            ->toArray();

        return $this->normalizeIds(array_column($rows, $this->model->getPk()));
    }

    private function nextArchiveVersion(string $scene): string
    {
        $archive = 'archived-' . date('YmdHis');
        $suffix = 0;
        while ((int) $this->flowQuery($scene, $archive)->count() > 0) {
            $suffix++;
            $archive = 'archived-' . date('YmdHis') . '-' . $suffix;
        }

        return $archive;
    }

    private function normalizeVersion(string $version, bool $allowEmpty): string
    {
        $version = trim($version);
        if ($version === '') {
            if ($allowEmpty) {
                return '';
            }
            throw new ApiException('请填写版本号');
        }
        if (!preg_match('/^[A-Za-z0-9][A-Za-z0-9._-]{0,48}$/', $version)) {
            throw new ApiException('版本号仅支持字母、数字、点、下划线和短横线，最长 50 位');
        }

        return $version;
    }

    private function flowQuery(string $scene, string $version)
    {
        return $this->model->where('scene', $scene)->where('version', $version);
    }

    /**
     * @param mixed $ids
     * @return array<int, int>
     */
    private function normalizeIds(mixed $ids): array
    {
        if (!is_array($ids)) {
            $ids = explode(',', (string) $ids);
        }

        $idList = [];
        foreach ($ids as $id) {
            $id = (int) $id;
            if ($id > 0 && !in_array($id, $idList, true)) {
                $idList[] = $id;
            }
        }

        return $idList;
    }

    /**
     * @param iterable<mixed> $rows
     * @return array<int, mixed>
     */
    private function siblingsBySort(iterable $rows, int $sort): array
    {
        $siblings = [];
        foreach ($rows as $row) {
            if ((int) $row->sort === $sort) {
                $siblings[] = $row;
            }
        }

        return $siblings;
    }
}
