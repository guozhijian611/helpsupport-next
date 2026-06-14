<?php

namespace plugin\help\app\admin\controller\plan;

use plugin\help\app\admin\logic\plan\SaMemberAssessmentResultLogic;
use plugin\help\app\admin\validate\plan\SaMemberAssessmentResultValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 会员评估结果控制器
 */
class SaMemberAssessmentResultController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaMemberAssessmentResultLogic();
        $this->validate = new SaMemberAssessmentResultValidate();
        parent::__construct();
    }

    #[Permission('会员评估结果列表', 'help:plan:assessmentResult:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['doctor_id', ''],
            ['assessment_id', ''],
            ['assessment_title', ''],
            ['result_level', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('会员评估结果读取', 'help:plan:assessmentResult:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        $data = is_array($model) ? $model : $model->toArray();

        return $this->success($data);
    }

    #[Permission('会员评估结果添加', 'help:plan:assessmentResult:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('会员评估结果修改', 'help:plan:assessmentResult:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('会员评估结果删除', 'help:plan:assessmentResult:destroy')]
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
