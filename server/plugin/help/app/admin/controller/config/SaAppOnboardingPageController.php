<?php

declare(strict_types=1);

namespace plugin\help\app\admin\controller\config;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\admin\logic\config\SaAppOnboardingPageLogic;
use plugin\help\app\admin\validate\config\SaAppOnboardingPageValidate;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;

/**
 * App引导页配置控制器
 */
#[Apidoc\Group('运营配置')]
#[Apidoc\Title('App引导页配置')]
class SaAppOnboardingPageController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaAppOnboardingPageLogic();
        $this->validate = new SaAppOnboardingPageValidate();
        parent::__construct();
    }

    #[Apidoc\Title('App引导页配置列表')]
    #[Apidoc\Url('/app/help/admin/config/SaAppOnboardingPage/index')]
    #[Apidoc\Method('GET')]
    #[Permission('App引导页配置列表', 'help:config:page:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['title', ''],
            ['action_type', ''],
        ]);
        $query = $this->logic->search($where);
        $data = $this->logic->getList($query);

        return $this->success($data);
    }

    #[Apidoc\Title('App引导页故事板')]
    #[Apidoc\Url('/app/help/admin/config/SaAppOnboardingPage/storyboard')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('scene', type: 'string', require: false, default: 'first_launch', desc: '引导场景')]
    #[Apidoc\Query('version', type: 'string', require: false, default: '', desc: '配置版本，空值表示默认版本')]
    #[Apidoc\Returned('scene', type: 'string', desc: '当前场景')]
    #[Apidoc\Returned('version', type: 'string', desc: '当前版本')]
    #[Apidoc\Returned('locales', type: 'array', desc: '当前流程已配置语言')]
    #[Apidoc\Returned('next_sort', type: 'int', desc: '下一页默认排序值')]
    #[Apidoc\Returned('slides', type: 'array', desc: '按播放顺序分组的幻灯片')]
    #[Apidoc\Returned('flows', type: 'array', desc: '全部引导流程摘要')]
    #[Permission('App引导页配置列表', 'help:config:page:index')]
    public function storyboard(Request $request): Response
    {
        $scene = (string) $request->get('scene', 'first_launch');
        $version = (string) $request->get('version', '');

        return $this->success($this->pageLogic()->storyboard($scene, $version));
    }

    #[Apidoc\Title('App引导页播放顺序')]
    #[Apidoc\Url('/app/help/admin/config/SaAppOnboardingPage/reorder')]
    #[Apidoc\Method('PUT')]
    #[Apidoc\Param('scene', type: 'string', require: true, desc: '引导场景')]
    #[Apidoc\Param('version', type: 'string', require: false, default: '', desc: '配置版本')]
    #[Apidoc\Param('slide_ids', type: 'array', require: true, desc: '按新播放顺序排列的代表页 ID')]
    #[Permission('App引导页配置修改', 'help:config:page:update')]
    public function reorder(Request $request): Response
    {
        $data = $request->post();
        $this->validate('reorder', $data);
        $this->pageLogic()->reorder(
            (string) ($data['scene'] ?? 'first_launch'),
            (string) ($data['version'] ?? ''),
            is_array($data['slide_ids'] ?? null) ? $data['slide_ids'] : [],
        );

        return $this->success('排序已更新');
    }

    #[Apidoc\Title('复制App引导页流程')]
    #[Apidoc\Url('/app/help/admin/config/SaAppOnboardingPage/copyFlow')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('source_scene', type: 'string', require: true, desc: '源场景')]
    #[Apidoc\Param('source_version', type: 'string', require: false, default: '', desc: '源版本')]
    #[Apidoc\Param('scene', type: 'string', require: true, desc: '目标场景')]
    #[Apidoc\Param('version', type: 'string', require: false, default: '', desc: '目标版本')]
    #[Permission('App引导页配置添加', 'help:config:page:save')]
    public function copyFlow(Request $request): Response
    {
        $data = $request->post();
        $this->validate('copyFlow', $data);
        $count = $this->pageLogic()->copyFlow(
            (string) ($data['source_scene'] ?? 'first_launch'),
            (string) ($data['source_version'] ?? ''),
            (string) ($data['scene'] ?? 'first_launch'),
            (string) ($data['version'] ?? ''),
        );

        return $this->success('已复制 ' . $count . ' 条引导页');
    }

    #[Apidoc\Title('发布App引导页版本')]
    #[Apidoc\Url('/app/help/admin/config/SaAppOnboardingPage/publishFlow')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('scene', type: 'string', require: true, desc: '引导场景')]
    #[Apidoc\Param('version', type: 'string', require: true, desc: '要发布为 App 当前使用的草稿版本号')]
    #[Permission('App引导页配置修改', 'help:config:page:update')]
    public function publishFlow(Request $request): Response
    {
        $data = $request->post();
        $this->validate('publishFlow', $data);
        $archive = $this->pageLogic()->publishFlow(
            (string) ($data['scene'] ?? 'first_launch'),
            (string) ($data['version'] ?? ''),
        );

        return $this->success('已发布为 App 当前版本，原默认版本已归档为 ' . $archive);
    }

    #[Apidoc\Title('重命名App引导页版本')]
    #[Apidoc\Url('/app/help/admin/config/SaAppOnboardingPage/renameFlow')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('scene', type: 'string', require: true, desc: '引导场景')]
    #[Apidoc\Param('version', type: 'string', require: true, desc: '当前版本号')]
    #[Apidoc\Param('new_version', type: 'string', require: true, desc: '新版本号')]
    #[Permission('App引导页配置修改', 'help:config:page:update')]
    public function renameFlow(Request $request): Response
    {
        $data = $request->post();
        $this->validate('renameFlow', $data);
        $this->pageLogic()->renameFlow(
            (string) ($data['scene'] ?? 'first_launch'),
            (string) ($data['version'] ?? ''),
            (string) ($data['new_version'] ?? ''),
        );

        return $this->success('版本号已更新');
    }

    #[Apidoc\Title('删除App引导页版本')]
    #[Apidoc\Url('/app/help/admin/config/SaAppOnboardingPage/destroyFlow')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('scene', type: 'string', require: true, desc: '引导场景')]
    #[Apidoc\Param('version', type: 'string', require: false, default: '', desc: '要删除的版本，空值表示默认版本')]
    #[Permission('App引导页配置删除', 'help:config:page:destroy')]
    public function destroyFlow(Request $request): Response
    {
        $data = $request->post();
        $this->validate('destroyFlow', $data);
        $count = $this->pageLogic()->destroyFlow(
            (string) ($data['scene'] ?? 'first_launch'),
            (string) ($data['version'] ?? ''),
        );

        return $this->success('已删除该版本的 ' . $count . ' 条引导页');
    }

    #[Apidoc\Title('App引导页配置读取')]
    #[Apidoc\Url('/app/help/admin/config/SaAppOnboardingPage/read')]
    #[Apidoc\Method('GET')]
    #[Permission('App引导页配置读取', 'help:config:page:read')]
    public function read(Request $request): Response
    {
        $id = $request->input('id', '');
        $model = $this->logic->read($id);
        if ($model) {
            $data = is_array($model) ? $model : $model->toArray();

            return $this->success($data);
        }

        return $this->fail('未查找到信息');
    }

    #[Apidoc\Title('App引导页配置添加')]
    #[Apidoc\Url('/app/help/admin/config/SaAppOnboardingPage/save')]
    #[Apidoc\Method('POST')]
    #[Permission('App引导页配置添加', 'help:config:page:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Apidoc\Title('App引导页配置修改')]
    #[Apidoc\Url('/app/help/admin/config/SaAppOnboardingPage/update')]
    #[Apidoc\Method('PUT')]
    #[Permission('App引导页配置修改', 'help:config:page:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Apidoc\Title('App引导页配置删除')]
    #[Apidoc\Url('/app/help/admin/config/SaAppOnboardingPage/destroy')]
    #[Apidoc\Method('DELETE')]
    #[Permission('App引导页配置删除', 'help:config:page:destroy')]
    public function destroy(Request $request): Response
    {
        $ids = $request->post('ids', '');
        if (empty($ids)) {
            return $this->fail('请选择要删除的数据');
        }
        $result = $this->logic->destroy($ids);

        return $result ? $this->success('删除成功') : $this->fail('删除失败');
    }

    private function pageLogic(): SaAppOnboardingPageLogic
    {
        /** @var SaAppOnboardingPageLogic $logic */
        $logic = $this->logic;

        return $logic;
    }
}
