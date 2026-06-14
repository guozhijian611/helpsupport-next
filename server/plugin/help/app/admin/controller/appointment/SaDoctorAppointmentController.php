<?php

namespace plugin\help\app\admin\controller\appointment;

use plugin\help\app\admin\logic\appointment\SaDoctorAppointmentLogic;
use plugin\help\app\admin\validate\appointment\SaDoctorAppointmentValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 医生预约控制器
 */
class SaDoctorAppointmentController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaDoctorAppointmentLogic();
        $this->validate = new SaDoctorAppointmentValidate();
        parent::__construct();
    }

    #[Permission('医生预约列表', 'help:appointment:doctorAppointment:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['doctor_id', ''],
            ['appoint_date', ''],
            ['status', ''],
            ['meet_type', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('医生预约读取', 'help:appointment:doctorAppointment:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }
        $data = is_array($model) ? $model : $model->toArray();

        return $this->success($data);
    }

    #[Permission('医生预约添加', 'help:appointment:doctorAppointment:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('医生预约修改', 'help:appointment:doctorAppointment:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('医生预约删除', 'help:appointment:doctorAppointment:destroy')]
    public function destroy(Request $request): Response
    {
        $ids = $request->post('ids', '');
        if (empty($ids)) {
            return $this->fail('请选择要删除的数据');
        }
        $result = $this->logic->destroy($ids);

        return $result ? $this->success('删除成功') : $this->fail('删除失败');
    }

    #[Permission('医生预约确认', 'help:appointment:doctorAppointment:confirm')]
    public function confirm(Request $request): Response
    {
        $id = (int) $request->post('id', 0);
        if ($id <= 0) {
            return $this->fail('请选择要确认的预约');
        }
        $result = $this->logic->confirm(
            $id,
            trim((string) $request->post('meet_type', '')),
            trim((string) $request->post('meet_link', '')),
            trim((string) $request->post('confirm_remark', ''))
        );

        return $result ? $this->success('确认成功') : $this->fail('确认失败');
    }

    #[Permission('医生预约完成', 'help:appointment:doctorAppointment:finish')]
    public function finish(Request $request): Response
    {
        $id = (int) $request->post('id', 0);
        if ($id <= 0) {
            return $this->fail('请选择要完成的预约');
        }
        $result = $this->logic->finish($id);

        return $result ? $this->success('操作成功') : $this->fail('操作失败');
    }

    #[Permission('医生预约取消', 'help:appointment:doctorAppointment:cancel')]
    public function cancel(Request $request): Response
    {
        $id = (int) $request->post('id', 0);
        if ($id <= 0) {
            return $this->fail('请选择要取消的预约');
        }
        $result = $this->logic->cancel(
            $id,
            trim((string) $request->post('cancel_reason', '')),
            trim((string) $request->post('cancel_by', 'system'))
        );

        return $result ? $this->success('取消成功') : $this->fail('取消失败');
    }

    #[Permission('医生预约拒绝', 'help:appointment:doctorAppointment:reject')]
    public function reject(Request $request): Response
    {
        $id = (int) $request->post('id', 0);
        if ($id <= 0) {
            return $this->fail('请选择要拒绝的预约');
        }
        $result = $this->logic->reject(
            $id,
            trim((string) $request->post('confirm_remark', ''))
        );

        return $result ? $this->success('拒绝成功') : $this->fail('拒绝失败');
    }
}
