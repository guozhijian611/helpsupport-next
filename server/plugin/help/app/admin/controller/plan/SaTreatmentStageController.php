<?php

namespace plugin\help\app\admin\controller\plan;

use plugin\help\app\admin\logic\plan\SaTreatmentStageLogic;
use plugin\help\app\admin\validate\plan\SaTreatmentStageValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 治疗阶段控制器
 */
class SaTreatmentStageController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaTreatmentStageLogic();
        $this->validate = new SaTreatmentStageValidate();
        parent::__construct();
    }

    #[Permission('治疗阶段列表', 'help:plan:treatmentStage:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['plan_id', ''],
            ['member_id', ''],
            ['stage_key', ''],
            ['stage_name', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('治疗阶段读取', 'help:plan:treatmentStage:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        $data = is_array($model) ? $model : $model->toArray();

        return $this->success($data);
    }

    #[Permission('治疗阶段添加', 'help:plan:treatmentStage:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('治疗阶段修改', 'help:plan:treatmentStage:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('治疗阶段删除', 'help:plan:treatmentStage:destroy')]
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
