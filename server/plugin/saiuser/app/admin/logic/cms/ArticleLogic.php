<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\saiuser\app\admin\logic\cms;

use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use plugin\saiadmin\utils\Helper;
use plugin\saiuser\app\model\cms\Article;
use plugin\saiuser\app\model\cms\ArticleCategory;

/**
 * 文章列表逻辑层
 */
class ArticleLogic extends BaseLogic
{
    /**
     * 构造函数
     */
    public function __construct()
    {
        $this->model = new Article();
    }

    /**
     * 读取数据
     * @param $id
     * @return array
     */
    public function read($id): array
    {
        $admin = $this->model->find($id);
        $data = $admin->toArray();
        $data['category'] = $admin->category->toArray() ?: [];
        return $data;
    }

    /**
     * 后台操作手册目录，只返回管理员手册分类和已发布文章。
     *
     * @return array{categories: list<array<string, mixed>>}
     */
    public function getManualCatalog(): array
    {
        $categoryIds = ArticleCategory::adminManualCategoryIds();
        if ($categoryIds === []) {
            return ['categories' => []];
        }

        $rootIds = ArticleCategory::where('parent_id', 0)
            ->where('describe', 'like', '%' . ArticleCategory::ADMIN_MANUAL_MARKER . '%')
            ->where('status', 1)
            ->column('id');
        $rootIds = array_values(array_unique(array_map('intval', (array) $rootIds)));
        if ($rootIds === []) {
            return ['categories' => []];
        }

        $categories = ArticleCategory::whereIn('parent_id', $rootIds)
            ->where('status', 1)
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();

        $articles = Article::whereIn('category_id', $categoryIds)
            ->where('status', 1)
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();

        $grouped = [];
        foreach ($articles as $article) {
            $categoryId = (int) ($article['category_id'] ?? 0);
            $grouped[$categoryId][] = [
                'id' => (int) ($article['id'] ?? 0),
                'title' => (string) ($article['title'] ?? ''),
                'describe' => (string) ($article['describe'] ?? ''),
                'sort' => (int) ($article['sort'] ?? 0),
            ];
        }

        $result = [];
        foreach ($categories as $category) {
            $categoryId = (int) ($category['id'] ?? 0);
            $items = $grouped[$categoryId] ?? [];
            if ($items === []) {
                continue;
            }
            $result[] = [
                'id' => $categoryId,
                'category_name' => (string) ($category['category_name'] ?? ''),
                'describe' => ArticleCategory::displayDescribe($category['describe'] ?? ''),
                'sort' => (int) ($category['sort'] ?? 0),
                'articles' => $items,
            ];
        }

        return ['categories' => $result];
    }

    /**
     * 读取一篇后台操作手册文章。
     *
     * @return array<string, mixed>
     */
    public function getManualArticle($id): array
    {
        $article = Article::with('category')->where('id', $id)->where('status', 1)->findOrEmpty();
        if ($article->isEmpty()) {
            return [];
        }

        $categoryIds = ArticleCategory::adminManualCategoryIds();
        if (!in_array((int) $article->category_id, $categoryIds, true)) {
            return [];
        }

        $data = $article->toArray();
        $category = is_array($data['category'] ?? null) ? $data['category'] : [];
        if ($category !== []) {
            $category['describe'] = ArticleCategory::displayDescribe($category['describe'] ?? '');
            $data['category'] = $category;
        }
        return $data;
    }

}
