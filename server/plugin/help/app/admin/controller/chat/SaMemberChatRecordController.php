<?php

namespace plugin\help\app\admin\controller\chat;

use plugin\help\app\admin\logic\chat\SaMemberChatRecordLogic;
use plugin\help\app\admin\validate\chat\SaMemberChatRecordValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 会员聊天记录控制器
 */
class SaMemberChatRecordController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaMemberChatRecordLogic();
        $this->validate = new SaMemberChatRecordValidate();
        parent::__construct();
    }

    #[Permission('聊天记录列表', 'help:chat:record:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['session_id', ''],
            ['member_id', ''],
            ['chat_mode', ''],
            ['role', ''],
            ['content', ''],
            ['status', ''],
        ]);

        return $this->success($this->logic->getList($this->logic->search($where)));
    }

    #[Permission('聊天记录读取', 'help:chat:record:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }

        return $this->success(is_array($model) ? $model : $model->toArray());
    }

    #[Permission('聊天记录添加', 'help:chat:record:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('聊天记录修改', 'help:chat:record:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('聊天记录删除', 'help:chat:record:destroy')]
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
