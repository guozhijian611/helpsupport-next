<?php

use plugin\help\app\api\controller\AppointmentController;
use plugin\help\app\api\controller\AuthController;
use plugin\help\app\api\controller\ChatController;
use plugin\help\app\api\controller\CommunityController;
use plugin\help\app\api\controller\CommonController;
use plugin\help\app\api\controller\DoctorController;
use plugin\help\app\api\controller\HomeController;
use plugin\help\app\api\controller\LocalModelController;
use plugin\help\app\api\controller\MaterialController;
use plugin\help\app\api\controller\MeController;
use plugin\help\app\api\controller\PlanController;
use plugin\help\app\api\controller\PushController;
use plugin\help\app\admin\controller\appointment\SaDoctorAppointmentController as AdminDoctorAppointmentController;
use plugin\help\app\admin\controller\audit\SaHelpDoctorProfileController as AdminHelpDoctorProfileController;
use plugin\help\app\admin\controller\chat\SaMemberChatConfigController as AdminMemberChatConfigController;
use plugin\help\app\admin\controller\community\SaCommunityCommentController as AdminCommunityCommentController;
use plugin\help\app\admin\controller\community\SaCommunityPostController as AdminCommunityPostController;
use plugin\help\app\admin\controller\community\SaCommunityReportController as AdminCommunityReportController;
use plugin\help\app\admin\controller\config\SaAppOnboardingPageController as AdminAppOnboardingPageController;
use plugin\help\app\admin\controller\doctor\SaDoctorAssessmentScaleController as AdminDoctorAssessmentScaleController;
use plugin\help\app\admin\controller\doctor\SaDoctorPatientController as AdminDoctorPatientController;
use plugin\help\app\admin\controller\doctor\SaDoctorTaskTemplateController as AdminDoctorTaskTemplateController;
use plugin\help\app\admin\controller\doctor\SaDoctorTaskTemplateFolderController as AdminDoctorTaskTemplateFolderController;
use plugin\help\app\admin\controller\localModel\SaLocalModelCatalogController as AdminLocalModelCatalogController;
use plugin\help\app\admin\controller\localModel\SaLocalModelPromptController as AdminLocalModelPromptController;
use plugin\help\app\admin\controller\material\SaContentCategoryController as AdminContentCategoryController;
use plugin\help\app\admin\controller\material\SaContentMaterialController as AdminContentMaterialController;
use plugin\help\app\admin\controller\message\SaMemberMessageController as AdminMemberMessageController;
use plugin\help\app\admin\controller\plan\SaDailyTaskController as AdminDailyTaskController;
use plugin\help\app\admin\controller\plan\SaMemberAssessmentResultController as AdminAssessmentResultController;
use plugin\help\app\admin\controller\plan\SaTreatmentPlanController as AdminTreatmentPlanController;
use plugin\help\app\admin\controller\plan\SaTreatmentStageController as AdminTreatmentStageController;
use plugin\help\app\admin\controller\push\SaMemberPushDeviceController as AdminMemberPushDeviceController;
use plugin\help\app\admin\controller\push\SaMemberPushPreferenceController as AdminMemberPushPreferenceController;
use Webman\Route;

