<?php

namespace plugin\help\app\admin\controller\doctor;

use plugin\help\app\admin\logic\doctor\SaDoctorPatientLogic;
use plugin\help\app\admin\validate\doctor\SaDoctorPatientValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 医生患者绑定关系控制器
 */
class SaDoctorPatientController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaDoctorPatientLogic();
        $this->validate = new SaDoctorPatientValidate();
        parent::__construct();
    }

    #[Permission('医生患者列表', 'help:doctor:patient:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['doctor_id', ''],
            ['member_id', ''],
            ['status', ''],
            ['bind_source', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('医生患者读取', 'help:doctor:patient:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }
        $data = is_array($model) ? $model : $model->toArray();

        return $this->success($data);
    }

    #[Permission('医生患者添加', 'help:doctor:patient:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('医生患者修改', 'help:doctor:patient:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('医生患者删除', 'help:doctor:patient:destroy')]
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
