<?php

namespace plugin\help\app\admin\controller\chat;

use plugin\help\app\admin\logic\chat\SaAiPersonaLogic;
use plugin\help\app\admin\validate\chat\SaAiPersonaValidate;
use plugin\help\app\service\ChatPersonaCatalog;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

class SaAiPersonaController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaAiPersonaLogic();
        $this->validate = new SaAiPersonaValidate();
        parent::__construct();
    }

    #[Permission('互动角色列表', 'help:chat:persona:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['code', ''],
            ['status', ''],
        ]);
        $data = $this->logic->getList($this->logic->search($where));
        if (isset($data['data']) && is_array($data['data'])) {
            $data['data'] = array_map(static function (mixed $row): array {
                $item = is_array($row) ? $row : (method_exists($row, 'toArray') ? $row->toArray() : []);
                return ChatPersonaCatalog::normalize($item);
            }, $data['data']);
        }

        return $this->success($data);
    }

    #[Permission('互动角色读取', 'help:chat:persona:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }
        $row = is_array($model) ? $model : $model->toArray();

        return $this->success(ChatPersonaCatalog::normalize($row));
    }

    #[Permission('互动角色添加', 'help:chat:persona:save')]
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

    #[Permission('互动角色删除', 'help:chat:persona:destroy')]
    public function destroy(Request $request): Response
    {
        $ids = $request->post('ids', '');
        if ($ids === '' || $ids === []) {
            return $this->fail('请选择要删除的数据');
        }

        return $this->logic->destroy($ids) ? $this->success('删除成功') : $this->fail('删除失败');
    }

    #[Permission('互动角色列表', 'help:chat:persona:index')]
    public function options(): Response
    {
        return $this->success($this->logic->options());
    }
}
