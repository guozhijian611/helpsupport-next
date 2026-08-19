<?php

namespace plugin\saiuser\app\admin\logic\member;

use plugin\saiadmin\exception\ApiException;
use plugin\saiuser\app\model\member\MemberLoginLog;
use plugin\saiuser\app\model\member\MemberPointsLog;
use support\think\Db;

/**
 * 会员关联业务数据
 */
class MemberRelatedLogic
{
    private const TYPES = [
        'posts',
        'comments',
        'material_comments',
        'materials',
        'post_collects',
        'material_collects',
        'plans',
        'doctor_plans',
        'assessments',
        'journals',
        'login_logs',
        'points_logs',
        'patients',
        'appointments',
    ];

    public function memberProfile(int $memberId): array
    {
        if ($memberId <= 0) {
            return [];
        }

        $row = Db::table('sa_help_member_profile')
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->find();

        return is_array($row) ? $row : [];
    }

    public function doctorProfile(int $memberId): array
    {
        if ($memberId <= 0) {
            return [];
        }

        $row = Db::table('sa_help_doctor_profile')
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->find();
        if (!is_array($row) || $row === []) {
            return [];
        }

        $images = $this->parseImageList($row['certification_images'] ?? null);
        $row['certification_image_urls'] = $images;

        $auditorId = (int) ($row['audit_by'] ?? 0);
        $row['audit_by_display'] = '';
        if ($auditorId > 0) {
            $user = Db::table('sa_system_user')
                ->where('id', $auditorId)
                ->field('id, username, realname')
                ->find();
            $name = trim((string) ($user['realname'] ?? ''));
            if ($name === '') {
                $name = trim((string) ($user['username'] ?? ''));
            }
            $row['audit_by_display'] = $name !== '' ? $name : ('管理员 #' . $auditorId);
        }

        $row['audit_logs'] = [];
        if (class_exists(\plugin\help\app\service\HelpAuditLogService::class) && (int) ($row['id'] ?? 0) > 0) {
            $row['audit_logs'] = (new \plugin\help\app\service\HelpAuditLogService())
                ->list('doctor_profile', (int) $row['id']);
        }

        return $row;
    }

    public function counts(int $memberId): array
    {
        if ($memberId <= 0) {
            return $this->emptyCounts();
        }

        return [
            'posts' => $this->countTable('sa_community_post', ['member_id' => $memberId]),
            'comments' => $this->countTable('sa_community_comment', ['member_id' => $memberId]),
            'material_comments' => $this->countTable('sa_material_comment', ['member_id' => $memberId]),
            'materials' => $this->countTable('sa_content_material', ['member_id' => $memberId]),
            'post_collects' => $this->countTable('sa_community_collect', ['member_id' => $memberId]),
            'material_collects' => $this->countTable('sa_material_collect', ['member_id' => $memberId]),
            'plans' => $this->countTable('sa_treatment_plan', ['member_id' => $memberId]),
            'doctor_plans' => $this->countTable('sa_treatment_plan', ['doctor_id' => $memberId]),
            'assessments' => $this->countTable('sa_member_assessment_result', ['member_id' => $memberId]),
            'journals' => $this->countTable('sa_member_journal', ['member_id' => $memberId]),
            'login_logs' => (int) MemberLoginLog::where('member_id', $memberId)->count(),
            'points_logs' => (int) MemberPointsLog::where('member_id', $memberId)->count(),
            'patients' => $this->countTable('sa_doctor_patient', ['doctor_id' => $memberId]),
            'appointments' => $this->countWhere(function () use ($memberId) {
                return Db::table('sa_doctor_appointment')
                    ->whereNull('delete_time')
                    ->where(function ($query) use ($memberId) {
                        $query->where('member_id', $memberId)->whereOr('doctor_id', $memberId);
                    });
            }),
        ];
    }

    public function page(int $memberId, string $type, int $page, int $limit): array
    {
        if ($memberId <= 0) {
            throw new ApiException('会员ID无效');
        }
        if (!in_array($type, self::TYPES, true)) {
            throw new ApiException('不支持的关联数据类型');
        }

        return match ($type) {
            'posts' => $this->pagePosts($memberId, $page, $limit),
            'comments' => $this->pageComments($memberId, $page, $limit),
            'material_comments' => $this->pageMaterialComments($memberId, $page, $limit),
            'materials' => $this->pageMaterials($memberId, $page, $limit),
            'post_collects' => $this->pagePostCollects($memberId, $page, $limit),
            'material_collects' => $this->pageMaterialCollects($memberId, $page, $limit),
            'plans' => $this->pagePlans($memberId, $page, $limit, false),
            'doctor_plans' => $this->pagePlans($memberId, $page, $limit, true),
            'assessments' => $this->pageAssessments($memberId, $page, $limit),
            'journals' => $this->pageJournals($memberId, $page, $limit),
            'login_logs' => $this->pageLoginLogs($memberId, $page, $limit),
            'points_logs' => $this->pagePointsLogs($memberId, $page, $limit),
            'patients' => $this->pagePatients($memberId, $page, $limit),
            'appointments' => $this->pageAppointments($memberId, $page, $limit),
        };
    }

