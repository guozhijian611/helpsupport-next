<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\logic\localModel;

use plugin\saiadmin\basic\think\BaseLogic;
use plugin\help\app\model\localModel\SaLocalModelCatalog;

/**
 * 本地模型目录逻辑层
 */
class SaLocalModelCatalogLogic extends BaseLogic
{
    /**
     * 构造函数
     */
    public function __construct()
    {
        $this->model = new SaLocalModelCatalog();
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
        if (array_key_exists('intro_i18n', $data)) {
            $data['intro_i18n'] = $this->normalizeJsonField($data['intro_i18n']);
        }

        return $data;
    }

    private function normalizeJsonField(mixed $value): ?string
    {
        if ($value === '' || $value === null) {
            return null;
        }

        if (is_array($value) || is_object($value)) {
            return json_encode($value, JSON_UNESCAPED_UNICODE);
        }

        return (string) $value;
    }

}
