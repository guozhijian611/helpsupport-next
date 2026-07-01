<?php

declare(strict_types=1);

namespace plugin\help\app\api\controller;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\service\HelpApiService;
use plugin\saiuser\basic\BaseController;
use support\Request;
use support\Response;

#[Apidoc\Group('预约')]
#[Apidoc\Title('HelpSupport预约')]
class AppointmentController extends BaseController
{
    public function __construct(private readonly HelpApiService $service = new HelpApiService())
    {
        parent::__construct();
    }

    #[Apidoc\Title('可预约医生列表')]
    #[Apidoc\Url('/app/help/appointment/doctors')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('keyword', type: 'string', require: false, desc: '医生姓名/医院/专长关键词')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '医生列表')]
    #[Apidoc\Returned('total', type: 'int', desc: '总数')]
    #[Apidoc\Returned('page', type: 'int', desc: '当前页码')]
    #[Apidoc\Returned('page_size', type: 'int', desc: '每页数量')]
    public function doctors(Request $request): Response
    {
        return ok($this->service->appointmentDoctors($request->get()));
    }

    #[Apidoc\Title('医生可预约时段')]
    #[Apidoc\Url('/app/help/appointment/slots')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('doctor_id', type: 'int', require: true, desc: '医生会员ID')]
    #[Apidoc\Query('date', type: 'string', require: false, desc: '预约日期 YYYY-MM-DD')]
    #[Apidoc\Returned('list', type: 'array', desc: '可预约时段列表')]
    #[Apidoc\Returned('list[].payment_method', type: 'string', desc: '预约支付方式 cash/points')]
    #[Apidoc\Returned('list[].can_use_points', type: 'bool', desc: '是否可使用积分预约')]
    #[Apidoc\Returned('list[].points_cost', type: 'int', desc: '本时段预约消耗积分')]
    public function slots(Request $request): Response
    {
        return ok($this->service->appointmentSlots($request->get()));
    }

    #[Apidoc\Title('我的预约列表')]
    #[Apidoc\Url('/app/help/appointment/list')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('status', type: 'int', require: false, desc: '预约状态')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '预约列表')]
    #[Apidoc\Returned('total', type: 'int', desc: '总数')]
    #[Apidoc\Returned('page', type: 'int', desc: '当前页码')]
    #[Apidoc\Returned('page_size', type: 'int', desc: '每页数量')]
    public function list(Request $request): Response
    {
        return ok($this->service->appointments($this->memberId, $request->get()));
    }

    #[Apidoc\Title('创建预约')]
    #[Apidoc\Url('/app/help/appointment')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('doctor_id', type: 'int', require: false, desc: '医生会员ID；无schedule_id时必填')]
    #[Apidoc\Param('schedule_id', type: 'int', require: false, desc: '排班ID，优先使用')]
    #[Apidoc\Param('appoint_date', type: 'string', require: false, desc: '预约日期 YYYY-MM-DD；无schedule_id时必填')]
    #[Apidoc\Param('appoint_time_slot', type: 'string', require: false, desc: '预约时间段；无schedule_id时必填')]
    #[Apidoc\Param('remark', type: 'string', require: false, desc: '预约备注')]
    #[Apidoc\Returned('id', type: 'int', desc: '预约ID')]
    #[Apidoc\Returned('status', type: 'int', desc: '预约状态')]
    #[Apidoc\Returned('payment_method', type: 'string', desc: '预约支付方式 cash/points')]
    #[Apidoc\Returned('points_cost', type: 'int', desc: '积分预约消耗积分')]
    #[Apidoc\Returned('points_log_id', type: 'int', desc: '积分扣减流水ID')]
    public function create(Request $request): Response
    {
        return ok($this->service->createAppointment($this->memberId, $request->post()));
    }

    #[Apidoc\Title('取消预约')]
    #[Apidoc\Url('/app/help/appointment/cancel')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('appointment_id', type: 'int', require: true, desc: '预约ID')]
    #[Apidoc\Param('cancel_reason', type: 'string', require: false, desc: '取消原因')]
    #[Apidoc\Returned('id', type: 'int', desc: '预约ID')]
    #[Apidoc\Returned('status', type: 'int', desc: '取消后的预约状态')]
    #[Apidoc\Returned('canceled_at', type: 'datetime', desc: '取消时间')]
    public function cancel(Request $request): Response
    {
        return ok($this->service->cancelAppointment($this->memberId, $request->post()));
    }
}
