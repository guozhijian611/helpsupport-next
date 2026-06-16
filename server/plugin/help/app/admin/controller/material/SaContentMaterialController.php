<?php

namespace plugin\help\app\admin\controller\material;

use plugin\help\app\admin\logic\material\SaContentMaterialLogic;
use plugin\help\app\admin\validate\material\SaContentMaterialValidate;
use plugin\help\app\service\HelpAuditLogService;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;
use think\facade\Db;

/**
 * 教育素材控制器
 */
class SaContentMaterialController extends BaseController
{
    private const MATERIAL_TYPE = 'education';

    public function __construct()
    {
        $this->logic = new SaContentMaterialLogic();
        $this->validate = new SaContentMaterialValidate();
        parent::__construct();
    }

    #[Permission('教育素材列表', 'help:material:content:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['category_id', ''],
            ['media_type', ''],
            ['title', ''],
            ['audit_status', ''],
            ['is_public', ''],
            ['is_recommended', ''],
            ['status', ''],
        ]);
        $where['material_type'] = self::MATERIAL_TYPE;
        $query = $this->logic->search($where);
        $data = $this->withCategoryNames($this->logic->getList($query));

        return $this->success($data);
    }

    #[Permission('教育素材读取', 'help:material:content:read')]
    public function read(Request $request): Response
    {
        $id = (int) $request->input('id', 0);
        $data = $this->materialByType($id);
        if ($data === []) {
            return $this->fail('未查找到教育素材');
        }
        $data = $this->appendCategoryName($data);
        $data['audit_logs'] = (new HelpAuditLogService())->list('content_material', $id);

        return $this->success($data);
    }

    #[Permission('教育素材添加', 'help:material:content:save')]
    public function save(Request $request): Response
    {
        $data = $this->materialPayload($request->post());
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('教育素材修改', 'help:material:content:update')]
    public function update(Request $request): Response
    {
        $data = $this->materialPayload($request->post());
        $id = (int) ($data['id'] ?? 0);
        if ($this->materialByType($id) === []) {
            return $this->fail('未查找到教育素材');
        }
        $this->validate('update', $data);
        $result = $this->logic->edit($id, $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('教育素材删除', 'help:material:content:destroy')]
    public function destroy(Request $request): Response
    {
        $ids = $this->parseIds($request->post('ids', ''));
        if ($ids === []) {
            return $this->fail('请选择要删除的数据');
        }
        if (!$this->allMaterialsOfType($ids)) {
            return $this->fail('只能删除教育素材');
        }
        $result = $this->logic->destroy($ids);

        return $result ? $this->success('删除成功') : $this->fail('删除失败');
    }

    #[Permission('教育素材审核', 'help:material:content:audit')]
    public function audit(Request $request): Response
    {
        $id = (int) $request->post('id', 0);
        if ($this->materialByType($id) === []) {
            return $this->fail('未查找到教育素材');
        }
        $result = $this->logic->audit(
            $id,
            (int) $request->post('audit_status', 0),
            trim((string) $request->post('audit_remark', '')),
            isset($this->adminId) ? (int) $this->adminId : 0
        );

        return $result ? $this->success('审核成功') : $this->fail('审核失败');
    }

    private function materialPayload(array $data): array
    {
        $data['material_type'] = self::MATERIAL_TYPE;

        return $data;
    }

    private function withCategoryNames(array $page): array
    {
        $rowsKey = null;
        if (isset($page['data']) && is_array($page['data'])) {
            $rowsKey = 'data';
        } elseif (isset($page['list']) && is_array($page['list'])) {
            $rowsKey = 'list';
        }
        if ($rowsKey === null) {
            return $page;
        }

        $page[$rowsKey] = $this->appendCategoryNames($page[$rowsKey]);

        return $page;
    }

    /**
     * @param array<int, array<string, mixed>> $rows
     * @return array<int, array<string, mixed>>
     */
    private function appendCategoryNames(array $rows): array
    {
        $categoryIds = array_values(array_unique(array_filter(
            array_map(fn (array $row): int => (int) ($row['category_id'] ?? 0), $rows),
            fn (int $id): bool => $id > 0
        )));
        if ($categoryIds === []) {
            foreach ($rows as &$row) {
                $row['category_name'] = '未分类';
            }
            unset($row);

            return $rows;
        }

        $categories = Db::table('sa_content_category')
            ->whereIn('id', $categoryIds)
            ->whereNull('delete_time')
            ->column('name', 'id');

        foreach ($rows as &$row) {
            $categoryId = (int) ($row['category_id'] ?? 0);
            $row['category_name'] = $categoryId > 0 ? (string) ($categories[$categoryId] ?? '分类已删除') : '未分类';
        }
        unset($row);

        return $rows;
    }

    /**
     * @param array<string, mixed> $data
     * @return array<string, mixed>
     */
    private function appendCategoryName(array $data): array
    {
        return $this->appendCategoryNames([$data])[0] ?? $data;
    }

    /**
     * @return array<string, mixed>
     */
    private function materialByType(int $id): array
    {
        if ($id <= 0) {
            return [];
        }

        return Db::table('sa_content_material')
            ->where('id', $id)
            ->where('material_type', self::MATERIAL_TYPE)
            ->whereNull('delete_time')
            ->find() ?: [];
    }

    /**
     * @return array<int, int>
     */
    private function parseIds(mixed $ids): array
    {
        if (is_string($ids)) {
            $ids = explode(',', $ids);
        }
        if (!is_array($ids)) {
            $ids = [$ids];
        }

        return array_values(array_unique(array_filter(array_map('intval', $ids), fn (int $id) => $id > 0)));
    }

    /**
     * @param array<int, int> $ids
     */
    private function allMaterialsOfType(array $ids): bool
    {
        $count = Db::table('sa_content_material')
            ->whereIn('id', $ids)
            ->where('material_type', self::MATERIAL_TYPE)
            ->whereNull('delete_time')
            ->count();

        return (int) $count === count($ids);
    }
}
