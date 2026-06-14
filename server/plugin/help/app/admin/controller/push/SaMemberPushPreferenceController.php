<?php

namespace plugin\help\app\admin\controller\push;

use plugin\help\app\admin\logic\push\SaMemberPushPreferenceLogic;
use plugin\help\app\admin\validate\push\SaMemberPushPreferenceValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 会员推送偏好控制器
 */
class SaMemberPushPreferenceController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaMemberPushPreferenceLogic();
        $this->validate = new SaMemberPushPreferenceValidate();
        parent::__construct();
    }

    #[Permission('推送偏好列表', 'help:push:preference:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['is_push_enabled', ''],
            ['is_task_reminder_enabled', ''],
            ['is_community_enabled', ''],
            ['is_appointment_enabled', ''],
            ['is_audit_notice_enabled', ''],
            ['is_local_companion_enabled', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('推送偏好读取', 'help:push:preference:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }
        $data = is_array($model) ? $model : $model->toArray();

        return $this->success($data);
    }

    #[Permission('推送偏好添加', 'help:push:preference:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('推送偏好修改', 'help:push:preference:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('推送偏好删除', 'help:push:preference:destroy')]
    public function destroy(Request $request): Response
    {
        $ids = $request->post('ids', '');
        if (empty($ids)) {
            return $this->fail('请选择要删除的数据');
        }
        $result = $this->logic->destroy($ids);

        return $result ? $this->success('删除成功') : $this->fail('删除失败');
    }

    #[Permission('推送偏好启用', 'help:push:preference:enable')]
    public function enable(Request $request): Response
    {
        $id = trim((string) $request->post('id', ''));
        $result = $this->logic->enable($id);

        return $result ? $this->success('启用成功') : $this->fail('启用失败');
    }

    #[Permission('推送偏好停用', 'help:push:preference:disable')]
    public function disable(Request $request): Response
    {
        $id = trim((string) $request->post('id', ''));
        $result = $this->logic->disable($id);

        return $result ? $this->success('停用成功') : $this->fail('停用失败');
    }
}
