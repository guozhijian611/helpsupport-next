<?php

namespace plugin\help\app\admin\controller\me;

use plugin\help\app\admin\logic\me\SaMemberJournalLogic;
use plugin\help\app\admin\validate\me\SaMemberJournalValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 会员日记控制器
 */
class SaMemberJournalController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaMemberJournalLogic();
        $this->validate = new SaMemberJournalValidate();
        parent::__construct();
    }

    #[Permission('会员日记列表', 'help:me:journal:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['entry_date', ''],
            ['summary', ''],
            ['is_private', ''],
            ['ai_access', ''],
            ['status', ''],
        ]);

        return $this->success($this->logic->getList($this->logic->search($where)));
    }

    #[Permission('会员日记读取', 'help:me:journal:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }

        return $this->success(is_array($model) ? $model : $model->toArray());
    }

    #[Permission('会员日记添加', 'help:me:journal:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('会员日记修改', 'help:me:journal:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('会员日记删除', 'help:me:journal:destroy')]
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
