<?php

namespace plugin\help\app\admin\controller\plan;

use plugin\help\app\admin\logic\plan\SaTreatmentPlanLogic;
use plugin\help\app\admin\validate\plan\SaTreatmentPlanValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 治疗计划控制器
 */
class SaTreatmentPlanController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaTreatmentPlanLogic();
        $this->validate = new SaTreatmentPlanValidate();
        parent::__construct();
    }

    #[Permission('治疗计划列表', 'help:plan:treatmentPlan:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['doctor_id', ''],
            ['title', ''],
            ['source_type', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('治疗计划读取', 'help:plan:treatmentPlan:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        $data = is_array($model) ? $model : $model->toArray();

        return $this->success($data);
    }

    #[Permission('治疗计划添加', 'help:plan:treatmentPlan:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('治疗计划修改', 'help:plan:treatmentPlan:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('治疗计划删除', 'help:plan:treatmentPlan:destroy')]
    public function destroy(Request $request): Response
    {
        $ids = $request->post('ids', '');
        if (empty($ids)) {
            return $this->fail('请选择要删除的数据');
        }
        $result = $this->logic->destroy($ids);

        return $result ? $this->success('删除成功') : $this->fail('删除失败');
    }
}
