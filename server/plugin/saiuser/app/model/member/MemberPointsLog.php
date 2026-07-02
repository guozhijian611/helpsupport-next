<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\saiuser\app\model\member;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 积分日志模型
 */
class MemberPointsLog extends BaseModel
{
    /**
     * 数据表主键
     * @var string
     */
    protected $pk = 'id';

    /**
     * 数据库表名称
     * @var string
     */
    protected $table = 'sa_member_point_log';

    /**
     * 会员ID搜索
     */
    public function searchMemberIdAttr($query, $value)
    {
        $query->where('member_id', (int) $value);
    }

    /**
     * 用户名搜索
     */
    public function searchUsernameAttr($query, $value)
    {
        $query->hasWhere('member', function ($query) use ($value) {
            $query->where('username', 'like', '%' . $value . '%');
        });
    }

    /**
     * 积分类型搜索，兼容会员后台原 operate_type 查询参数
     */
    public function searchOperateTypeAttr($query, $value)
    {
        if ((string) $value === '1') {
            $query->whereIn('change_type', ['income', 'adjust']);
            return;
        }
        if ((string) $value === '2') {
            $query->where('change_type', 'expense');
            return;
        }
        $query->where('change_type', (string) $value);
    }

    /**
     * 积分变动类型搜索
     */
    public function searchChangeTypeAttr($query, $value)
    {
        $query->where('change_type', (string) $value);
    }

    /**
     * 来源类型搜索
     */
    public function searchSourceTypeAttr($query, $value)
    {
        $query->where('source_type', (string) $value);
    }

    /**
     * 旧积分表订单号字段已不再作为当前积分流水条件
     */
    public function searchOrderNoAttr($query, $value)
    {
        $query->where('source_id|title|remark', 'like', '%' . (string) $value . '%');
    }

    /**
     * 时间范围搜索
     */
    public function searchCreateTimeAttr($query, $value)
    {
        $query->whereTime('create_time', 'between', $value);
    }

    /**
     * 会员账号
     */
    public function member()
    {
        return $this->belongsTo(Member::class, 'member_id', 'id')->bind(['username']);
    }

}
