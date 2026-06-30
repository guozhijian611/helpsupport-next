<?php

declare(strict_types=1);

namespace plugin\help\app\api\controller;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\service\HelpApiService;
use plugin\saiuser\basic\BaseController;
use support\Request;
use support\Response;

#[Apidoc\Group('医生端')]
#[Apidoc\Title('HelpSupport医生端')]
class DoctorController extends BaseController
{
    public function __construct(private readonly HelpApiService $service = new HelpApiService())
    {
        parent::__construct();
    }

    #[Apidoc\Title('我的患者列表')]
    #[Apidoc\Url('/app/help/doctor/patients')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('status', type: 'int', require: false, desc: '绑定状态 1绑定中 2已解绑')]
    #[Apidoc\Query('keyword', type: 'string', require: false, desc: '患者昵称关键词')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '患者列表')]
    public function patients(Request $request): Response
    {
        return ok($this->service->doctorPatients($this->memberId, $request->get()));
    }

    #[Apidoc\Title('可添加患者搜索')]
    #[Apidoc\Url('/app/help/doctor/patient/candidates')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('keyword', type: 'string', require: false, desc: '患者ID、昵称或用户名关键词')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '患者候选列表，包含 is_bound 标识')]
    public function patientCandidates(Request $request): Response
    {
        return ok($this->service->doctorPatientCandidates($this->memberId, $request->get()));
    }

    #[Apidoc\Title('绑定患者')]
    #[Apidoc\Url('/app/help/doctor/patient/bind')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('member_id', type: 'int', require: true, desc: '患者会员ID')]
    #[Apidoc\Param('bind_source', type: 'string', require: false, desc: '绑定来源 manual/system/appointment')]
    #[Apidoc\Returned('id', type: 'int', desc: '绑定关系ID')]
    public function bindPatient(Request $request): Response
    {
        return ok($this->service->bindDoctorPatient($this->memberId, $request->post()));
    }

    #[Apidoc\Title('解绑患者')]
    #[Apidoc\Url('/app/help/doctor/patient/unbind')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('member_id', type: 'int', require: true, desc: '患者会员ID')]
    #[Apidoc\Returned('id', type: 'int', desc: '绑定关系ID')]
    #[Apidoc\Returned('status', type: 'int', desc: '解绑后的状态')]
    public function unbindPatient(Request $request): Response
    {
        return ok($this->service->unbindDoctorPatient($this->memberId, $request->post()));
    }

    #[Apidoc\Title('患者治疗计划')]
    #[Apidoc\Url('/app/help/doctor/patient/plans')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('member_id', type: 'int', require: true, desc: '患者会员ID')]
    #[Apidoc\Query('status', type: 'int', require: false, desc: '计划状态')]
    #[Apidoc\Returned('list', type: 'array', desc: '治疗计划及阶段')]
    public function patientPlans(Request $request): Response
    {
        return ok($this->service->doctorPatientPlans($this->memberId, $request->get()));
    }

    #[Apidoc\Title('保存患者治疗计划')]
    #[Apidoc\Url('/app/help/doctor/treatment-plan')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('member_id', type: 'int', require: true, desc: '患者会员ID')]
    #[Apidoc\Param('id', type: 'int', require: false, desc: '计划ID，空为新增')]
    #[Apidoc\Param('title', type: 'string', require: true, desc: '计划标题')]
    #[Apidoc\Param('description', type: 'string', require: false, desc: '计划说明')]
    #[Apidoc\Param('start_date', type: 'string', require: false, desc: '开始日期')]
    #[Apidoc\Param('end_date', type: 'string', require: false, desc: '结束日期')]
    #[Apidoc\Param('status', type: 'int', require: false, desc: '状态 1进行中 2已完成 3已终止')]
    #[Apidoc\Returned('id', type: 'int', desc: '计划ID')]
    public function saveTreatmentPlan(Request $request): Response
    {
        return ok($this->service->saveDoctorTreatmentPlan($this->memberId, $request->post()));
    }

    #[Apidoc\Title('保存治疗阶段')]
    #[Apidoc\Url('/app/help/doctor/treatment-stage')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('member_id', type: 'int', require: true, desc: '患者会员ID')]
    #[Apidoc\Param('plan_id', type: 'int', require: true, desc: '治疗计划ID')]
    #[Apidoc\Param('id', type: 'int', require: false, desc: '阶段ID，空为新增')]
    #[Apidoc\Param('stage_name', type: 'string', require: true, desc: '阶段名称')]
    #[Apidoc\Param('start_date', type: 'string', require: true, desc: '开始日期')]
    #[Apidoc\Param('end_date', type: 'string', require: true, desc: '结束日期')]
    #[Apidoc\Param('stage_target', type: 'string', require: false, desc: '阶段目标')]
    #[Apidoc\Param('sort', type: 'int', require: false, desc: '排序')]
    #[Apidoc\Param('status', type: 'int', require: false, desc: '状态 0待开始 1进行中 2完成')]
    #[Apidoc\Returned('id', type: 'int', desc: '阶段ID')]
    public function saveTreatmentStage(Request $request): Response
    {
        return ok($this->service->saveDoctorTreatmentStage($this->memberId, $request->post()));
    }

