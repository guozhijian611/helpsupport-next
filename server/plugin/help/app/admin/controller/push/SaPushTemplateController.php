<?php

namespace plugin\help\app\admin\controller\push;

use plugin\help\app\admin\logic\push\SaPushTemplateLogic;
use plugin\help\app\admin\validate\push\SaPushTemplateValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 推送模板控制器
 */
class SaPushTemplateController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaPushTemplateLogic();
        $this->validate = new SaPushTemplateValidate();
        parent::__construct();
    }

    #[Permission('推送模板列表', 'help:push:template:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['template_code', ''],
            ['template_name', ''],
            ['scene', ''],
            ['locale', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('推送模板读取', 'help:push:template:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }
        $data = is_array($model) ? $model : $model->toArray();

        return $this->success($data);
    }

    #[Permission('推送模板添加', 'help:push:template:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('推送模板修改', 'help:push:template:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('推送模板删除', 'help:push:template:destroy')]
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