    private function pagePosts(int $memberId, int $page, int $limit): array
    {
        return $this->paginate(
            Db::table('sa_community_post')
                ->where('member_id', $memberId)
                ->whereNull('delete_time')
                ->field('id, content, is_anonymous, is_doctor_post, view_count, like_count, comment_count, collect_count, audit_status, status, create_time')
                ->order('id', 'desc'),
            $page,
            $limit
        );
    }

    private function pageComments(int $memberId, int $page, int $limit): array
    {
        return $this->paginate(
            Db::table('sa_community_comment')
                ->alias('c')
                ->leftJoin('sa_community_post p', 'p.id = c.post_id AND p.delete_time IS NULL')
                ->where('c.member_id', $memberId)
                ->whereNull('c.delete_time')
                ->field('c.id, c.post_id, c.content, c.like_count, c.audit_status, c.status, c.create_time, p.content as target_content')
                ->order('c.id', 'desc'),
            $page,
            $limit
        );
    }

    private function pageMaterialComments(int $memberId, int $page, int $limit): array
    {
        return $this->paginate(
            Db::table('sa_material_comment')
                ->alias('c')
                ->leftJoin('sa_content_material m', 'm.id = c.material_id AND m.delete_time IS NULL')
                ->where('c.member_id', $memberId)
                ->whereNull('c.delete_time')
                ->field('c.id, c.material_id, c.content, c.like_count, c.audit_status, c.status, c.create_time, m.title as target_title, m.material_type')
                ->order('c.id', 'desc'),
            $page,
            $limit
        );
    }

    private function pageMaterials(int $memberId, int $page, int $limit): array
    {
        return $this->paginate(
            Db::table('sa_content_material')
                ->where('member_id', $memberId)
                ->whereNull('delete_time')
                ->field('id, title, material_type, media_type, is_public, view_count, like_count, collect_count, comment_count, audit_status, status, create_time')
                ->order('id', 'desc'),
            $page,
            $limit
        );
    }

    private function pagePostCollects(int $memberId, int $page, int $limit): array
    {
        return $this->paginate(
            Db::table('sa_community_collect')
                ->alias('c')
                ->leftJoin('sa_community_post p', 'p.id = c.post_id AND p.delete_time IS NULL')
                ->where('c.member_id', $memberId)
                ->whereNull('c.delete_time')
                ->field('c.id, c.post_id, c.create_time, p.content as target_content, p.member_id as author_id')
                ->order('c.id', 'desc'),
            $page,
            $limit
        );
    }

    private function pageMaterialCollects(int $memberId, int $page, int $limit): array
    {
        return $this->paginate(
            Db::table('sa_material_collect')
                ->alias('c')
                ->leftJoin('sa_content_material m', 'm.id = c.material_id AND m.delete_time IS NULL')
                ->where('c.member_id', $memberId)
                ->whereNull('c.delete_time')
                ->field('c.id, c.material_id, c.create_time, m.title as target_title, m.material_type, m.media_type')
                ->order('c.id', 'desc'),
            $page,
            $limit
        );
    }

    private function pagePlans(int $memberId, int $page, int $limit, bool $asDoctor): array
    {
        $query = Db::table('sa_treatment_plan')
            ->alias('p')
            ->leftJoin('sa_member patient', 'patient.id = p.member_id')
            ->leftJoin('sa_member doctor', 'doctor.id = p.doctor_id')
            ->whereNull('p.delete_time')
            ->field('p.id, p.member_id, p.doctor_id, p.title, p.description, p.start_date, p.end_date, p.source_type, p.status, p.create_time, patient.nickname as member_nickname, patient.username as member_username, doctor.nickname as doctor_nickname, doctor.username as doctor_username')
            ->order('p.id', 'desc');

        if ($asDoctor) {
            $query->where('p.doctor_id', $memberId);
        } else {
            $query->where('p.member_id', $memberId);
        }

        return $this->paginate($query, $page, $limit);
    }