    #[Apidoc\Title('患者每日任务')]
    #[Apidoc\Url('/app/help/doctor/daily-tasks')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('member_id', type: 'int', require: true, desc: '患者会员ID')]
    #[Apidoc\Query('plan_id', type: 'int', require: false, desc: '计划ID')]
    #[Apidoc\Query('date', type: 'string', require: false, desc: '任务日期')]
    #[Apidoc\Query('status', type: 'int', require: false, desc: '任务状态')]
    #[Apidoc\Returned('list', type: 'array', desc: '任务列表')]
    public function dailyTasks(Request $request): Response
    {
        return ok($this->service->doctorDailyTasks($this->memberId, $request->get()));
    }

    #[Apidoc\Title('保存患者每日任务')]
    #[Apidoc\Url('/app/help/doctor/daily-task')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('member_id', type: 'int', require: true, desc: '患者会员ID')]
    #[Apidoc\Param('id', type: 'int', require: false, desc: '任务ID，空为新增')]
    #[Apidoc\Param('task_date', type: 'string', require: true, desc: '任务日期')]
    #[Apidoc\Param('title', type: 'string', require: true, desc: '任务标题')]
    #[Apidoc\Param('task_type', type: 'string', require: false, desc: '任务类型')]
    #[Apidoc\Param('reminders', type: 'array', require: false, desc: '提醒规则')]
    #[Apidoc\Returned('id', type: 'int', desc: '任务ID')]
    public function saveDailyTask(Request $request): Response
    {
        return ok($this->service->saveDoctorDailyTask($this->memberId, $request->post()));
    }

    #[Apidoc\Title('任务模板文件夹')]
    #[Apidoc\Url('/app/help/doctor/task-template-folders')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('status', type: 'int', require: false, desc: '状态')]
    #[Apidoc\Returned('list', type: 'array', desc: '文件夹列表')]
    public function taskTemplateFolders(Request $request): Response
    {
        return ok($this->service->doctorTaskTemplateFolders($this->memberId, $request->get()));
    }

    #[Apidoc\Title('保存任务模板文件夹')]
    #[Apidoc\Url('/app/help/doctor/task-template-folder')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'string', require: false, desc: '文件夹ID，空为新增')]
    #[Apidoc\Param('name', type: 'string', require: true, desc: '文件夹名称')]
    #[Apidoc\Param('color', type: 'string', require: false, desc: '主题颜色')]
    #[Apidoc\Param('sort', type: 'int', require: false, desc: '排序')]
    #[Apidoc\Param('status', type: 'int', require: false, desc: '状态 1启用 2禁用')]
    #[Apidoc\Returned('id', type: 'string', desc: '文件夹ID')]
    public function saveTaskTemplateFolder(Request $request): Response
    {
        return ok($this->service->saveDoctorTaskTemplateFolder($this->memberId, $request->post()));
    }

    #[Apidoc\Title('任务模板列表')]
    #[Apidoc\Url('/app/help/doctor/task-templates')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('folder_id', type: 'string', require: false, desc: '文件夹ID')]
    #[Apidoc\Query('stage', type: 'string', require: false, desc: '阶段')]
    #[Apidoc\Query('status', type: 'int', require: false, desc: '状态')]
    #[Apidoc\Returned('list', type: 'array', desc: '模板列表')]
    public function taskTemplates(Request $request): Response
    {
        return ok($this->service->doctorTaskTemplates($this->memberId, $request->get()));
    }

    #[Apidoc\Title('保存任务模板')]
    #[Apidoc\Url('/app/help/doctor/task-template')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'string', require: false, desc: '模板ID，空为新增')]
    #[Apidoc\Param('title', type: 'string', require: true, desc: '模板名称')]
    #[Apidoc\Param('folder_id', type: 'string', require: false, desc: '文件夹ID')]
    #[Apidoc\Param('reminder_rule', type: 'array', require: false, desc: '提醒规则')]
    #[Apidoc\Returned('id', type: 'string', desc: '模板ID')]
    public function saveTaskTemplate(Request $request): Response
    {
        return ok($this->service->saveDoctorTaskTemplate($this->memberId, $request->post()));
    }

