<?php

namespace plugin\help\app\admin\controller\config;

use plugin\help\app\admin\logic\config\HelpRuntimeConfigLogic;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * HelpSupport 登录与推送配置控制器
 */
class HelpRuntimeConfigController extends BaseController
{
    public function __construct()
    {
        $this->logic = new HelpRuntimeConfigLogic();
        parent::__construct();
    }

    /**
     * 读取登录与推送配置
     */
    #[Permission('登录推送配置读取', 'help:config:runtime:read')]
    public function read(Request $request): Response
    {
        return $this->success($this->logic->read());
    }

    /**
     * 更新登录与推送配置
     */
    #[Permission('登录推送配置更新', 'help:config:runtime:update')]
    public function update(Request $request): Response
    {
        $configs = $request->post('configs', []);
        $this->logic->update(is_array($configs) ? $configs : [], $this->adminId ?? 0);

        return $this->success('保存成功');
    }
}