    private function pageAssessments(int $memberId, int $page, int $limit): array
    {
        return $this->paginate(
            Db::table('sa_member_assessment_result')
                ->where('member_id', $memberId)
                ->whereNull('delete_time')
                ->field('id, assessment_id, assessment_title, task_title, question_count, total_score, achieved_score, result_level, suggestions, assessed_at, create_time')
                ->order('id', 'desc'),
            $page,
            $limit
        );
    }

    private function pageJournals(int $memberId, int $page, int $limit): array
    {
        return $this->paginate(
            Db::table('sa_member_journal')
                ->where('member_id', $memberId)
                ->whereNull('delete_time')
                ->field('id, entry_date, entry_time, title, content, mood_score, is_private, status, create_time')
                ->order('id', 'desc'),
            $page,
            $limit
        );
    }

    private function pageLoginLogs(int $memberId, int $page, int $limit): array
    {
        $query = MemberLoginLog::with(['platform'])
            ->where('member_id', $memberId)
            ->order('id', 'desc');
        $total = (clone $query)->count();
        $list = $query->page($page, $limit)->select()->toArray();

        return $this->pageResult($list, $total, $page, $limit);
    }

    private function pagePointsLogs(int $memberId, int $page, int $limit): array
    {
        $query = MemberPointsLog::where('member_id', $memberId)->order('id', 'desc');
        $total = (clone $query)->count();
        $list = $query->page($page, $limit)->select()->toArray();

        return $this->pageResult($list, $total, $page, $limit);
    }

    private function pagePatients(int $memberId, int $page, int $limit): array
    {
        return $this->paginate(
            Db::table('sa_doctor_patient')
                ->alias('p')
                ->leftJoin('sa_member m', 'm.id = p.member_id')
                ->where('p.doctor_id', $memberId)
                ->whereNull('p.delete_time')
                ->field('p.id, p.member_id, p.status, p.bind_source, p.bind_time, p.unbind_time, p.remark, p.create_time, m.nickname as member_nickname, m.username as member_username, m.avatar as member_avatar')
                ->order('p.id', 'desc'),
            $page,
            $limit
        );
    }

    private function pageAppointments(int $memberId, int $page, int $limit): array
    {
        return $this->paginate(
            Db::table('sa_doctor_appointment')
                ->alias('a')
                ->leftJoin('sa_member patient', 'patient.id = a.member_id')
                ->leftJoin('sa_member doctor', 'doctor.id = a.doctor_id')
                ->whereNull('a.delete_time')
                ->where(function ($query) use ($memberId) {
                    $query->where('a.member_id', $memberId)->whereOr('a.doctor_id', $memberId);
                })
                ->field('a.id, a.member_id, a.doctor_id, a.appoint_date, a.appoint_time_slot, a.status, a.meet_type, a.remark, a.cancel_reason, a.create_time, patient.nickname as member_nickname, patient.username as member_username, doctor.nickname as doctor_nickname, doctor.username as doctor_username')
                ->order('a.id', 'desc'),
            $page,
            $limit
        );
    }

    private function paginate(mixed $query, int $page, int $limit): array
    {
        $total = (int) (clone $query)->count();
        $list = $query->page($page, $limit)->select()->toArray();

        return $this->pageResult($list, $total, $page, $limit);
    }

    private function pageResult(array $list, int $total, int $page, int $limit): array
    {
        return [
            'data' => $list,
            'total' => $total,
            'current_page' => $page,
            'per_page' => $limit,
        ];
    }

    private function countTable(string $table, array $where): int
    {
        return $this->countWhere(function () use ($table, $where) {
            $query = Db::table($table)->whereNull('delete_time');
            foreach ($where as $field => $value) {
                $query->where($field, $value);
            }
            return $query;
        });
    }

    private function countWhere(callable $builder): int
    {
        try {
            return (int) $builder()->count();
        } catch (\Throwable) {
            return 0;
        }
    }

    private function emptyCounts(): array
    {
        $counts = [];
        foreach (self::TYPES as $type) {
            $counts[$type] = 0;
        }
        return $counts;
    }

    private function parseImageList(mixed $value): array
    {
        if ($value === '' || $value === null) {
            return [];
        }
        if (is_array($value)) {
            return array_values(array_filter(array_map('strval', $value)));
        }

        $text = trim((string) $value);
        if ($text === '') {
            return [];
        }

        $decoded = json_decode($text, true);
        if (json_last_error() === JSON_ERROR_NONE) {
            if (is_array($decoded)) {
                return array_values(array_filter(array_map('strval', $decoded)));
            }
            if (is_string($decoded) && trim($decoded) !== '') {
                return [trim($decoded)];
            }
        }

        return [$text];
    }
}
