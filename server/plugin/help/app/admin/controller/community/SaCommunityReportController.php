<?php

namespace plugin\help\app\admin\controller\community;

use plugin\help\app\admin\logic\community\SaCommunityReportLogic;
use plugin\help\app\admin\validate\community\SaCommunityReportValidate;
use plugin\help\app\service\HelpAuditLogService;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 社区举报处理控制器
 */
class SaCommunityReportController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaCommunityReportLogic();
        $this->validate = new SaCommunityReportValidate();
        parent::__construct();
    }

    #[Permission('社区举报列表', 'help:community:report:index')]
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

    #[Permission('社区举报读取', 'help:community:report:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        $data = is_array($model) ? $model : $model->toArray();
        $data['audit_logs'] = (new HelpAuditLogService())->list('community_report', (int) ($data['id'] ?? 0));

        return $this->success($data);
    }

    #[Permission('社区举报添加', 'help:community:report:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('社区举报修改', 'help:community:report:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('社区举报删除', 'help:community:report:destroy')]
    public function destroy(Request $request): Response
    {
        $ids = $request->post('ids', '');
        if (empty($ids)) {
            return $this->fail('请选择要删除的数据');
        }
        $result = $this->logic->destroy($ids);

        return $result ? $this->success('删除成功') : $this->fail('删除失败');
    }

    #[Permission('社区举报处理', 'help:community:report:handle')]
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
            isset($this->adminId) ? $this->adminId : 0
        );

        return $result ? $this->success('处理成功') : $this->fail('处理失败');
    }
}
