<?php

namespace plugin\help\app\admin\controller\message;

use plugin\help\app\admin\logic\message\SaMemberMessageLogic;
use plugin\help\app\admin\validate\message\SaMemberMessageValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 会员消息中心控制器
 */
class SaMemberMessageController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaMemberMessageLogic();
        $this->validate = new SaMemberMessageValidate();
        parent::__construct();
    }

    #[Permission('会员消息列表', 'help:message:memberMessage:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['message_type', ''],
            ['title', ''],
            ['is_pushed', ''],
            ['push_status', ''],
            ['is_read', ''],
            ['biz_type', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('会员消息读取', 'help:message:memberMessage:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }
        $data = is_array($model) ? $model : $model->toArray();

        return $this->success($data);
    }

    #[Permission('会员消息添加', 'help:message:memberMessage:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('会员消息修改', 'help:message:memberMessage:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('会员消息删除', 'help:message:memberMessage:destroy')]
    public function destroy(Request $request): Response
    {
        $ids = $request->post('ids', '');
        if (empty($ids)) {
            return $this->fail('请选择要删除的数据');
        }
        $result = $this->logic->destroy($ids);

        return $result ? $this->success('删除成功') : $this->fail('删除失败');
    }

    #[Permission('会员消息标记已读', 'help:message:memberMessage:markRead')]
    public function markRead(Request $request): Response
    {
        $result = $this->logic->markRead($request->post('ids', ''));

        return $result ? $this->success('标记成功') : $this->fail('标记失败');
    }

    #[Permission('会员消息标记推送成功', 'help:message:memberMessage:markPushed')]
    public function markPushed(Request $request): Response
    {
        $result = $this->logic->markPushed($request->post('ids', ''));

        return $result ? $this->success('标记成功') : $this->fail('标记失败');
    }

    #[Permission('会员消息标记推送失败', 'help:message:memberMessage:markFailed')]
    public function markFailed(Request $request): Response
    {
        $result = $this->logic->markFailed($request->post('ids', ''));

        return $result ? $this->success('标记成功') : $this->fail('标记失败');
    }

    #[Permission('会员消息推送', 'help:message:memberMessage:push')]
    public function push(Request $request): Response
    {
        $ids = $request->post('ids', $request->post('id', ''));
        $result = $this->logic->push($ids);

        return $this->success($result, '推送完成');
    }
}
