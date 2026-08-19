<?php

namespace plugin\help\app\admin\controller\chat;

use plugin\help\app\admin\logic\chat\SaAiPersonaPromptLogic;
use plugin\help\app\admin\validate\chat\SaAiPersonaPromptValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

class SaAiPersonaPromptController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaAiPersonaPromptLogic();
        $this->validate = new SaAiPersonaPromptValidate();
        parent::__construct();
    }

    #[Permission('互动角色列表', 'help:chat:persona:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['persona_id', ''],
            ['runtime_mode', ''],
            ['locale', ''],
        ]);

        return $this->success($this->logic->getList($this->logic->search($where)));
    }

    #[Permission('互动角色读取', 'help:chat:persona:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }

        return $this->success(is_array($model) ? $model : $model->toArray());
    }

    #[Permission('互动角色修改', 'help:chat:persona:update')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);

        return $this->logic->add($data) ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('互动角色修改', 'help:chat:persona:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);

        return $this->logic->edit($data['id'], $data) ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('互动角色修改', 'help:chat:persona:update')]
    public function destroy(Request $request): Response
    {
        $ids = $request->post('ids', '');
        if ($ids === '' || $ids === []) {
            return $this->fail('请选择要删除的数据');
        }

        return $this->logic->destroy($ids) ? $this->success('删除成功') : $this->fail('删除失败');
    }
}