    #[Apidoc\Title('评估量表列表')]
    #[Apidoc\Url('/app/help/doctor/assessment-scales')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('stage', type: 'string', require: false, desc: '阶段')]
    #[Apidoc\Query('status', type: 'string', require: false, desc: '状态')]
    #[Apidoc\Returned('list', type: 'array', desc: '量表列表')]
    public function assessmentScales(Request $request): Response
    {
        return ok($this->service->doctorAssessmentScales($this->memberId, $request->get()));
    }

    #[Apidoc\Title('保存评估量表')]
    #[Apidoc\Url('/app/help/doctor/assessment-scale')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'string', require: false, desc: '量表ID，空为新增')]
    #[Apidoc\Param('title', type: 'string', require: true, desc: '量表名称')]
    #[Apidoc\Param('questions', type: 'array', require: false, desc: '题目配置')]
    #[Apidoc\Param('scoring_rule', type: 'array', require: false, desc: '评分规则')]
    #[Apidoc\Returned('id', type: 'string', desc: '量表ID')]
    public function saveAssessmentScale(Request $request): Response
    {
        return ok($this->service->saveDoctorAssessmentScale($this->memberId, $request->post()));
    }

    #[Apidoc\Title('发布评估量表')]
    #[Apidoc\Url('/app/help/doctor/assessment-scale/publish')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'string', require: true, desc: '量表ID')]
    #[Apidoc\Returned('id', type: 'string', desc: '量表ID')]
    #[Apidoc\Returned('status', type: 'string', desc: '发布后的状态')]
    public function publishAssessmentScale(Request $request): Response
    {
        return ok($this->service->publishDoctorAssessmentScale($this->memberId, (string) $request->post('id', '')));
    }

    #[Apidoc\Title('医生预约列表')]
    #[Apidoc\Url('/app/help/doctor/appointments')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('member_id', type: 'int', require: false, desc: '患者会员ID')]
    #[Apidoc\Query('date', type: 'string', require: false, desc: '预约日期')]
    #[Apidoc\Query('status', type: 'int', require: false, desc: '预约状态')]
    #[Apidoc\Returned('list', type: 'array', desc: '预约列表')]
    public function appointments(Request $request): Response
    {
        return ok($this->service->doctorAppointments($this->memberId, $request->get()));
    }

    #[Apidoc\Title('确认预约')]
    #[Apidoc\Url('/app/help/doctor/appointment/confirm')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('appointment_id', type: 'int', require: true, desc: '预约ID')]
    #[Apidoc\Param('meet_type', type: 'string', require: false, desc: '接诊方式 link/address/phone')]
    #[Apidoc\Param('meet_link', type: 'string', require: false, desc: '接诊地址或链接')]
    #[Apidoc\Param('confirm_remark', type: 'string', require: false, desc: '确认备注')]
    #[Apidoc\Returned('id', type: 'int', desc: '预约ID')]
    public function confirmAppointment(Request $request): Response
    {
        return ok($this->service->confirmDoctorAppointment($this->memberId, $request->post()));
    }

    #[Apidoc\Title('完成预约')]
    #[Apidoc\Url('/app/help/doctor/appointment/finish')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('appointment_id', type: 'int', require: true, desc: '预约ID')]
    #[Apidoc\Returned('id', type: 'int', desc: '预约ID')]
    public function finishAppointment(Request $request): Response
    {
        return ok($this->service->finishDoctorAppointment($this->memberId, $request->post()));
    }

    #[Apidoc\Title('取消预约')]
    #[Apidoc\Url('/app/help/doctor/appointment/cancel')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('appointment_id', type: 'int', require: true, desc: '预约ID')]
    #[Apidoc\Param('cancel_reason', type: 'string', require: false, desc: '取消原因')]
    #[Apidoc\Returned('id', type: 'int', desc: '预约ID')]
    public function cancelAppointment(Request $request): Response
    {
        return ok($this->service->cancelDoctorAppointment($this->memberId, $request->post()));
    }

    #[Apidoc\Title('拒绝预约')]
    #[Apidoc\Url('/app/help/doctor/appointment/reject')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('appointment_id', type: 'int', require: true, desc: '预约ID')]
    #[Apidoc\Param('confirm_remark', type: 'string', require: false, desc: '拒绝原因')]
    #[Apidoc\Returned('id', type: 'int', desc: '预约ID')]
    public function rejectAppointment(Request $request): Response
    {
        return ok($this->service->rejectDoctorAppointment($this->memberId, $request->post()));
    }
}
