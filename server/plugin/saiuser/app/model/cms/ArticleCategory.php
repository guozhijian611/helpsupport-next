<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\saiuser\app\model\cms;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 文章分类模型
 */
class ArticleCategory extends BaseModel
{
    /**
     * 后台操作手册分类标记，写入 describe / link_url，用于和用户端帮助中心隔离。
     */
    public const ADMIN_MANUAL_MARKER = 'audience:admin-manual';

    /**
     * 数据表主键
     * @var string
     */
    protected $pk = 'id';

    /**
     * 数据库表名称
     * @var string
     */
    protected $table = 'sa_article_category';

    /**
     * 分类标题 搜索
     */
    public function searchCategoryNameAttr($query, $value)
    {
        $query->where('category_name', 'like', '%' . $value . '%');
    }

    /**
     * 后台操作手册分类 ID，包含根分类及其子分类。
     *
     * @return list<int>
     */
    public static function adminManualCategoryIds(): array
    {
        $rootIds = self::where('parent_id', 0)
            ->where('describe', 'like', '%' . self::ADMIN_MANUAL_MARKER . '%')
            ->column('id');
        $rootIds = array_values(array_unique(array_map('intval', (array) $rootIds)));
        if ($rootIds === []) {
            return [];
        }

        $childIds = self::whereIn('parent_id', $rootIds)->column('id');
        $childIds = array_values(array_unique(array_map('intval', (array) $childIds)));

        return array_values(array_unique(array_merge($rootIds, $childIds)));
    }

    /**
     * 去掉内部标记后，供手册页展示。
     */
    public static function displayDescribe(?string $describe): string
    {
        $text = trim((string) $describe);
        $text = str_replace(self::ADMIN_MANUAL_MARKER, '', $text);
        return trim($text, " \t\n\r\0\x0B。;；");
    }

}
