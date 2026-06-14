<?php

namespace plugin\help\app\admin\controller\plan;

use plugin\help\app\admin\logic\plan\SaDailyTaskLogic;
use plugin\help\app\admin\validate\plan\SaDailyTaskValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 每日任务控制器
 */
class SaDailyTaskController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaDailyTaskLogic();
        $this->validate = new SaDailyTaskValidate();
        parent::__construct();
    }

    #[Permission('每日任务列表', 'help:plan:dailyTask:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['plan_id', ''],
            ['stage_id', ''],
            ['task_date', ''],
            ['title', ''],
            ['task_type', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('每日任务读取', 'help:plan:dailyTask:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        $data = is_array($model) ? $model : $model->toArray();

        return $this->success($data);
    }

    #[Permission('每日任务添加', 'help:plan:dailyTask:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('每日任务修改', 'help:plan:dailyTask:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('每日任务删除', 'help:plan:dailyTask:destroy')]
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
