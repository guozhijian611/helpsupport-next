<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\saiuser\app\admin\controller\member;

use plugin\saiadmin\basic\BaseController;
use plugin\saiuser\app\admin\logic\member\MemberPointsLogLogic;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 积分日志控制器
 */
class MemberPointsLogController extends BaseController
{
    /**
     * 构造函数
     */
    public function __construct()
    {
        $this->logic = new MemberPointsLogLogic();
        parent::__construct();
    }

    /**
     * 数据列表
     * @param Request $request
     * @return Response
     */
    #[Permission('积分日志列表', 'saiuser:member:points:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['operate_type', ''],
            ['change_type', ''],
            ['source_type', ''],
            ['username', ''],
            ['create_time', ''],
        ]);
        $query = $this->logic->search($where);
        $query->with(['member']);
        $data = $this->logic->getList($query);
        return $this->success($data);
    }

    /**
     * 读取数据
     * @param Request $request
     * @return Response
     */
    #[Permission('积分日志读取', 'saiuser:member:points:read')]
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
     * 删除数据
     * @param Request $request
     * @return Response
     */
    #[Permission('积分日志删除', 'saiuser:member:points:destroy')]
    public function destroy(Request $request): Response
    {
        return $this->fail('积分日志不支持删除');
    }
}
