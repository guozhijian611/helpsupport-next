<?php

namespace plugin\help\app\admin\controller\community;

use plugin\help\app\admin\logic\community\SaCommunityCommentLogic;
use plugin\help\app\admin\validate\community\SaCommunityCommentValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 社区评论管理控制器
 */
class SaCommunityCommentController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaCommunityCommentLogic();
        $this->validate = new SaCommunityCommentValidate();
        parent::__construct();
    }

    #[Permission('社区评论列表', 'help:community:comment:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['post_id', ''],
            ['member_id', ''],
            ['content', ''],
            ['audit_status', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('社区评论读取', 'help:community:comment:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        $data = is_array($model) ? $model : $model->toArray();

        return $this->success($data);
    }

    #[Permission('社区评论添加', 'help:community:comment:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('社区评论修改', 'help:community:comment:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('社区评论删除', 'help:community:comment:destroy')]
    public function destroy(Request $request): Response
    {
        $ids = $request->post('ids', '');
        if (empty($ids)) {
            return $this->fail('请选择要删除的数据');
        }
        $result = $this->logic->destroy($ids);

        return $result ? $this->success('删除成功') : $this->fail('删除失败');
    }

    #[Permission('社区评论审核', 'help:community:comment:audit')]
    public function audit(Request $request): Response
    {
        $id = (int) $request->post('id', 0);
        $auditStatus = (int) $request->post('audit_status', 0);
        if ($id <= 0) {
            return $this->fail('请选择要审核的评论');
        }
        $result = $this->logic->audit(
            $id,
            $auditStatus,
            isset($this->adminId) ? $this->adminId : 0
        );

        return $result ? $this->success('审核成功') : $this->fail('审核失败');
    }
}
