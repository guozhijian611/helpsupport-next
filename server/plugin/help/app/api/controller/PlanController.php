<?php

declare(strict_types=1);

namespace plugin\help\app\api\controller;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\service\HelpApiService;
use plugin\saiuser\basic\BaseController;
use support\Request;
use support\Response;

#[Apidoc\Group('计划')]
#[Apidoc\Title('HelpSupport计划任务')]
class PlanController extends BaseController
{
    public function __construct(private readonly HelpApiService $service = new HelpApiService())
    {
        parent::__construct();
    }

    #[Apidoc\Title('当前治疗计划')]
    #[Apidoc\Url('/app/help/plan/current')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Returned('plans', type: 'array', desc: '当前计划及阶段')]
    public function current(Request $request): Response
    {
        return ok($this->service->currentPlans($this->memberId));
    }

    #[Apidoc\Title('每日任务列表')]
    #[Apidoc\Url('/app/help/plan/tasks')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('date', type: 'string', require: false, desc: '任务日期 YYYY-MM-DD')]
    #[Apidoc\Query('status', type: 'int', require: false, desc: '任务状态')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '每日任务列表')]
    #[Apidoc\Returned('total', type: 'int', desc: '总数')]
    #[Apidoc\Returned('page', type: 'int', desc: '当前页码')]
    #[Apidoc\Returned('page_size', type: 'int', desc: '每页数量')]
    public function tasks(Request $request): Response
    {
        return ok($this->service->dailyTasks($this->memberId, $request->get()));
    }

    #[Apidoc\Title('更新任务状态')]
    #[Apidoc\Url('/app/help/plan/task/status')]
    #[Apidoc\Method('PUT')]
    #[Apidoc\Param('task_id', type: 'int', require: true, desc: '任务ID')]
    #[Apidoc\Param('status', type: 'int', require: true, desc: '状态 0待办 1完成 2跳过 3延期')]
    #[Apidoc\Param('completion_note', type: 'string', require: false, desc: '完成备注')]
    #[Apidoc\Param('feedback_content', type: 'string', require: false, desc: '患者反馈内容')]
    #[Apidoc\Returned('id', type: 'int', desc: '任务ID')]
    #[Apidoc\Returned('status', type: 'int', desc: '更新后的任务状态')]
    #[Apidoc\Returned('completed_time', type: 'datetime', desc: '完成时间')]
    #[Apidoc\Returned('feedback_content', type: 'string', desc: '患者反馈内容')]
    public function saveTaskStatus(Request $request): Response
    {
        return ok($this->service->saveTaskStatus($this->memberId, $request->all()));
    }

    #[Apidoc\Title('评估结果列表')]
    #[Apidoc\Url('/app/help/plan/assessment-results')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '评估结果列表')]
    #[Apidoc\Returned('total', type: 'int', desc: '总数')]
    #[Apidoc\Returned('page', type: 'int', desc: '当前页码')]
    #[Apidoc\Returned('page_size', type: 'int', desc: '每页数量')]
    public function assessmentResults(Request $request): Response
    {
        return ok($this->service->assessmentResults($this->memberId, $request->get()));
    }

    #[Apidoc\Title('评估任务详情')]
    #[Apidoc\Url('/app/help/plan/assessment-task')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('task_id', type: 'int', require: true, desc: '任务ID')]
    #[Apidoc\Returned('task', type: 'object', desc: '任务信息')]
    #[Apidoc\Returned('scale', type: 'object', desc: '量表信息')]
    #[Apidoc\Returned('result', type: 'object', desc: '已保存的评估结果')]
    public function assessmentTask(Request $request): Response
    {
        return ok($this->service->assessmentTaskDetail(
            $this->memberId,
            (int) $request->get('task_id', 0)
        ));
    }

    #[Apidoc\Title('提交评估结果')]
    #[Apidoc\Url('/app/help/plan/assessment-result')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('assessment_title', type: 'string', require: true, desc: '量表名称')]
    #[Apidoc\Param('answers', type: 'array', require: false, desc: '作答结果')]
    #[Apidoc\Param('achieved_score', type: 'int', require: false, desc: '实得分')]
    #[Apidoc\Returned('id', type: 'int', desc: '评估结果ID')]
    #[Apidoc\Returned('assessment_title', type: 'string', desc: '量表名称')]
    #[Apidoc\Returned('achieved_score', type: 'int', desc: '实得分')]
    public function saveAssessmentResult(Request $request): Response
    {
        return ok($this->service->saveAssessmentResult($this->memberId, $request->post()));
    }
}
