<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: sai <1430792918@qq.com>
// +----------------------------------------------------------------------
namespace plugin\saiadmin\app\controller\system;

use hg\apidoc\annotation as Apidoc;
use plugin\saiadmin\app\logic\system\SystemMailTemplateLogic;
use plugin\saiadmin\app\validate\system\SystemMailTemplateValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 邮件模板控制器
 */
#[Apidoc\Group('系统管理')]
#[Apidoc\Title('邮件模板')]
class SystemMailTemplateController extends BaseController
{
    /**
     * 构造
     */
    public function __construct()
    {
        $this->logic = new SystemMailTemplateLogic();
        $this->validate = new SystemMailTemplateValidate();
        parent::__construct();
    }

    /**
     * 数据列表
     * @param Request $request
     * @return Response
     */
    #[Apidoc\Title('邮件模板列表')]
    #[Apidoc\Url('/core/email-template/index')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('name', type: 'string', require: false, desc: '模板名称')]
    #[Apidoc\Query('code', type: 'string', require: false, desc: '模板标识')]
    #[Apidoc\Query('subject', type: 'string', require: false, desc: '邮件主题')]
    #[Apidoc\Query('status', type: 'int', require: false, desc: '状态')]
    #[Permission('邮件模板列表', 'core:email-template:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['name', ''],
            ['code', ''],
            ['subject', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);
        $data = $this->logic->getList($query);
        return $this->success($data);
    }

    /**
     * 读取数据
     * @param Request $request
     * @return Response
     */
    #[Apidoc\Title('读取邮件模板')]
    #[Apidoc\Url('/core/email-template/read')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('id', type: 'int', require: true, desc: '模板ID')]
    #[Permission('邮件模板读取', 'core:email-template:read')]
    public function read(Request $request): Response
    {
        $id = $request->input('id', '');
        $model = $this->logic->read($id);
        $data = is_array($model) ? $model : $model->toArray();
        return $this->success($data);
    }

    /**
     * 保存数据
     * @param Request $request
     * @return Response
     */
    #[Apidoc\Title('新增邮件模板')]
    #[Apidoc\Url('/core/email-template/save')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('name', type: 'string', require: true, desc: '模板名称')]
    #[Apidoc\Param('code', type: 'string', require: true, desc: '模板标识')]
    #[Apidoc\Param('subject', type: 'string', require: true, desc: '邮件主题')]
    #[Apidoc\Param('content', type: 'string', require: true, desc: '邮件内容')]
    #[Apidoc\Param('variables', type: 'string', require: false, desc: '变量说明')]
    #[Apidoc\Param('sort', type: 'int', require: false, desc: '排序')]
    #[Apidoc\Param('status', type: 'int', require: true, desc: '状态')]
    #[Apidoc\Param('remark', type: 'string', require: false, desc: '备注')]
    #[Permission('邮件模板添加', 'core:email-template:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);
        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    /**
     * 更新数据
     * @param Request $request
     * @return Response
     */
    #[Apidoc\Title('修改邮件模板')]
    #[Apidoc\Url('/core/email-template/update')]
    #[Apidoc\Method('PUT')]
    #[Apidoc\Param('id', type: 'int', require: true, desc: '模板ID')]
    #[Apidoc\Param('name', type: 'string', require: true, desc: '模板名称')]
    #[Apidoc\Param('code', type: 'string', require: true, desc: '模板标识')]
    #[Apidoc\Param('subject', type: 'string', require: true, desc: '邮件主题')]
    #[Apidoc\Param('content', type: 'string', require: true, desc: '邮件内容')]
    #[Apidoc\Param('variables', type: 'string', require: false, desc: '变量说明')]
    #[Apidoc\Param('sort', type: 'int', require: false, desc: '排序')]
    #[Apidoc\Param('status', type: 'int', require: true, desc: '状态')]
    #[Apidoc\Param('remark', type: 'string', require: false, desc: '备注')]
    #[Permission('邮件模板修改', 'core:email-template:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);
        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    /**
     * 删除数据
     * @param Request $request
     * @return Response
     */
    #[Apidoc\Title('删除邮件模板')]
    #[Apidoc\Url('/core/email-template/destroy')]
    #[Apidoc\Method('DELETE')]
    #[Apidoc\Param('ids', type: 'array', require: true, desc: '模板ID数组')]
    #[Permission('邮件模板删除', 'core:email-template:destroy')]
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
