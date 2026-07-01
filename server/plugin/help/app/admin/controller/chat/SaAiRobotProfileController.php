<?php

namespace plugin\help\app\admin\controller\chat;

use plugin\help\app\admin\logic\chat\SaAiRobotProfileLogic;
use plugin\help\app\admin\validate\chat\SaAiRobotProfileValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * AI 机器人形象配置控制器
 */
class SaAiRobotProfileController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaAiRobotProfileLogic();
        $this->validate = new SaAiRobotProfileValidate();
        parent::__construct();
    }

    #[Permission('AI机器人形象列表', 'help:chat:robotProfile:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['chat_mode', ''],
            ['runtime_mode', ''],
            ['display_name', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);
        $data = $this->logic->getList($query);
        return $this->success($data);
    }

    #[Permission('AI机器人形象读取', 'help:chat:robotProfile:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }

        return $this->success(is_array($model) ? $model : $model->toArray());
    }

    #[Permission('AI机器人形象添加', 'help:chat:robotProfile:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);
        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('AI机器人形象修改', 'help:chat:robotProfile:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);
        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('AI机器人形象删除', 'help:chat:robotProfile:destroy')]
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
