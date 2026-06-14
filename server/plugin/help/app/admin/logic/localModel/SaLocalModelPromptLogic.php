<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\logic\localModel;

use plugin\saiadmin\basic\think\BaseLogic;
use plugin\help\app\model\localModel\SaLocalModelPrompt;

/**
 * 本地模型提示词逻辑层
 */
class SaLocalModelPromptLogic extends BaseLogic
{
    /**
     * 构造函数
     */
    public function __construct()
    {
        $this->model = new SaLocalModelPrompt();
    }

    public function add(array $data): mixed
    {
        return parent::add($this->normalizeFields($data));
    }

    public function edit($id, array $data): mixed
    {
        return parent::edit($id, $this->normalizeFields($data));
    }

    private function normalizeFields(array $data): array
    {
        if (array_key_exists('model_id', $data) && ($data['model_id'] === '' || $data['model_id'] === 0)) {
            $data['model_id'] = null;
        }

        return $data;
    }

}
