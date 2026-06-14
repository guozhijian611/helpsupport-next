<?php

namespace plugin\help\app\admin\controller\gamification;

use plugin\help\app\admin\logic\gamification\SaMemberBadgeRuleLogic;
use plugin\help\app\admin\validate\gamification\SaMemberBadgeRuleValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 荣誉徽章规则控制器
 */
class SaMemberBadgeRuleController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaMemberBadgeRuleLogic();
        $this->validate = new SaMemberBadgeRuleValidate();
        parent::__construct();
    }

    #[Permission('荣誉徽章规则列表', 'help:gamification:badgeRule:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['name', ''],
            ['code', ''],
            ['trigger_type', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('荣誉徽章规则读取', 'help:gamification:badgeRule:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }

        return $this->success(is_array($model) ? $model : $model->toArray());
    }

    #[Permission('荣誉徽章规则添加', 'help:gamification:badgeRule:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('荣誉徽章规则修改', 'help:gamification:badgeRule:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('荣誉徽章规则删除', 'help:gamification:badgeRule:destroy')]
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