Route::group('/app/help', function () {
    Route::post('/auth/account-login', [AuthController::class, 'accountLogin']);
    Route::post('/auth/google', [AuthController::class, 'google']);
    Route::post('/auth/apple', [AuthController::class, 'apple']);
    Route::post('/auth/refresh', [AuthController::class, 'refresh']);

    Route::get('/common/app-config', [CommonController::class, 'appConfig']);
    Route::get('/common/onboarding', [CommonController::class, 'onboarding']);
    Route::post('/common/onboarding/seen', [MeController::class, 'onboardingSeen']);

    Route::get('/home/summary', [HomeController::class, 'summary']);

    Route::get('/chat/overview', [ChatController::class, 'overview']);
    Route::get('/chat/config', [ChatController::class, 'configs']);
    Route::post('/chat/config', [ChatController::class, 'saveConfig']);
    Route::get('/chat/sessions', [ChatController::class, 'sessions']);
    Route::post('/chat/session', [ChatController::class, 'saveSession']);
    Route::post('/chat/session/delete', [ChatController::class, 'deleteSession']);
    Route::get('/chat/records', [ChatController::class, 'records']);
    Route::post('/chat/record', [ChatController::class, 'saveRecord']);
    Route::post('/chat/send', [ChatController::class, 'send']);

    Route::get('/community/tags', [CommunityController::class, 'tags']);
    Route::get('/community/posts', [CommunityController::class, 'posts']);
    Route::get('/community/post', [CommunityController::class, 'post']);
    Route::post('/community/post', [CommunityController::class, 'savePost']);
    Route::get('/community/comments', [CommunityController::class, 'comments']);
    Route::post('/community/comment', [CommunityController::class, 'saveComment']);
    Route::post('/community/like', [CommunityController::class, 'toggleLike']);
    Route::post('/community/collect', [CommunityController::class, 'toggleCollect']);
    Route::post('/community/report', [CommunityController::class, 'report']);

    Route::get('/me/profile', [MeController::class, 'profile']);
    Route::post('/me/profile/save', [MeController::class, 'saveProfile']);
    Route::post('/me/doctor-certification', [MeController::class, 'doctorCertification']);
    Route::get('/me/journals', [MeController::class, 'journals']);
    Route::post('/me/journal', [MeController::class, 'saveJournal']);
    Route::post('/me/journal/delete', [MeController::class, 'deleteJournal']);
    Route::get('/me/messages', [MeController::class, 'messages']);
    Route::put('/me/message/read', [MeController::class, 'readMessage']);

    Route::get('/material/categories', [MaterialController::class, 'categories']);
    Route::get('/material/list', [MaterialController::class, 'list']);
    Route::get('/material/detail', [MaterialController::class, 'detail']);
    Route::get('/material/history', [MaterialController::class, 'history']);
    Route::post('/material/history/save', [MaterialController::class, 'saveHistory']);
    Route::get('/material/collections', [MaterialController::class, 'collections']);
    Route::post('/material/like', [MaterialController::class, 'toggleLike']);
    Route::post('/material/collect', [MaterialController::class, 'toggleCollect']);

    Route::get('/plan/current', [PlanController::class, 'current']);
    Route::get('/plan/tasks', [PlanController::class, 'tasks']);
    Route::put('/plan/task/status', [PlanController::class, 'saveTaskStatus']);
    Route::get('/plan/assessment-results', [PlanController::class, 'assessmentResults']);
    Route::post('/plan/assessment-result', [PlanController::class, 'saveAssessmentResult']);

    Route::get('/appointment/doctors', [AppointmentController::class, 'doctors']);
    Route::get('/appointment/list', [AppointmentController::class, 'list']);
    Route::post('/appointment', [AppointmentController::class, 'create']);
    Route::post('/appointment/cancel', [AppointmentController::class, 'cancel']);

    Route::get('/doctor/patients', [DoctorController::class, 'patients']);
    Route::post('/doctor/patient/bind', [DoctorController::class, 'bindPatient']);
    Route::post('/doctor/patient/unbind', [DoctorController::class, 'unbindPatient']);
    Route::get('/doctor/patient/plans', [DoctorController::class, 'patientPlans']);
    Route::post('/doctor/treatment-plan', [DoctorController::class, 'saveTreatmentPlan']);
    Route::get('/doctor/daily-tasks', [DoctorController::class, 'dailyTasks']);
    Route::post('/doctor/daily-task', [DoctorController::class, 'saveDailyTask']);
    Route::get('/doctor/task-template-folders', [DoctorController::class, 'taskTemplateFolders']);
    Route::get('/doctor/task-templates', [DoctorController::class, 'taskTemplates']);
    Route::post('/doctor/task-template', [DoctorController::class, 'saveTaskTemplate']);
    Route::get('/doctor/assessment-scales', [DoctorController::class, 'assessmentScales']);
    Route::post('/doctor/assessment-scale', [DoctorController::class, 'saveAssessmentScale']);
    Route::post('/doctor/assessment-scale/publish', [DoctorController::class, 'publishAssessmentScale']);
    Route::get('/doctor/appointments', [DoctorController::class, 'appointments']);
    Route::post('/doctor/appointment/confirm', [DoctorController::class, 'confirmAppointment']);
    Route::post('/doctor/appointment/finish', [DoctorController::class, 'finishAppointment']);
    Route::post('/doctor/appointment/cancel', [DoctorController::class, 'cancelAppointment']);
    Route::post('/doctor/appointment/reject', [DoctorController::class, 'rejectAppointment']);

    Route::get('/local-model/catalog', [LocalModelController::class, 'catalog']);
    Route::get('/local-model/prompts', [LocalModelController::class, 'prompts']);

    Route::post('/push/device/register', [PushController::class, 'registerDevice']);
    Route::post('/push/device/unregister', [PushController::class, 'unregisterDevice']);
    Route::get('/push/preference', [PushController::class, 'preference']);
    Route::post('/push/preference/save', [PushController::class, 'savePreference']);
});

