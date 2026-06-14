<?php

namespace plugin\help\app\admin\controller\material;

use plugin\help\app\admin\logic\material\SaContentMaterialLogic;
use plugin\help\app\admin\validate\material\SaContentMaterialValidate;
use plugin\help\app\service\HelpAuditLogService;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 内容素材控制器
 */
class SaContentMaterialController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaContentMaterialLogic();
        $this->validate = new SaContentMaterialValidate();
        parent::__construct();
    }

    #[Permission('内容素材列表', 'help:material:content:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['category_id', ''],
            ['media_type', ''],
            ['material_type', ''],
            ['title', ''],
            ['audit_status', ''],
            ['is_public', ''],
            ['is_recommended', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('内容素材读取', 'help:material:content:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }
        $data = is_array($model) ? $model : $model->toArray();
        $data['audit_logs'] = (new HelpAuditLogService())->list('content_material', (int) ($data['id'] ?? 0));

        return $this->success($data);
    }

    #[Permission('内容素材添加', 'help:material:content:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('内容素材修改', 'help:material:content:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('内容素材删除', 'help:material:content:destroy')]
    public function destroy(Request $request): Response
    {
        $ids = $request->post('ids', '');
        if (empty($ids)) {
            return $this->fail('请选择要删除的数据');
        }
        $result = $this->logic->destroy($ids);

        return $result ? $this->success('删除成功') : $this->fail('删除失败');
    }

    #[Permission('内容素材审核', 'help:material:content:audit')]
    public function audit(Request $request): Response
    {
        $id = (int) $request->post('id', 0);
        $auditStatus = (int) $request->post('audit_status', 0);
        if ($id <= 0) {
            return $this->fail('请选择要审核的素材');
        }
        $result = $this->logic->audit(
            $id,
            $auditStatus,
            trim((string) $request->post('audit_remark', '')),
            isset($this->adminId) ? (int) $this->adminId : 0
        );

        return $result ? $this->success('审核成功') : $this->fail('审核失败');
    }
}
