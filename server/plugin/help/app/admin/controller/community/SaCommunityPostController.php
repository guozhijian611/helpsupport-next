<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\controller\community;

use hg\apidoc\annotation as Apidoc;
use plugin\saiadmin\basic\BaseController;
use plugin\help\app\admin\logic\community\SaCommunityPostLogic;
use plugin\help\app\admin\validate\community\SaCommunityPostValidate;
use plugin\help\app\service\HelpAuditLogService;
use plugin\help\app\service\HelpAiAuditService;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 社区内容审核控制器
 */
class SaCommunityPostController extends BaseController
{
    /**
     * 构造函数
     */
    public function __construct()
    {
        $this->logic = new SaCommunityPostLogic();
        $this->validate = new SaCommunityPostValidate;
        parent::__construct();
    }

    /**
     * 数据列表
     * @param Request $request
     * @return Response
     */
    #[Permission('社区内容审核列表', 'help:community:post:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['content', ''],
            ['audit_status', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);
        $data = (new HelpAiAuditService())->decoratePage($this->logic->getList($query), 'community_post');
        return $this->success($data);
    }

    /**
     * 读取数据
     * @param Request $request
     * @return Response
     */
    #[Permission('社区内容审核读取', 'help:community:post:read')]
    public function read(Request $request): Response
    {
        $id = $request->input('id', '');
        $model = $this->logic->read($id);
        if ($model) {
            $data = is_array($model) ? $model : $model->toArray();
            $data = (new HelpAiAuditService())->decorateRow($data, 'community_post');
            $data['audit_logs'] = (new HelpAuditLogService())->list('community_post', (int) $id);
            return $this->success($data);
        } else {
            return $this->fail('未查找到信息');
        }
    }

    /**
     * 保存数据
     * @param Request $request
     * @return Response
     */
    #[Permission('社区内容审核添加', 'help:community:post:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);
        if ($result) {
            return $this->success('添加成功');
        } else {
            return $this->fail('添加失败');
        }
    }

    /**
     * 更新数据
     * @param Request $request
     * @return Response
     */
    #[Permission('社区内容审核修改', 'help:community:post:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);
        if ($result) {
            return $this->success('修改成功');
        } else {
            return $this->fail('修改失败');
        }
    }

    /**
     * 删除数据
     * @param Request $request
     * @return Response
     */
    #[Permission('社区内容审核删除', 'help:community:post:destroy')]
    public function destroy(Request $request): Response
    {
        $ids = $request->post('ids', '');
        if (empty($ids)) {
            return $this->fail('请选择要删除的数据');
        }
        $result = $this->logic->destroy($ids);
        if ($result) {
            return $this->success('删除成功');
        } else {
            return $this->fail('删除失败');
        }
    }

    /**
     * 审核帖子
     * @param Request $request
     * @return Response
     */
    #[Permission('社区帖子审核', 'help:community:post:audit')]
    public function audit(Request $request): Response
    {
        $id = (int) $request->post('id', 0);
        $auditStatus = (int) $request->post('audit_status', 0);
        if ($id <= 0) {
            return $this->fail('请选择要审核的帖子');
        }
        $result = $this->logic->audit(
            $id,
            $auditStatus,
            trim((string) $request->post('audit_remark', '')),
            isset($this->adminId) ? $this->adminId : 0
        );

        return $result ? $this->success('审核成功') : $this->fail('审核失败');
    }

    #[Apidoc\Title('重新发起帖子AI审核')]
    #[Apidoc\Url('/app/help/admin/community/SaCommunityPost/aiAudit')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'int', require: true, desc: '帖子ID')]
    #[Permission('社区帖子重新AI审核', 'help:community:post:aiAudit')]
    public function aiAudit(Request $request): Response
    {
        $id = (int) $request->post('id', 0);
        if ($id <= 0) {
            return $this->fail('请选择要审核的帖子');
        }
        $taskId = (new HelpAiAuditService())->retryTarget('community_post', $id, $this->adminId ?? 0);
        return $this->success(['task_id' => $taskId], 'AI审核任务已提交');
    }

}
