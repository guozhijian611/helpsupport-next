<?php

namespace plugin\help\app\admin\controller\doctor;

use plugin\help\app\admin\logic\doctor\SaDoctorAssessmentScaleLogic;
use plugin\help\app\admin\validate\doctor\SaDoctorAssessmentScaleValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 医生评估量表控制器
 */
class SaDoctorAssessmentScaleController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaDoctorAssessmentScaleLogic();
        $this->validate = new SaDoctorAssessmentScaleValidate();
        parent::__construct();
    }

    #[Permission('评估量表列表', 'help:doctor:assessmentScale:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['doctor_id', ''],
            ['title', ''],
            ['stage', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('评估量表读取', 'help:doctor:assessmentScale:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }
        $data = is_array($model) ? $model : $model->toArray();

        return $this->success($this->logic->presentScale($data));
    }

    #[Permission('评估量表添加', 'help:doctor:assessmentScale:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('评估量表修改', 'help:doctor:assessmentScale:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('评估量表删除', 'help:doctor:assessmentScale:destroy')]
    public function destroy(Request $request): Response
    {
        $ids = $request->post('ids', '');
        if (empty($ids)) {
            return $this->fail('请选择要删除的数据');
        }
        $result = $this->logic->destroy($ids);

        return $result ? $this->success('删除成功') : $this->fail('删除失败');
    }

    #[Permission('评估量表发布', 'help:doctor:assessmentScale:publish')]
    public function publish(Request $request): Response
    {
        $id = trim((string) $request->post('id', ''));
        $result = $this->logic->publish($id);

        return $result ? $this->success('发布成功') : $this->fail('发布失败');
    }

    #[Permission('评估量表禁用', 'help:doctor:assessmentScale:disable')]
    public function disable(Request $request): Response
    {
        $id = trim((string) $request->post('id', ''));
        $result = $this->logic->disable($id);

        return $result ? $this->success('禁用成功') : $this->fail('禁用失败');
    }
}
