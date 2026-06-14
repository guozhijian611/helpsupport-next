<?php

namespace plugin\help\app\admin\controller\me;

use plugin\help\app\admin\logic\me\SaMemberRecoveryGoalLogLogic;
use plugin\help\app\admin\validate\me\SaMemberRecoveryGoalLogValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 康复目标记录控制器
 */
class SaMemberRecoveryGoalLogController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaMemberRecoveryGoalLogLogic();
        $this->validate = new SaMemberRecoveryGoalLogValidate();
        parent::__construct();
    }

    #[Permission('康复目标记录列表', 'help:me:recoveryGoal:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['goal_text', ''],
            ['goal_type', ''],
            ['status', ''],
        ]);

        return $this->success($this->logic->getList($this->logic->search($where)));
    }

    #[Permission('康复目标记录读取', 'help:me:recoveryGoal:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }

        return $this->success(is_array($model) ? $model : $model->toArray());
    }

    #[Permission('康复目标记录添加', 'help:me:recoveryGoal:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('康复目标记录修改', 'help:me:recoveryGoal:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('康复目标记录删除', 'help:me:recoveryGoal:destroy')]
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
