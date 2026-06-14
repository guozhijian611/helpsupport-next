<?php

declare(strict_types=1);

namespace plugin\help\app\api\controller;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\service\HelpApiService;
use plugin\saiuser\basic\BaseController;
use support\Request;
use support\Response;

#[Apidoc\Group('社区')]
#[Apidoc\Title('HelpSupport社区')]
class CommunityController extends BaseController
{
    public function __construct(private readonly HelpApiService $service = new HelpApiService())
    {
        parent::__construct();
    }

    #[Apidoc\Title('社区标签')]
    #[Apidoc\Url('/app/help/community/tags')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Returned('list', type: 'array', desc: '社区标签列表')]
    public function tags(Request $request): Response
    {
        return ok($this->service->communityTags($this->memberId));
    }

    #[Apidoc\Title('社区帖子列表')]
    #[Apidoc\Url('/app/help/community/posts')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('keyword', type: 'string', require: false, desc: '关键词')]
    #[Apidoc\Query('mine', type: 'int', require: false, default: 2, desc: '是否只看自己 1是 2否')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '帖子列表')]
    #[Apidoc\Returned('total', type: 'int', desc: '总数')]
    public function posts(Request $request): Response
    {
        return ok($this->service->communityPosts($this->memberId, $request->get()));
    }

    #[Apidoc\Title('社区帖子详情')]
    #[Apidoc\Url('/app/help/community/post')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('id', type: 'int', require: true, desc: '帖子ID')]
    #[Apidoc\Returned('id', type: 'int', desc: '帖子ID')]
    #[Apidoc\Returned('content', type: 'string', desc: '帖子内容')]
    public function post(Request $request): Response
    {
        return ok($this->service->communityPostDetail($this->memberId, (int) $request->get('id', 0)));
    }

    #[Apidoc\Title('发布社区帖子')]
    #[Apidoc\Url('/app/help/community/post')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('content', type: 'string', require: true, desc: '帖子内容')]
    #[Apidoc\Param('images', type: 'array', require: false, desc: '图片URL数组')]
    #[Apidoc\Param('tags', type: 'array', require: false, desc: '标签数组')]
    #[Apidoc\Param('is_anonymous', type: 'int', require: false, default: 2, desc: '是否匿名 1是 2否')]
    #[Apidoc\Returned('id', type: 'int', desc: '帖子ID')]
    #[Apidoc\Returned('audit_status', type: 'int', desc: '审核状态')]
    public function savePost(Request $request): Response
    {
        return ok($this->service->saveCommunityPost($this->memberId, $request->post()));
    }

    #[Apidoc\Title('社区评论列表')]
    #[Apidoc\Url('/app/help/community/comments')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('post_id', type: 'int', require: true, desc: '帖子ID')]
    #[Apidoc\Query('parent_id', type: 'int', require: false, default: 0, desc: '父评论ID')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '评论列表')]
    #[Apidoc\Returned('total', type: 'int', desc: '总数')]
    public function comments(Request $request): Response
    {
        return ok($this->service->communityComments($this->memberId, $request->get()));
    }

    #[Apidoc\Title('发布社区评论')]
    #[Apidoc\Url('/app/help/community/comment')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('post_id', type: 'int', require: true, desc: '帖子ID')]
    #[Apidoc\Param('parent_id', type: 'int', require: false, default: 0, desc: '父评论ID')]
    #[Apidoc\Param('content', type: 'string', require: true, desc: '评论内容')]
    #[Apidoc\Param('is_anonymous', type: 'int', require: false, default: 2, desc: '是否匿名 1是 2否')]
    #[Apidoc\Returned('id', type: 'int', desc: '评论ID')]
    public function saveComment(Request $request): Response
    {
        return ok($this->service->saveCommunityComment($this->memberId, $request->post()));
    }

    #[Apidoc\Title('社区点赞切换')]
    #[Apidoc\Url('/app/help/community/like')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('target_type', type: 'int', require: true, desc: '目标类型 1帖子 2评论')]
    #[Apidoc\Param('target_id', type: 'int', require: true, desc: '目标ID')]
    #[Apidoc\Returned('is_liked', type: 'boolean', desc: '当前是否点赞')]
    public function toggleLike(Request $request): Response
    {
        return ok($this->service->toggleCommunityLike($this->memberId, $request->post()));
    }

    #[Apidoc\Title('社区收藏切换')]
    #[Apidoc\Url('/app/help/community/collect')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('post_id', type: 'int', require: true, desc: '帖子ID')]
    #[Apidoc\Returned('is_collected', type: 'boolean', desc: '当前是否收藏')]
    public function toggleCollect(Request $request): Response
    {
        return ok($this->service->toggleCommunityCollect($this->memberId, (int) $request->post('post_id', 0)));
    }

    #[Apidoc\Title('社区标签关注切换')]
    #[Apidoc\Url('/app/help/community/follow-tag')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('tag_id', type: 'int', require: true, desc: '标签ID')]
    #[Apidoc\Returned('tag_id', type: 'int', desc: '标签ID')]
    #[Apidoc\Returned('is_followed', type: 'boolean', desc: '当前是否关注')]
    public function toggleFollowTag(Request $request): Response
    {
        return ok($this->service->toggleCommunityFollowTag($this->memberId, (int) $request->post('tag_id', 0)));
    }

    #[Apidoc\Title('社区用户关注切换')]
    #[Apidoc\Url('/app/help/community/follow-member')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('target_member_id', type: 'int', require: true, desc: '被关注会员ID')]
    #[Apidoc\Returned('target_member_id', type: 'int', desc: '被关注会员ID')]
    #[Apidoc\Returned('is_followed', type: 'boolean', desc: '当前是否关注')]
    public function toggleFollowMember(Request $request): Response
    {
        return ok($this->service->toggleCommunityFollowMember($this->memberId, (int) $request->post('target_member_id', 0)));
    }

    #[Apidoc\Title('社区举报')]
    #[Apidoc\Url('/app/help/community/report')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('target_type', type: 'int', require: true, desc: '举报类型 1帖子 2评论 3用户')]
    #[Apidoc\Param('target_id', type: 'int', require: true, desc: '举报目标ID')]
    #[Apidoc\Param('reason', type: 'string', require: true, desc: '举报原因')]
    #[Apidoc\Param('description', type: 'string', require: false, desc: '举报描述')]
    #[Apidoc\Returned('id', type: 'int', desc: '举报ID')]
    public function report(Request $request): Response
    {
        return ok($this->service->reportCommunityTarget($this->memberId, $request->post()));
    }
}
