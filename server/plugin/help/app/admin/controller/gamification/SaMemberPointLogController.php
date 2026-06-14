<?php

namespace plugin\help\app\admin\controller\gamification;

use plugin\help\app\admin\logic\gamification\SaMemberPointLogLogic;
use plugin\help\app\admin\validate\gamification\SaMemberPointLogValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 积分流水控制器
 */
class SaMemberPointLogController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaMemberPointLogLogic();
        $this->validate = new SaMemberPointLogValidate();
        parent::__construct();
    }

    #[Permission('积分流水列表', 'help:gamification:pointLog:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['change_type', ''],
            ['source_type', ''],
            ['title', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('积分流水读取', 'help:gamification:pointLog:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }

        return $this->success(is_array($model) ? $model : $model->toArray());
    }

    #[Permission('积分流水添加', 'help:gamification:pointLog:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('积分流水修改', 'help:gamification:pointLog:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('积分流水删除', 'help:gamification:pointLog:destroy')]
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
