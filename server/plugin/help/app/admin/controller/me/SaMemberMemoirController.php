<?php

namespace plugin\help\app\admin\controller\me;

use plugin\help\app\admin\logic\me\SaMemberMemoirLogic;
use plugin\help\app\admin\validate\me\SaMemberMemoirValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 会员回忆录控制器
 */
class SaMemberMemoirController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaMemberMemoirLogic();
        $this->validate = new SaMemberMemoirValidate();
        parent::__construct();
    }

    #[Permission('会员回忆录列表', 'help:me:memoir:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['config_id', ''],
            ['title', ''],
            ['source_month', ''],
            ['status', ''],
        ]);

        return $this->success($this->logic->getList($this->logic->search($where)));
    }

    #[Permission('会员回忆录读取', 'help:me:memoir:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }

        return $this->success(is_array($model) ? $model : $model->toArray());
    }

    #[Permission('会员回忆录添加', 'help:me:memoir:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('会员回忆录修改', 'help:me:memoir:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('会员回忆录删除', 'help:me:memoir:destroy')]
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
