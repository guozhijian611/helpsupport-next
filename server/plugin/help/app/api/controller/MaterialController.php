<?php

declare(strict_types=1);

namespace plugin\help\app\api\controller;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\service\HelpApiService;
use plugin\saiuser\basic\BaseController;
use support\Request;
use support\Response;

#[Apidoc\Group('素材')]
#[Apidoc\Title('HelpSupport素材')]
class MaterialController extends BaseController
{
    public function __construct(private readonly HelpApiService $service = new HelpApiService())
    {
        parent::__construct();
    }

    #[Apidoc\Title('素材分类')]
    #[Apidoc\Url('/app/help/material/categories')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('type', type: 'string', require: false, desc: '分类类型 education/entertainment/private')]
    #[Apidoc\Returned('list', type: 'array', desc: '素材分类')]
    public function categories(Request $request): Response
    {
        return ok($this->service->materialCategories($request->get()));
    }

    #[Apidoc\Title('素材列表')]
    #[Apidoc\Url('/app/help/material/list')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('material_type', type: 'string', require: false, desc: '内容大类')]
    #[Apidoc\Query('category_id', type: 'int', require: false, desc: '分类ID')]
    #[Apidoc\Query('keyword', type: 'string', require: false, desc: '关键词')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 15, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '素材列表')]
    #[Apidoc\Returned('total', type: 'int', desc: '总数')]
    #[Apidoc\Returned('page', type: 'int', desc: '当前页码')]
    #[Apidoc\Returned('page_size', type: 'int', desc: '每页数量')]
    public function list(Request $request): Response
    {
        return ok($this->service->materials($this->memberId, $request->get()));
    }

    #[Apidoc\Title('素材详情')]
    #[Apidoc\Url('/app/help/material/detail')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('id', type: 'int', require: true, desc: '素材ID')]
    #[Apidoc\Returned('material', type: 'object', desc: '素材详情')]
    public function detail(Request $request): Response
    {
        return ok($this->service->materialDetail($this->memberId, (int) $request->get('id')));
    }

    #[Apidoc\Title('浏览历史')]
    #[Apidoc\Url('/app/help/material/history')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '浏览历史')]
    #[Apidoc\Returned('total', type: 'int', desc: '总数')]
    #[Apidoc\Returned('page', type: 'int', desc: '当前页码')]
    #[Apidoc\Returned('page_size', type: 'int', desc: '每页数量')]
    public function history(Request $request): Response
    {
        return ok($this->service->materialHistory($this->memberId, $request->get()));
    }

    #[Apidoc\Title('保存浏览历史')]
    #[Apidoc\Url('/app/help/material/history/save')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('content_id', type: 'int', require: true, desc: '内容ID')]
    #[Apidoc\Param('content_type', type: 'string', require: true, desc: '内容类型')]
    #[Apidoc\Param('title', type: 'string', require: true, desc: '内容标题')]
    #[Apidoc\Param('route', type: 'string', require: true, desc: '页面路由')]
    #[Apidoc\Returned('id', type: 'int', desc: '浏览历史ID')]
    #[Apidoc\Returned('viewed_at', type: 'datetime', desc: '最近浏览时间')]
    public function saveHistory(Request $request): Response
    {
        return ok($this->service->saveMaterialHistory($this->memberId, $request->post()));
    }

    #[Apidoc\Title('素材收藏列表')]
    #[Apidoc\Url('/app/help/material/collections')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '素材收藏列表')]
    #[Apidoc\Returned('total', type: 'int', desc: '总数')]
    #[Apidoc\Returned('page', type: 'int', desc: '当前页码')]
    #[Apidoc\Returned('page_size', type: 'int', desc: '每页数量')]
    public function collections(Request $request): Response
    {
        return ok($this->service->materialCollections($this->memberId, $request->get()));
    }

    #[Apidoc\Title('素材评论列表')]
    #[Apidoc\Url('/app/help/material/comments')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('material_id', type: 'int', require: true, desc: '素材ID')]
    #[Apidoc\Query('parent_id', type: 'int', require: false, default: 0, desc: '父评论ID')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '评论列表')]
    #[Apidoc\Returned('total', type: 'int', desc: '总数')]
    public function comments(Request $request): Response
    {
        return ok($this->service->materialComments($this->memberId, $request->get()));
    }

    #[Apidoc\Title('发布素材评论')]
    #[Apidoc\Url('/app/help/material/comment')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('material_id', type: 'int', require: true, desc: '素材ID')]
    #[Apidoc\Param('parent_id', type: 'int', require: false, default: 0, desc: '父评论ID')]
    #[Apidoc\Param('content', type: 'string', require: true, desc: '评论内容')]
    #[Apidoc\Param('attachments', type: 'array', require: false, desc: '附件列表')]
    #[Apidoc\Returned('id', type: 'int', desc: '评论ID')]
    public function saveComment(Request $request): Response
    {
        return ok($this->service->saveMaterialComment($this->memberId, $request->post()));
    }

    #[Apidoc\Title('素材评论点赞切换')]
    #[Apidoc\Url('/app/help/material/comment/like')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('comment_id', type: 'int', require: true, desc: '评论ID')]
    #[Apidoc\Returned('comment_id', type: 'int', desc: '评论ID')]
    #[Apidoc\Returned('is_liked', type: 'boolean', desc: '是否已点赞')]
    public function toggleCommentLike(Request $request): Response
    {
        return ok($this->service->toggleMaterialCommentLike($this->memberId, (int) $request->post('comment_id')));
    }

    #[Apidoc\Title('切换素材点赞')]
    #[Apidoc\Url('/app/help/material/like')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('material_id', type: 'int', require: true, desc: '素材ID')]
    #[Apidoc\Returned('material_id', type: 'int', desc: '素材ID')]
    #[Apidoc\Returned('is_liked', type: 'boolean', desc: '是否已点赞')]
    public function toggleLike(Request $request): Response
    {
        return ok($this->service->toggleMaterialLike($this->memberId, (int) $request->post('material_id')));
    }

    #[Apidoc\Title('切换素材收藏')]
    #[Apidoc\Url('/app/help/material/collect')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('material_id', type: 'int', require: true, desc: '素材ID')]
    #[Apidoc\Returned('material_id', type: 'int', desc: '素材ID')]
    #[Apidoc\Returned('is_collected', type: 'boolean', desc: '是否已收藏')]
    public function toggleCollect(Request $request): Response
    {
        return ok($this->service->toggleMaterialCollect($this->memberId, (int) $request->post('material_id')));
    }
}
