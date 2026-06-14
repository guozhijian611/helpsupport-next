<?php

namespace plugin\help\app\admin\controller\appointment;

use plugin\help\app\admin\logic\appointment\SaDoctorScheduleLogic;
use plugin\help\app\admin\validate\appointment\SaDoctorScheduleValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 医生排班控制器
 */
class SaDoctorScheduleController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaDoctorScheduleLogic();
        $this->validate = new SaDoctorScheduleValidate();
        parent::__construct();
    }

    #[Permission('医生排班列表', 'help:appointment:doctorSchedule:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['doctor_id', ''],
            ['schedule_date', ''],
            ['meet_type', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('医生排班读取', 'help:appointment:doctorSchedule:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }
        $data = is_array($model) ? $model : $model->toArray();

        return $this->success($data);
    }

    #[Permission('医生排班添加', 'help:appointment:doctorSchedule:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('医生排班修改', 'help:appointment:doctorSchedule:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('医生排班删除', 'help:appointment:doctorSchedule:destroy')]
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