Route::group('/app/help/admin/community', function () {
    fastRoute('SaCommunityPost', AdminCommunityPostController::class);
    Route::post('/SaCommunityPost/audit', [AdminCommunityPostController::class, 'audit']);

    fastRoute('SaCommunityComment', AdminCommunityCommentController::class);
    Route::post('/SaCommunityComment/audit', [AdminCommunityCommentController::class, 'audit']);

    fastRoute('SaCommunityReport', AdminCommunityReportController::class);
    Route::post('/SaCommunityReport/handle', [AdminCommunityReportController::class, 'handle']);
});

Route::group('/app/help/admin/config', function () {
    fastRoute('SaAppOnboardingPage', AdminAppOnboardingPageController::class);
});

Route::group('/app/help/admin/audit', function () {
    fastRoute('SaHelpDoctorProfile', AdminHelpDoctorProfileController::class);
});

Route::group('/app/help/admin/chat', function () {
    fastRoute('SaMemberChatConfig', AdminMemberChatConfigController::class);
});

Route::group('/app/help/admin/localModel', function () {
    fastRoute('SaLocalModelCatalog', AdminLocalModelCatalogController::class);
    fastRoute('SaLocalModelPrompt', AdminLocalModelPromptController::class);
});

Route::group('/app/help/admin/plan', function () {
    fastRoute('SaTreatmentPlan', AdminTreatmentPlanController::class);
    fastRoute('SaTreatmentStage', AdminTreatmentStageController::class);
    fastRoute('SaDailyTask', AdminDailyTaskController::class);
    fastRoute('SaMemberAssessmentResult', AdminAssessmentResultController::class);
});

Route::group('/app/help/admin/material', function () {
    fastRoute('SaContentCategory', AdminContentCategoryController::class);
    fastRoute('SaContentMaterial', AdminContentMaterialController::class);
    Route::post('/SaContentMaterial/audit', [AdminContentMaterialController::class, 'audit']);
});

Route::group('/app/help/admin/appointment', function () {
    fastRoute('SaDoctorAppointment', AdminDoctorAppointmentController::class);
    Route::post('/SaDoctorAppointment/confirm', [AdminDoctorAppointmentController::class, 'confirm']);
    Route::post('/SaDoctorAppointment/finish', [AdminDoctorAppointmentController::class, 'finish']);
    Route::post('/SaDoctorAppointment/cancel', [AdminDoctorAppointmentController::class, 'cancel']);
    Route::post('/SaDoctorAppointment/reject', [AdminDoctorAppointmentController::class, 'reject']);
});

Route::group('/app/help/admin/doctor', function () {
    fastRoute('SaDoctorPatient', AdminDoctorPatientController::class);
    fastRoute('SaDoctorTaskTemplateFolder', AdminDoctorTaskTemplateFolderController::class);
    fastRoute('SaDoctorTaskTemplate', AdminDoctorTaskTemplateController::class);
    fastRoute('SaDoctorAssessmentScale', AdminDoctorAssessmentScaleController::class);
    Route::post('/SaDoctorAssessmentScale/publish', [AdminDoctorAssessmentScaleController::class, 'publish']);
    Route::post('/SaDoctorAssessmentScale/disable', [AdminDoctorAssessmentScaleController::class, 'disable']);
});

Route::group('/app/help/admin/push', function () {
    fastRoute('SaMemberPushDevice', AdminMemberPushDeviceController::class);
    fastRoute('SaMemberPushPreference', AdminMemberPushPreferenceController::class);
    Route::post('/SaMemberPushPreference/enable', [AdminMemberPushPreferenceController::class, 'enable']);
    Route::post('/SaMemberPushPreference/disable', [AdminMemberPushPreferenceController::class, 'disable']);
});

Route::group('/app/help/admin/message', function () {
    fastRoute('SaMemberMessage', AdminMemberMessageController::class);
    Route::post('/SaMemberMessage/markRead', [AdminMemberMessageController::class, 'markRead']);
    Route::post('/SaMemberMessage/markPushed', [AdminMemberMessageController::class, 'markPushed']);
    Route::post('/SaMemberMessage/markFailed', [AdminMemberMessageController::class, 'markFailed']);
});
