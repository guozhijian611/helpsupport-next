<?php

namespace plugin\help\app\admin\controller\risk;

use plugin\help\app\admin\logic\risk\SaSensitiveWordRuleLogic;
use plugin\help\app\admin\validate\risk\SaSensitiveWordRuleValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 敏感词风控规则控制器
 */
class SaSensitiveWordRuleController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaSensitiveWordRuleLogic();
        $this->validate = new SaSensitiveWordRuleValidate();
        parent::__construct();
    }

    #[Permission('敏感词规则列表', 'help:risk:sensitiveWordRule:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['scene', ''],
            ['word', ''],
            ['action', ''],
            ['risk_level', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('敏感词规则读取', 'help:risk:sensitiveWordRule:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }

        return $this->success(is_array($model) ? $model : $model->toArray());
    }

    #[Permission('敏感词规则添加', 'help:risk:sensitiveWordRule:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('敏感词规则修改', 'help:risk:sensitiveWordRule:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('敏感词规则删除', 'help:risk:sensitiveWordRule:destroy')]
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
