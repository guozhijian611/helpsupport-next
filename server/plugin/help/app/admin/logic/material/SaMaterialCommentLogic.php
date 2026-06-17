<?php

namespace plugin\help\app\admin\logic\material;

use plugin\help\app\model\material\SaMaterialComment;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

/**
 * 素材评论逻辑层
 */
class SaMaterialCommentLogic extends BaseLogic
{
    private const MANAGED_MATERIAL_TYPES = ['education', 'entertainment'];

    public function __construct()
    {
        $this->model = new SaMaterialComment();
        $this->orderField = 'id';
        $this->orderType = 'DESC';
    }

    public function getAdminList(array $where): array
    {
        $request = request();
        $saiType = $request ? $request->input('saiType', 'list') : 'list';
        $page = max(1, (int) ($request ? $request->input('page', 1) : 1));
        $limit = max(1, (int) ($request ? $request->input('limit', 10) : 10));
        $orderField = (string) ($request ? $request->input('orderField', 'id') : 'id');
        $orderType = strtolower((string) ($request ? $request->input('orderType', 'desc') : 'desc')) === 'asc' ? 'asc' : 'desc';

        $query = $this->baseQuery();
        $this->applySearch($query, $where);

        $allowedOrderFields = [
            'id' => 'c.id',
            'material_id' => 'c.material_id',
            'member_id' => 'c.member_id',
            'like_count' => 'c.like_count',
            'status' => 'c.status',
            'create_time' => 'c.create_time',
        ];
        $query->order($allowedOrderFields[$orderField] ?? 'c.id', $orderType);

        if ($saiType === 'all') {
            return $this->formatRows($query->select()->toArray());
        }

        $data = $query->paginate($limit, false, ['page' => $page])->toArray();
        foreach (['data', 'list'] as $key) {
            if (isset($data[$key]) && is_array($data[$key])) {
                $data[$key] = $this->formatRows($data[$key]);
            }
        }

        return $data;
    }

    public function readDetail(int $id): array
    {
        if ($id <= 0) {
            return [];
        }

        $row = $this->baseQuery()
            ->where('c.id', $id)
            ->find();

        return $row ? ($this->formatRows([$row])[0] ?? []) : [];
    }

    public function setStatus(int $id, int $status, string $remark, int $adminId): bool
    {
        if ($id <= 0) {
            throw new ApiException('请选择要处理的评论');
        }
        if (!in_array($status, [1, 2], true)) {
            throw new ApiException('状态参数错误');
        }
        if ($status === 2 && $remark === '') {
            throw new ApiException('隐藏原因必须填写');
        }

        $comment = $this->managedComment($id);
        $oldStatus = (int) ($comment['status'] ?? 0);
        if ($oldStatus === $status) {
            return true;
        }

        return Db::transaction(function () use ($id, $status, $remark, $adminId, $comment, $oldStatus) {
            Db::table('sa_material_comment')
                ->where('id', $id)
                ->whereNull('delete_time')
                ->update([
                    'status' => $status,
                    'remark' => $remark,
                    'updated_by' => $adminId > 0 ? $adminId : null,
                    'update_time' => date('Y-m-d H:i:s'),
                ]);

            if ($oldStatus === 1 && $status === 2) {
                $this->syncMaterialCommentCount((int) $comment['material_id'], -1);
            } elseif ($oldStatus === 2 && $status === 1) {
                $this->syncMaterialCommentCount((int) $comment['material_id'], 1);
            }

            return true;
        });
    }

    public function deleteComments(mixed $ids, int $adminId): bool
    {
        $ids = $this->parseIds($ids);
        if ($ids === []) {
            throw new ApiException('请选择要删除的数据');
        }

        $comments = Db::table('sa_material_comment')
            ->alias('c')
            ->leftJoin('sa_content_material m', 'm.id = c.material_id AND m.delete_time IS NULL')
            ->whereIn('c.id', $ids)
            ->whereIn('m.material_type', self::MANAGED_MATERIAL_TYPES)
            ->whereNull('c.delete_time')
            ->field('c.id, c.material_id, c.status')
            ->select()
            ->toArray();

        if (count($comments) !== count($ids)) {
            throw new ApiException('只能删除教育和娱乐素材评论');
        }

        return Db::transaction(function () use ($ids, $comments, $adminId) {
            Db::table('sa_material_comment')
                ->whereIn('id', $ids)
                ->whereNull('delete_time')
                ->update([
                    'updated_by' => $adminId > 0 ? $adminId : null,
                    'update_time' => date('Y-m-d H:i:s'),
                    'delete_time' => date('Y-m-d H:i:s'),
                ]);

            $visibleCounts = [];
            foreach ($comments as $comment) {
                if ((int) ($comment['status'] ?? 0) !== 1) {
                    continue;
                }
                $materialId = (int) ($comment['material_id'] ?? 0);
                $visibleCounts[$materialId] = ($visibleCounts[$materialId] ?? 0) + 1;
            }
            foreach ($visibleCounts as $materialId => $count) {
                $this->syncMaterialCommentCount((int) $materialId, -$count);
            }

            return true;
        });
    }

