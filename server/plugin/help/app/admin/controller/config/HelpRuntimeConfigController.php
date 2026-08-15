<?php

namespace plugin\help\app\admin\controller\config;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\admin\logic\config\HelpRuntimeConfigLogic;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * HelpSupport 运行配置控制器
 */
class HelpRuntimeConfigController extends BaseController
{
    public function __construct()
    {
        $this->logic = new HelpRuntimeConfigLogic();
        parent::__construct();
    }

    /**
     * 读取运行配置
     */
    #[Apidoc\Title('读取登录推送配置')]
    #[Apidoc\Url('/app/help/admin/config/HelpRuntimeConfig/read')]
    #[Apidoc\Method('GET')]
    #[Permission('运行配置读取', 'help:config:runtime:read')]
    public function read(Request $request): Response
    {
        return $this->success($this->logic->read());
    }

    /**
     * 更新运行配置
     */
    #[Apidoc\Title('更新登录推送配置')]
    #[Apidoc\Url('/app/help/admin/config/HelpRuntimeConfig/update')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('configs', type: 'object', require: true, desc: '按配置组编码组织的配置项')]
    #[Permission('运行配置更新', 'help:config:runtime:update')]
    public function update(Request $request): Response
    {
        $configs = $request->post('configs', []);
        $this->logic->update(is_array($configs) ? $configs : [], $this->adminId ?? 0);

        return $this->success('保存成功');
    }

    #[Apidoc\Title('读取AI审核模型选项')]
    #[Apidoc\Url('/app/help/admin/config/HelpRuntimeConfig/aiOptions')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Returned('value', type: 'string', desc: 'AI配置ID')]
    #[Apidoc\Returned('label', type: 'string', desc: '模型显示名称')]
    #[Permission('AI审核模型选项', 'help:config:runtime:read')]
    public function aiOptions(Request $request): Response
    {
        return $this->success($this->logic->aiOptions());
    }

    /**
     * 读取 App 下载配置
     */
    #[Apidoc\Title('读取 App 下载配置')]
    #[Apidoc\Url('/app/help/admin/config/HelpRuntimeConfig/readDownload')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Returned('code', type: 'string', desc: '配置组编码')]
    #[Apidoc\Returned('items', type: 'array', desc: '下载配置项')]
    #[Permission('App下载配置读取', 'help:config:download:read')]
    public function readDownload(Request $request): Response
    {
        return $this->success($this->logic->readAppDownload());
    }

    /**
     * 更新 App 下载配置
     */
    #[Apidoc\Title('更新 App 下载配置')]
    #[Apidoc\Url('/app/help/admin/config/HelpRuntimeConfig/updateDownload')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('config', type: 'object', require: true, desc: 'App 下载配置键值')]
    #[Permission('App下载配置更新', 'help:config:download:update')]
    public function updateDownload(Request $request): Response
    {
        $config = $request->post('config', []);
        $this->logic->updateAppDownload(is_array($config) ? $config : [], $this->adminId ?? 0);

        return $this->success('保存成功');
    }
}
