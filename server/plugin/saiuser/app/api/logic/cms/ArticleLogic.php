<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\saiuser\app\api\logic\cms;

use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiuser\app\model\cms\ArticleBanner;
use plugin\saiuser\app\model\cms\ArticleCategory;
use plugin\saiuser\app\model\cms\Article;

/**
 * 新闻中心逻辑层
 */
class ArticleLogic extends BaseLogic
{
    /**
     * 轮播图列表
     * @return array
     */
    public function bannerList()
    {
        $data = ArticleBanner::where('status', 1)->select()->toArray();
        return $data;
    }

    /**
     * 分类列表
     * @return array
     */
    public function categoryList()
    {
        $query = ArticleCategory::where('status', 1);
        $query = $this->excludeAdminManualCategories($query);
        return $query->select()->toArray();
    }

    /**
     * 文章列表
     * @param mixed $category_id
     * @return array
     */
    public function articleList($category_id)
    {
        $this->setOrderField('create_time');
        $this->setOrderType('desc');
        $query = Article::where('status', 1)->order('sort', 'desc');
        $query = $this->excludeAdminManualArticles($query);
        if (!empty($category_id)) {
            if ($this->isAdminManualCategory((int) $category_id)) {
                return $this->getList($query->where('id', 0));
            }
            $query = $query->where('category_id', $category_id);
        }
        return $this->getList($query);
    }

    /**
     * 热门文章
     * @return array
     */
    public function hotArticleList()
    {
        $query = Article::where('status', 1)->order('views', 'desc');
        $query = $this->excludeAdminManualArticles($query);
        return $query->limit(5)->select()->toArray();
    }

    /**
     * 随机文章
     * @return array
     */
    public function randomArticleList($limit)
    {
        $query = Article::where('status', 1)->orderRaw('RAND()');
        $query = $this->excludeAdminManualArticles($query);
        return $query->limit($limit)->select()->toArray();
    }

    /**
     * 文章详情
     * @param mixed $id
     * @return array
     */
    public function getArticle($id)
    {
        $data = Article::with('publisher')->where('id', $id)->where('status', 1)->findOrEmpty();
        if ($data->isEmpty() || $this->isAdminManualCategory((int) $data->category_id)) {
            return [];
        }
        $data->views = $data->views + 1;
        $data->save();
        return $data->toArray();
    }

    /**
     * 查询指定id相邻的文章
     * @param mixed $id
     * @return array
     */
    public function articleAround($id)
    {
        $model = Article::where('id', $id)->where('status', 1)->findOrEmpty();
        if ($model->isEmpty() || $this->isAdminManualCategory((int) $model->category_id)) {
            return [];
        }
        $query = Article::where('status', 1)->where('category_id', $model->category_id);
        $query = $this->excludeAdminManualArticles($query);

        // 查询上一篇文章（id小于当前id，取最大的一条）
        $prev = (clone $query)->where('id', '<', $id)->order('id', 'desc')->find();

        // 查询下一篇文章（id大于当前id，取最小的一条）
        $next = (clone $query)->where('id', '>', $id)->order('id', 'asc')->find();

        return [
            'prev' => $prev ? $prev->toArray() : null,
            'next' => $next ? $next->toArray() : null,
        ];
    }

    private function excludeAdminManualCategories($query)
    {
        $ids = ArticleCategory::adminManualCategoryIds();
        if ($ids !== []) {
            $query->whereNotIn('id', $ids);
        }
        return $query;
    }

    private function excludeAdminManualArticles($query)
    {
        $ids = ArticleCategory::adminManualCategoryIds();
        if ($ids !== []) {
            $query->whereNotIn('category_id', $ids);
        }
        $query->whereRaw(
            '(IFNULL(`link_url`, \'\') = \'\' OR `link_url` <> ?)',
            [ArticleCategory::ADMIN_MANUAL_MARKER]
        );
        return $query;
    }

    private function isAdminManualCategory(int $categoryId): bool
    {
        if ($categoryId <= 0) {
            return false;
        }
        return in_array($categoryId, ArticleCategory::adminManualCategoryIds(), true);
    }

}
