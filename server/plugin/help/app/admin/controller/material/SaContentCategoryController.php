<?php

namespace plugin\help\app\admin\controller\material;

use plugin\help\app\admin\logic\material\SaContentCategoryLogic;
use plugin\help\app\admin\validate\material\SaContentCategoryValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 内容分类控制器
 */
class SaContentCategoryController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaContentCategoryLogic();
        $this->validate = new SaContentCategoryValidate();
        parent::__construct();
    }

    #[Permission('内容分类列表', 'help:material:category:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['parent_id', ''],
            ['member_id', ''],
            ['name', ''],
            ['type', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('内容分类读取', 'help:material:category:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }
        $data = is_array($model) ? $model : $model->toArray();

        return $this->success($data);
    }

    #[Permission('内容分类添加', 'help:material:category:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('内容分类修改', 'help:material:category:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('内容分类删除', 'help:material:category:destroy')]
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
