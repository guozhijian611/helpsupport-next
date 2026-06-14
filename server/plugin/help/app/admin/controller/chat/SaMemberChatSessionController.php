<?php

namespace plugin\help\app\admin\controller\chat;

use plugin\help\app\admin\logic\chat\SaMemberChatSessionLogic;
use plugin\help\app\admin\validate\chat\SaMemberChatSessionValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 会员聊天会话控制器
 */
class SaMemberChatSessionController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaMemberChatSessionLogic();
        $this->validate = new SaMemberChatSessionValidate();
        parent::__construct();
    }

    #[Permission('聊天会话列表', 'help:chat:session:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['chat_mode', ''],
            ['session_name', ''],
            ['status', ''],
        ]);

        return $this->success($this->logic->getList($this->logic->search($where)));
    }

    #[Permission('聊天会话读取', 'help:chat:session:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }

        return $this->success(is_array($model) ? $model : $model->toArray());
    }

    #[Permission('聊天会话添加', 'help:chat:session:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('聊天会话修改', 'help:chat:session:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('聊天会话删除', 'help:chat:session:destroy')]
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
