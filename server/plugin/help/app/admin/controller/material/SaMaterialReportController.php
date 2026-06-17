<?php

namespace plugin\help\app\admin\controller\material;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\admin\logic\material\SaMaterialReportLogic;
use plugin\help\app\admin\validate\material\SaMaterialReportValidate;
use plugin\help\app\service\HelpAuditLogService;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 素材举报处理控制器
 */
#[Apidoc\Group('HelpSupport 后台素材管理')]
#[Apidoc\Title('素材举报管理')]
class SaMaterialReportController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaMaterialReportLogic();
        $this->validate = new SaMaterialReportValidate();
        parent::__construct();
    }

    #[Apidoc\Title('素材举报列表')]
    #[Apidoc\Url('/app/help/admin/material/SaMaterialReport/index')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('member_id', type: 'int', require: false, desc: '举报会员ID')]
    #[Apidoc\Query('target_type', type: 'int', require: false, desc: '目标类型 1素材 2评论')]
    #[Apidoc\Query('target_id', type: 'int', require: false, desc: '目标ID')]
    #[Apidoc\Query('reason', type: 'string', require: false, desc: '举报原因')]
    #[Apidoc\Query('handle_status', type: 'int', require: false, desc: '处理状态 0待处理 1已处理 2已忽略')]
    #[Apidoc\Returned('list', type: 'array', desc: '举报分页列表')]
    #[Permission('素材举报列表', 'help:material:report:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['target_type', ''],
            ['target_id', ''],
            ['reason', ''],
            ['handle_status', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Apidoc\Title('素材举报读取')]
    #[Apidoc\Url('/app/help/admin/material/SaMaterialReport/read')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('id', type: 'int', require: true, desc: '举报ID')]
    #[Apidoc\Returned('id', type: 'int', desc: '举报ID')]
    #[Permission('素材举报读取', 'help:material:report:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        $data = is_array($model) ? $model : $model->toArray();
        $data['audit_logs'] = (new HelpAuditLogService())->list('material_report', (int) ($data['id'] ?? 0));

        return $this->success($data);
    }

    #[Apidoc\Title('素材举报添加')]
    #[Apidoc\Url('/app/help/admin/material/SaMaterialReport/save')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('member_id', type: 'int', require: true, desc: '举报会员ID')]
    #[Apidoc\Param('target_type', type: 'int', require: true, desc: '目标类型 1素材 2评论')]
    #[Apidoc\Param('target_id', type: 'int', require: true, desc: '目标ID')]
    #[Apidoc\Param('reason', type: 'string', require: true, desc: '举报原因')]
    #[Apidoc\Param('description', type: 'string', require: false, desc: '举报描述')]
    #[Permission('素材举报添加', 'help:material:report:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Apidoc\Title('素材举报修改')]
    #[Apidoc\Url('/app/help/admin/material/SaMaterialReport/update')]
    #[Apidoc\Method('PUT')]
    #[Apidoc\Param('id', type: 'int', require: true, desc: '举报ID')]
    #[Apidoc\Param('member_id', type: 'int', require: true, desc: '举报会员ID')]
    #[Apidoc\Param('target_type', type: 'int', require: true, desc: '目标类型 1素材 2评论')]
    #[Apidoc\Param('target_id', type: 'int', require: true, desc: '目标ID')]
    #[Apidoc\Param('reason', type: 'string', require: true, desc: '举报原因')]
    #[Apidoc\Param('description', type: 'string', require: false, desc: '举报描述')]
    #[Permission('素材举报修改', 'help:material:report:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Apidoc\Title('素材举报删除')]
    #[Apidoc\Url('/app/help/admin/material/SaMaterialReport/destroy')]
    #[Apidoc\Method('DELETE')]
    #[Apidoc\Param('ids', type: 'array', require: true, desc: '举报ID列表')]
    #[Permission('素材举报删除', 'help:material:report:destroy')]
    public function destroy(Request $request): Response
    {
        $ids = $request->post('ids', '');
        if (empty($ids)) {
            return $this->fail('请选择要删除的数据');
        }
        $result = $this->logic->destroy($ids);

        return $result ? $this->success('删除成功') : $this->fail('删除失败');
    }

    #[Apidoc\Title('素材举报处理')]
    #[Apidoc\Url('/app/help/admin/material/SaMaterialReport/handle')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'int', require: true, desc: '举报ID')]
    #[Apidoc\Param('handle_status', type: 'int', require: true, desc: '处理状态 1已处理 2已忽略')]
    #[Apidoc\Param('handle_remark', type: 'string', require: false, desc: '处理备注')]
    #[Permission('素材举报处理', 'help:material:report:handle')]
    public function handle(Request $request): Response
    {
        $id = (int) $request->post('id', 0);
        $handleStatus = (int) $request->post('handle_status', 0);
        if ($id <= 0) {
            return $this->fail('请选择要处理的举报');
        }
        $result = $this->logic->handle(
            $id,
            $handleStatus,
            trim((string) $request->post('handle_remark', '')),
            isset($this->adminId) ? (int) $this->adminId : 0
        );

        return $result ? $this->success('处理成功') : $this->fail('处理失败');
    }
}
