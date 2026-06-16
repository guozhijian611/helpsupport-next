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
    #[Apidoc\Query('locale', type: 'string', require: false, default: 'en-US', desc: '客户端语言')]
    #[Apidoc\Returned('list', type: 'array', desc: '素材分类')]
    public function categories(Request $request): Response
    {
        return ok($this->service->materialCategories($this->memberId, $request->get()));
    }

    #[Apidoc\Title('素材列表')]
    #[Apidoc\Url('/app/help/material/list')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('material_type', type: 'string', require: false, desc: '内容大类')]
    #[Apidoc\Query('category_id', type: 'int', require: false, desc: '分类ID')]
    #[Apidoc\Query('keyword', type: 'string', require: false, desc: '关键词')]
    #[Apidoc\Query('locale', type: 'string', require: false, default: 'en-US', desc: '客户端语言')]
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
    #[Apidoc\Query('locale', type: 'string', require: false, default: 'en-US', desc: '客户端语言')]
    #[Apidoc\Returned('material', type: 'object', desc: '素材详情')]
    public function detail(Request $request): Response
    {
        return ok($this->service->materialDetail(
            $this->memberId,
            (int) $request->get('id'),
            (string) $request->get('locale', '')
        ));
    }

    #[Apidoc\Title('上传私人素材文件')]
    #[Apidoc\Url('/app/help/material/private/upload')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('file', type: 'file', require: true, desc: '素材文件，支持 txt/epub/pdf/mp4/mov/mp3')]
    #[Apidoc\Returned('url', type: 'string', desc: '素材文件地址')]
    #[Apidoc\Returned('origin_name', type: 'string', desc: '原始文件名')]
    #[Apidoc\Returned('mime_type', type: 'string', desc: 'MIME 类型')]
    #[Apidoc\Returned('suffix', type: 'string', desc: '文件后缀')]
    #[Apidoc\Returned('size_byte', type: 'int', desc: '文件大小')]
    public function uploadPrivate(Request $request): Response
    {
        return ok($this->service->uploadPrivateMaterialFile($request));
    }

    #[Apidoc\Title('保存私人素材分类')]
    #[Apidoc\Url('/app/help/material/private/category')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'int', require: false, desc: '分类ID，空为新增')]
    #[Apidoc\Param('name', type: 'string', require: true, desc: '分类名称')]
    #[Apidoc\Param('name_i18n', type: 'object', require: false, desc: '多语言分类名称，例如 {"zh":"书籍","en":"Books"}')]
    #[Apidoc\Param('icon', type: 'string', require: false, desc: '图标标识')]
    #[Apidoc\Param('sort', type: 'int', require: false, default: 100, desc: '排序')]
    #[Apidoc\Param('status', type: 'int', require: false, default: 1, desc: '状态 1启用 2禁用')]
    #[Apidoc\Returned('category', type: 'object', desc: '私人分类')]
    public function savePrivateCategory(Request $request): Response
    {
        return ok($this->service->savePrivateMaterialCategory($this->memberId, $request->post()));
    }

    #[Apidoc\Title('删除私人素材分类')]
    #[Apidoc\Url('/app/help/material/private/category/delete')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'int', require: true, desc: '分类ID')]
    #[Apidoc\Returned('id', type: 'int', desc: '已删除分类ID')]
    public function deletePrivateCategory(Request $request): Response
    {
        return ok($this->service->deletePrivateMaterialCategory($this->memberId, (int) $request->post('id')));
    }

    #[Apidoc\Title('保存私人素材')]
    #[Apidoc\Url('/app/help/material/private')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'int', require: false, desc: '素材ID，空为新增')]
    #[Apidoc\Param('category_id', type: 'int', require: false, desc: '私人素材分类ID')]
    #[Apidoc\Param('media_type', type: 'string', require: false, default: 'article', desc: '素材类型 article/video/audio/pdf/epub/link/txt/mp4/mov/mp3')]
    #[Apidoc\Param('title', type: 'string', require: true, desc: '素材标题')]
    #[Apidoc\Param('title_i18n', type: 'object', require: false, desc: '多语言标题，例如 {"zh":"标题","en":"Title"}')]
    #[Apidoc\Param('summary', type: 'string', require: false, desc: '摘要')]
    #[Apidoc\Param('summary_i18n', type: 'object', require: false, desc: '多语言摘要，例如 {"zh":"摘要","en":"Summary"}')]
    #[Apidoc\Param('artist', type: 'string', require: false, desc: '音乐歌手')]
    #[Apidoc\Param('album', type: 'string', require: false, desc: '音乐专辑')]
    #[Apidoc\Param('cover_url', type: 'string', require: false, desc: '封面图')]
    #[Apidoc\Param('content_url', type: 'string', require: false, desc: '内容地址')]
    #[Apidoc\Param('content_text', type: 'string', require: false, desc: '富文本内容或歌词')]
    #[Apidoc\Param('content_text_i18n', type: 'object', require: false, desc: '多语言富文本内容或歌词，例如 {"zh":"<p>正文</p>","en":"<p>Body</p>"}')]
    #[Apidoc\Param('tags', type: 'array', require: false, desc: '标签')]
    #[Apidoc\Param('duration_seconds', type: 'int', require: false, desc: '时长秒')]
    #[Apidoc\Returned('id', type: 'int', desc: '素材ID')]
    #[Apidoc\Returned('audit_status', type: 'int', desc: '审核状态 1待审 2通过 3拒绝')]
    public function savePrivate(Request $request): Response
    {
        return ok($this->service->savePrivateMaterial($this->memberId, $request->post()));
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
    #[Apidoc\Param('progress', type: 'float', require: false, default: 0, desc: '浏览或播放进度百分比')]
    #[Apidoc\Param('duration_seconds', type: 'int', require: false, default: 0, desc: '停留或播放秒数')]
    #[Apidoc\Returned('id', type: 'int', desc: '浏览历史ID')]
    #[Apidoc\Returned('viewed_at', type: 'datetime', desc: '最近浏览时间')]
    public function saveHistory(Request $request): Response
    {
        return ok($this->service->saveMaterialHistory($this->memberId, $request->post()));
    }

    #[Apidoc\Title('素材收藏列表')]
    #[Apidoc\Url('/app/help/material/collections')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('locale', type: 'string', require: false, default: 'en-US', desc: '客户端语言')]
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
