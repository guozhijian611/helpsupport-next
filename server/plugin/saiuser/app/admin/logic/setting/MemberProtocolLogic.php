<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\saiuser\app\admin\logic\setting;

use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use plugin\saiuser\app\model\setting\MemberProtocol;
use think\facade\Db;

/**
 * 使用协议逻辑层
 */
class MemberProtocolLogic extends BaseLogic
{
    private const DEFAULT_LOCALE = 'zh-CN';

    /**
     * 构造函数
     */
    public function __construct()
    {
        $this->model = new MemberProtocol();
    }

    public function add($data): mixed
    {
        $data = $this->normalizeFields((array) $data, true);
        $this->assertUnique($data);

        return parent::add($data);
    }

    public function edit($id, $data): mixed
    {
        $id = (int) $id;
        $current = (array) $this->model->find($id)?->toArray();
        $data = $this->normalizeFields((array) $data, false, $current);
        $this->assertUnique($data, $id);

        return parent::edit($id, $data);
    }

    private function normalizeFields(array $data, bool $isCreate = false, array $current = []): array
    {
        if (array_key_exists('title', $data)) {
            $data['title'] = trim((string) $data['title']);
        }
        if (array_key_exists('locale', $data)) {
            $data['locale'] = trim((string) $data['locale']);
        }

        if ($isCreate && (($data['locale'] ?? '') === '')) {
            $data['locale'] = self::DEFAULT_LOCALE;
        } elseif (!$isCreate && (($data['locale'] ?? '') === '') && isset($current['locale'])) {
            $data['locale'] = (string) $current['locale'];
        }

        return $data;
    }

    private function assertUnique(array $data, ?int $id = null): void
    {
        $protocolType = (int) ($data['protocol_type'] ?? 0);
        $locale = trim((string) ($data['locale'] ?? ''));
        if ($protocolType <= 0 || $locale === '') {
            return;
        }

        $query = Db::table('sa_member_protocol')
            ->where('protocol_type', $protocolType)
            ->where('locale', $locale)
            ->whereNull('delete_time');
        if ($id !== null && $id > 0) {
            $query->where('id', '<>', $id);
        }

        if ($query->find()) {
            throw new ApiException('该协议类型和语言的协议已存在');
        }
    }

}
