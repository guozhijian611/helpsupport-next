<?php

namespace plugin\help\app\admin\controller\material;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\admin\logic\material\SaMaterialCommentLogic;
use plugin\help\app\admin\validate\material\SaMaterialCommentValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 素材评论管理控制器
 */
#[Apidoc\Group('HelpSupport 后台素材管理')]
#[Apidoc\Title('素材评论管理')]
class SaMaterialCommentController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaMaterialCommentLogic();
        $this->validate = new SaMaterialCommentValidate();
        parent::__construct();
    }

    #[Apidoc\Title('素材评论列表')]
    #[Apidoc\Url('/app/help/admin/material/SaMaterialComment/index')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('material_type', type: 'string', require: false, desc: '素材类型 education/entertainment')]
    #[Apidoc\Query('material_id', type: 'int', require: false, desc: '素材ID')]
    #[Apidoc\Query('material_title', type: 'string', require: false, desc: '素材标题')]
    #[Apidoc\Query('member_id', type: 'int', require: false, desc: '会员ID')]
    #[Apidoc\Query('content', type: 'string', require: false, desc: '评论内容')]
    #[Apidoc\Query('status', type: 'int', require: false, desc: '状态 1正常 2隐藏')]
    #[Apidoc\Returned('list', type: 'array', desc: '评论分页列表')]
    #[Permission('素材评论列表', 'help:material:comment:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['material_type', ''],
            ['material_id', ''],
            ['material_title', ''],
            ['member_id', ''],
            ['content', ''],
            ['status', ''],
        ]);

        return $this->success($this->logic->getAdminList($where));
    }

    #[Apidoc\Title('素材评论读取')]
    #[Apidoc\Url('/app/help/admin/material/SaMaterialComment/read')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('id', type: 'int', require: true, desc: '评论ID')]
    #[Apidoc\Returned('id', type: 'int', desc: '评论ID')]
    #[Permission('素材评论读取', 'help:material:comment:read')]
    public function read(Request $request): Response
    {
        $data = $this->logic->readDetail((int) $request->input('id', 0));
        if ($data === []) {
            return $this->fail('未查找到素材评论');
        }

        return $this->success($data);
    }

    #[Apidoc\Title('素材评论状态')]
    #[Apidoc\Url('/app/help/admin/material/SaMaterialComment/status')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'int', require: true, desc: '评论ID')]
    #[Apidoc\Param('status', type: 'int', require: true, desc: '状态 1正常 2隐藏')]
    #[Apidoc\Param('remark', type: 'string', require: false, desc: '处理备注')]
    #[Permission('素材评论状态', 'help:material:comment:status')]
    public function status(Request $request): Response
    {
        $data = $request->post();
        $this->validate('status', $data);
        $result = $this->logic->setStatus(
            (int) $data['id'],
            (int) $data['status'],
            trim((string) ($data['remark'] ?? '')),
            isset($this->adminId) ? (int) $this->adminId : 0
        );

        return $result ? $this->success('处理成功') : $this->fail('处理失败');
    }

    #[Apidoc\Title('素材评论删除')]
    #[Apidoc\Url('/app/help/admin/material/SaMaterialComment/destroy')]
    #[Apidoc\Method('DELETE')]
    #[Apidoc\Param('ids', type: 'array', require: true, desc: '评论ID列表')]
    #[Permission('素材评论删除', 'help:material:comment:destroy')]
    public function destroy(Request $request): Response
    {
        $ids = $request->post('ids', '');
        if (empty($ids)) {
            return $this->fail('请选择要删除的数据');
        }
        $result = $this->logic->deleteComments($ids, isset($this->adminId) ? (int) $this->adminId : 0);

        return $result ? $this->success('删除成功') : $this->fail('删除失败');
    }
}
