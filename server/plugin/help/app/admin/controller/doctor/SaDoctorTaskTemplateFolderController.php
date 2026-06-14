<?php

namespace plugin\help\app\admin\controller\doctor;

use plugin\help\app\admin\logic\doctor\SaDoctorTaskTemplateFolderLogic;
use plugin\help\app\admin\validate\doctor\SaDoctorTaskTemplateFolderValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 医生任务模板文件夹控制器
 */
class SaDoctorTaskTemplateFolderController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaDoctorTaskTemplateFolderLogic();
        $this->validate = new SaDoctorTaskTemplateFolderValidate();
        parent::__construct();
    }

    #[Permission('任务模板文件夹列表', 'help:doctor:taskTemplateFolder:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['doctor_id', ''],
            ['name', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);

        return $this->success($this->logic->getList($query));
    }

    #[Permission('任务模板文件夹读取', 'help:doctor:taskTemplateFolder:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }
        $data = is_array($model) ? $model : $model->toArray();

        return $this->success($data);
    }

    #[Permission('任务模板文件夹添加', 'help:doctor:taskTemplateFolder:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('任务模板文件夹修改', 'help:doctor:taskTemplateFolder:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('任务模板文件夹删除', 'help:doctor:taskTemplateFolder:destroy')]
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
