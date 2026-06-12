<?php

declare(strict_types=1);

namespace plugin\help\app\api\controller;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\service\HelpApiService;
use plugin\saiuser\basic\BaseController;
use support\Request;
use support\Response;

#[Apidoc\Group('推送')]
#[Apidoc\Title('HelpSupport推送设备')]
class PushController extends BaseController
{
    public function __construct(private readonly HelpApiService $service = new HelpApiService())
    {
        parent::__construct();
    }

    #[Apidoc\Title('注册推送设备')]
    #[Apidoc\Url('/app/help/push/device')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('device_id', type: 'string', require: true, desc: '设备标识')]
    #[Apidoc\Param('platform', type: 'string', require: true, desc: 'ios/android')]
    #[Apidoc\Param('fcm_token', type: 'string', require: false, desc: 'Firebase FCM Token')]
    #[Apidoc\Param('apns_token', type: 'string', require: false, desc: 'iOS APNs Token')]
    #[Apidoc\Param('app_version', type: 'string', require: false, desc: 'App版本')]
    #[Apidoc\Param('locale', type: 'string', require: false, desc: '语言')]
    #[Apidoc\Param('timezone', type: 'string', require: false, desc: '时区')]
    #[Apidoc\Returned('id', type: 'int', desc: '设备记录ID')]
    public function registerDevice(Request $request): Response
    {
        return ok($this->service->registerDevice($this->memberId, $request->post()));
    }

    #[Apidoc\Title('注销推送设备')]
    #[Apidoc\Url('/app/help/push/device/logout')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('device_id', type: 'string', require: true, desc: '设备标识')]
    #[Apidoc\Param('platform', type: 'string', require: true, desc: 'ios/android')]
    public function logoutDevice(Request $request): Response
    {
        $this->service->logoutDevice($this->memberId, $request->post());
        return ok('操作成功');
    }

    #[Apidoc\Title('读取推送偏好')]
    #[Apidoc\Url('/app/help/push/preference')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Returned('is_push_enabled', type: 'int', desc: '总通知开关 1是 2否')]
    public function preference(Request $request): Response
    {
        return ok($this->service->pushPreference($this->memberId));
    }

    #[Apidoc\Title('保存推送偏好')]
    #[Apidoc\Url('/app/help/push/preference')]
    #[Apidoc\Method('PUT')]
    #[Apidoc\Param('is_push_enabled', type: 'int', require: false, desc: '总通知开关 1是 2否')]
    #[Apidoc\Param('is_task_reminder_enabled', type: 'int', require: false, desc: '任务提醒 1是 2否')]
    #[Apidoc\Param('is_community_enabled', type: 'int', require: false, desc: '社区互动 1是 2否')]
    #[Apidoc\Param('is_appointment_enabled', type: 'int', require: false, desc: '预约提醒 1是 2否')]
    #[Apidoc\Param('is_audit_notice_enabled', type: 'int', require: false, desc: '审核/系统通知 1是 2否')]
    #[Apidoc\Param('is_local_companion_enabled', type: 'int', require: false, desc: '本地陪伴提醒 1是 2否')]
    #[Apidoc\Param('quiet_start_time', type: 'string', require: false, desc: '免打扰开始时间 HH:mm:ss')]
    #[Apidoc\Param('quiet_end_time', type: 'string', require: false, desc: '免打扰结束时间 HH:mm:ss')]
    public function savePreference(Request $request): Response
    {
        return ok($this->service->savePushPreference($this->memberId, $request->all()));
    }
}