    private function baseQuery(): mixed
    {
        return Db::table('sa_material_comment')
            ->alias('c')
            ->leftJoin('sa_content_material mat', 'mat.id = c.material_id AND mat.delete_time IS NULL')
            ->leftJoin('sa_member mem', 'mem.id = c.member_id AND mem.delete_time IS NULL')
            ->whereIn('mat.material_type', self::MANAGED_MATERIAL_TYPES)
            ->whereNull('c.delete_time')
            ->field(
                'c.*, mat.title AS material_title, mat.material_type, mat.media_type, mem.nickname AS member_name, mem.username AS member_username'
            );
    }

    private function applySearch(mixed $query, array $where): void
    {
        if (($where['material_id'] ?? '') !== '') {
            $query->where('c.material_id', (int) $where['material_id']);
        }
        if (($where['member_id'] ?? '') !== '') {
            $query->where('c.member_id', (int) $where['member_id']);
        }
        if (($where['content'] ?? '') !== '') {
            $query->where('c.content', 'like', '%' . trim((string) $where['content']) . '%');
        }
        if (($where['status'] ?? '') !== '') {
            $query->where('c.status', (int) $where['status']);
        }
        if (($where['material_type'] ?? '') !== '') {
            $type = (string) $where['material_type'];
            if (!in_array($type, self::MANAGED_MATERIAL_TYPES, true)) {
                throw new ApiException('素材类型参数错误');
            }
            $query->where('mat.material_type', $type);
        }
        if (($where['material_title'] ?? '') !== '') {
            $query->where('mat.title', 'like', '%' . trim((string) $where['material_title']) . '%');
        }
    }

    private function managedComment(int $id): array
    {
        $comment = Db::table('sa_material_comment')
            ->alias('c')
            ->leftJoin('sa_content_material m', 'm.id = c.material_id AND m.delete_time IS NULL')
            ->where('c.id', $id)
            ->whereIn('m.material_type', self::MANAGED_MATERIAL_TYPES)
            ->whereNull('c.delete_time')
            ->field('c.*')
            ->find();

        if (!$comment) {
            throw new ApiException('素材评论不存在或不支持处理');
        }

        return $comment;
    }

    /**
     * @param array<int, array<string, mixed>> $rows
     * @return array<int, array<string, mixed>>
     */
    private function formatRows(array $rows): array
    {
        foreach ($rows as &$row) {
            $memberName = trim((string) ($row['member_name'] ?? ''));
            if ($memberName === '') {
                $memberName = trim((string) ($row['member_username'] ?? ''));
            }
            if ($memberName === '') {
                $memberName = '会员#' . (int) ($row['member_id'] ?? 0);
            }
            $row['member_name'] = $memberName;
            $row['material_title'] = trim((string) ($row['material_title'] ?? '')) ?: '素材已删除';
            $row['material_type_label'] = match ((string) ($row['material_type'] ?? '')) {
                'education' => '教育素材',
                'entertainment' => '娱乐素材',
                default => '未知类型',
            };
        }
        unset($row);

        return $rows;
    }

    /**
     * @return array<int, int>
     */
    private function parseIds(mixed $ids): array
    {
        if (is_string($ids)) {
            $ids = explode(',', $ids);
        }
        if (!is_array($ids)) {
            $ids = [$ids];
        }

        return array_values(array_unique(array_filter(array_map('intval', $ids), fn (int $id) => $id > 0)));
    }

    private function syncMaterialCommentCount(int $materialId, int $delta): void
    {
        if ($materialId <= 0 || $delta === 0) {
            return;
        }

        $operator = $delta > 0 ? '+' : '-';
        Db::execute(sprintf(
            'UPDATE `sa_content_material` SET `comment_count` = GREATEST(`comment_count` %s %d, 0), `update_time` = NOW() WHERE `id` = %d',
            $operator,
            abs($delta),
            $materialId
        ));
    }
}
