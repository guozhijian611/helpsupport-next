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
 * 私人素材审核控制器
 */
class SaPrivateMaterialController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaContentMaterialLogic();
        $this->validate = new SaContentMaterialValidate();
        parent::__construct();
    }

    #[Permission('私人素材审核列表', 'help:material:privateMaterial:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['category_id', ''],
            ['media_type', ''],
            ['title', ''],
            ['audit_status', ''],
            ['status', ''],
        ]);
        $where['material_type'] = 'private';
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('私人素材审核读取', 'help:material:privateMaterial:read')]
    public function read(Request $request): Response
    {
        $id = (int) $request->input('id', 0);
        $data = $this->privateMaterial($id);
        if ($data === []) {
            return $this->fail('未查找到私人素材');
        }
        $data = $this->logic->enrichRows([$data])[0] ?? $data;
        $data['audit_logs'] = (new HelpAuditLogService())->list('content_material', $id);

        return $this->success($data);
    }

    #[Permission('私人素材审核添加', 'help:material:privateMaterial:save')]
    public function save(Request $request): Response
    {
        $data = $this->privatePayload($request->post());
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('私人素材审核修改', 'help:material:privateMaterial:update')]
    public function update(Request $request): Response
    {
        $data = $this->privatePayload($request->post());
        $id = (int) ($data['id'] ?? 0);
        if ($this->privateMaterial($id) === []) {
            return $this->fail('未查找到私人素材');
        }
        $this->validate('update', $data);
        $result = $this->logic->edit($id, $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('私人素材审核删除', 'help:material:privateMaterial:destroy')]
    public function destroy(Request $request): Response
    {
        $ids = $this->parseIds($request->post('ids', ''));
        if ($ids === []) {
            return $this->fail('请选择要删除的数据');
        }
        if (!$this->allPrivateMaterials($ids)) {
            return $this->fail('只能删除私人素材');
        }
        $result = $this->logic->destroy($ids);

        return $result ? $this->success('删除成功') : $this->fail('删除失败');
    }

    #[Permission('私人素材审核', 'help:material:privateMaterial:audit')]
    public function audit(Request $request): Response
    {
        $id = (int) $request->post('id', 0);
        if ($this->privateMaterial($id) === []) {
            return $this->fail('未查找到私人素材');
        }
        $result = $this->logic->audit(
            $id,
            (int) $request->post('audit_status', 0),
            trim((string) $request->post('audit_remark', '')),
            isset($this->adminId) ? (int) $this->adminId : 0
        );

        return $result ? $this->success('审核成功') : $this->fail('审核失败');
    }

    private function privatePayload(array $data): array
    {
        $data['material_type'] = 'private';
        $data['is_public'] = 2;
        $data['is_recommended'] = 2;

        return $data;
    }

    /**
     * @return array<string, mixed>
     */
    private function privateMaterial(int $id): array
    {
        if ($id <= 0) {
            return [];
        }

        return Db::table('sa_content_material')
            ->where('id', $id)
            ->where('material_type', 'private')
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
    private function allPrivateMaterials(array $ids): bool
    {
        $count = Db::table('sa_content_material')
            ->whereIn('id', $ids)
            ->where('material_type', 'private')
            ->whereNull('delete_time')
            ->count();

        return (int) $count === count($ids);
    }
}
