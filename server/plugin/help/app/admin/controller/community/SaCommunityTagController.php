<?php

namespace plugin\help\app\admin\controller\community;

use plugin\help\app\admin\logic\community\SaCommunityTagLogic;
use plugin\help\app\admin\validate\community\SaCommunityTagValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 社区标签控制器
 */
class SaCommunityTagController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaCommunityTagLogic();
        $this->validate = new SaCommunityTagValidate();
        parent::__construct();
    }

    #[Permission('社区标签列表', 'help:community:tag:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['tag_name', ''],
            ['status', ''],
        ]);

        return $this->success($this->logic->getList($this->logic->search($where)));
    }

    #[Permission('社区标签读取', 'help:community:tag:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }

        return $this->success(is_array($model) ? $model : $model->toArray());
    }

    #[Permission('社区标签添加', 'help:community:tag:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('社区标签修改', 'help:community:tag:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('社区标签删除', 'help:community:tag:destroy')]
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
