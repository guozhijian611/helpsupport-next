<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\controller\audit;

use plugin\saiadmin\basic\BaseController;
use plugin\help\app\admin\logic\audit\SaHelpDoctorProfileLogic;
use plugin\help\app\admin\validate\audit\SaHelpDoctorProfileValidate;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 医生资质审核控制器
 */
class SaHelpDoctorProfileController extends BaseController
{
    /**
     * 构造函数
     */
    public function __construct()
    {
        $this->logic = new SaHelpDoctorProfileLogic();
        $this->validate = new SaHelpDoctorProfileValidate;
        parent::__construct();
    }

    /**
     * 数据列表
     * @param Request $request
     * @return Response
     */
    #[Permission('医生资质审核列表', 'help:audit:profile:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['real_name', ''],
            ['title', ''],
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
    #[Permission('医生资质审核读取', 'help:audit:profile:read')]
    public function read(Request $request): Response
    {
        $id = $request->input('id', '');
        $model = $this->logic->read($id);
        if ($model) {
            $data = is_array($model) ? $model : $model->toArray();
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
    #[Permission('医生资质审核添加', 'help:audit:profile:save')]
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
    #[Permission('医生资质审核修改', 'help:audit:profile:update')]
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
    #[Permission('医生资质审核删除', 'help:audit:profile:destroy')]
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

}
