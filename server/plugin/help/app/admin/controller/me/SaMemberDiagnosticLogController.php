<?php

namespace plugin\help\app\admin\controller\me;

use plugin\help\app\admin\logic\me\SaMemberDiagnosticLogLogic;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * 会员客户端诊断日志控制器
 */
class SaMemberDiagnosticLogController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaMemberDiagnosticLogLogic();
        parent::__construct();
    }

    #[Permission('诊断日志列表', 'help:me:diagnosticLog:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['member_id', ''],
            ['member_keyword', ''],
            ['device_id', ''],
            ['platform', ''],
            ['source', ''],
            ['status', ''],
        ]);

        return $this->success($this->logic->getList($this->logic->search($where)));
    }

    #[Permission('诊断日志读取', 'help:me:diagnosticLog:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        if (!$model) {
            return $this->fail('未查找到信息');
        }

        return $this->success(is_array($model) ? $model : $model->toArray());
    }
}
