<?php

namespace plugin\help\app\admin\controller\community;

use plugin\help\app\admin\logic\community\SaCommunityCommentLogic;
use plugin\help\app\admin\validate\community\SaCommunityCommentValidate;
use plugin\help\app\service\HelpAuditLogService;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\service\Permission;
use support\Request;
use support\Response;
use think\facade\Db;

/**
 * 社区评论管理控制器
 */
class SaCommunityCommentController extends BaseController
{
    public function __construct()
    {
        $this->logic = new SaCommunityCommentLogic();
        $this->validate = new SaCommunityCommentValidate();
        parent::__construct();
    }

    #[Permission('社区评论列表', 'help:community:comment:index')]
    public function index(Request $request): Response
    {
        $where = $request->more([
            ['post_id', ''],
            ['member_id', ''],
            ['content', ''],
            ['audit_status', ''],
            ['status', ''],
        ]);
        $query = $this->logic->search($where);
        $data = $this->withRelatedNames($this->logic->getList($query));

        return $this->success($data);
    }

    #[Permission('社区评论读取', 'help:community:comment:read')]
    public function read(Request $request): Response
    {
        $model = $this->logic->read($request->input('id', ''));
        $data = is_array($model) ? $model : $model->toArray();
        $data = $this->appendRelatedNames([$data])[0] ?? $data;
        $data['audit_logs'] = (new HelpAuditLogService())->list('community_comment', (int) ($data['id'] ?? 0));

        return $this->success($data);
    }

    #[Permission('社区评论添加', 'help:community:comment:save')]
    public function save(Request $request): Response
    {
        $data = $request->post();
        $this->validate('save', $data);
        $result = $this->logic->add($data);

        return $result ? $this->success('添加成功') : $this->fail('添加失败');
    }

    #[Permission('社区评论修改', 'help:community:comment:update')]
    public function update(Request $request): Response
    {
        $data = $request->post();
        $this->validate('update', $data);
        $result = $this->logic->edit($data['id'], $data);

        return $result ? $this->success('修改成功') : $this->fail('修改失败');
    }

    #[Permission('社区评论删除', 'help:community:comment:destroy')]
    public function destroy(Request $request): Response
    {
        $ids = $request->post('ids', '');
        if (empty($ids)) {
            return $this->fail('请选择要删除的数据');
        }
        $result = $this->logic->destroy($ids);

        return $result ? $this->success('删除成功') : $this->fail('删除失败');
    }

    #[Permission('社区评论审核', 'help:community:comment:audit')]
    public function audit(Request $request): Response
    {
        $id = (int) $request->post('id', 0);
        $auditStatus = (int) $request->post('audit_status', 0);
        if ($id <= 0) {
            return $this->fail('请选择要审核的评论');
        }
        $result = $this->logic->audit(
            $id,
            $auditStatus,
            trim((string) $request->post('audit_remark', '')),
            isset($this->adminId) ? $this->adminId : 0
        );

        return $result ? $this->success('审核成功') : $this->fail('审核失败');
    }

    private function withRelatedNames(array $page): array
    {
        foreach (['data', 'list'] as $rowsKey) {
            if (isset($page[$rowsKey]) && is_array($page[$rowsKey])) {
                $page[$rowsKey] = $this->appendRelatedNames($page[$rowsKey]);
                break;
            }
        }

        return $page;
    }

    /**
     * @param array<int, array<string, mixed>> $rows
     * @return array<int, array<string, mixed>>
     */
    private function appendRelatedNames(array $rows): array
    {
        $memberIds = array_values(array_unique(array_filter(
            array_map(fn (array $row): int => (int) ($row['member_id'] ?? 0), $rows),
            fn (int $id): bool => $id > 0
        )));
        $postIds = array_values(array_unique(array_filter(
            array_map(fn (array $row): int => (int) ($row['post_id'] ?? 0), $rows),
            fn (int $id): bool => $id > 0
        )));

        $memberMap = [];
        if ($memberIds !== []) {
            $members = Db::table('sa_member')
                ->whereIn('id', $memberIds)
                ->whereNull('delete_time')
                ->field('id, nickname, username')
                ->select()
                ->toArray();
            foreach ($members as $member) {
                $name = trim((string) ($member['nickname'] ?? ''));
                if ($name === '') {
                    $name = trim((string) ($member['username'] ?? ''));
                }
                $memberMap[(int) $member['id']] = $name;
            }
        }

        $postMap = [];
        if ($postIds !== []) {
            $posts = Db::table('sa_community_post')
                ->whereIn('id', $postIds)
                ->whereNull('delete_time')
                ->field('id, content')
                ->select()
                ->toArray();
            foreach ($posts as $post) {
                $postMap[(int) $post['id']] = $this->excerpt((string) ($post['content'] ?? ''));
            }
        }

        foreach ($rows as &$row) {
            $memberId = (int) ($row['member_id'] ?? 0);
            $postId = (int) ($row['post_id'] ?? 0);
            $row['member_name'] = $memberMap[$memberId] ?? ('会员#' . $memberId);
            $row['post_title'] = $postMap[$postId] ?? '帖子已删除';
        }
        unset($row);

        return $rows;
    }

    private function excerpt(string $content): string
    {
        $text = trim(preg_replace('/\s+/', ' ', strip_tags($content)) ?: '');
        if ($text === '') {
            return '无内容';
        }

        return mb_strlen($text) > 60 ? mb_substr($text, 0, 60) . '...' : $text;
    }
}
