<?php

namespace plugin\help\app\admin\controller\me;

use plugin\help\app\admin\logic\me\SaMemberMemoirConfigLogic;
use plugin\help\app\admin\validate\me\SaMemberMemoirConfigValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 回忆录配置控制器
 */
class SaMemberMemoirConfigController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaMemberMemoirConfigLogic();
        $this->validate = new SaMemberMemoirConfigValidate();
        parent::__construct();
    }

    #[Permission('回忆录配置列表', 'help:me:memoirConfig:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['name', ''],
            ['code', ''],
            ['generation_cycle', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('回忆录配置读取', 'help:me:memoirConfig:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }

        return $this->success(is_array($model) ? $model : $model->toArray());
    }

    #[Permission('回忆录配置添加', 'help:me:memoirConfig:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('回忆录配置修改', 'help:me:memoirConfig:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('回忆录配置删除', 'help:me:memoirConfig:destroy')]
    public function destroy(Request $request): Response
    {
        $ids = $request->post('ids', '');
        if (empty($ids)) {
            return $this->fail('请选择要删除的数据');
        }
        $result = $this->logic->destroy($ids);

        return $result ? $this->success('删除成功') : $this->fail('删除失败');
    }

    #[Permission('生成回忆录', 'help:me:memoirConfig:generate')]
    public function generate(Request $request): Response
    {
        $id = (int) $request->post('id', 0);
        $memberId = (int) $request->post('member_id', 0);
        $sourceMonth = (string) $request->post('source_month', '');

        return $this->success($this->logic->generate($id, $memberId, $sourceMonth));
    }
}
