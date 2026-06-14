<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\controller\localModel;

use plugin\saiadmin\basic\BaseController;
use plugin\help\app\admin\logic\localModel\SaLocalModelPromptLogic;
use plugin\help\app\admin\validate\localModel\SaLocalModelPromptValidate;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 本地模型提示词控制器
 */
class SaLocalModelPromptController extends BaseController
{
    /**
     * 构造函数
     */
    public function __construct()
    {
        $this->logic = new SaLocalModelPromptLogic();
        $this->validate = new SaLocalModelPromptValidate;
        parent::__construct();
    }

    /**
     * 数据列表
     * @param Request $request
     * @return Response
     */
    #[Permission('本地模型提示词列表', 'help:localModel:prompt:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['chat_mode', ''],
            ['locale', ''],
            ['title', ''],
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
    #[Permission('本地模型提示词读取', 'help:localModel:prompt:read')]
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
    #[Permission('本地模型提示词添加', 'help:localModel:prompt:save')]
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
    #[Permission('本地模型提示词修改', 'help:localModel:prompt:update')]
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
    #[Permission('本地模型提示词删除', 'help:localModel:prompt:destroy')]
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
