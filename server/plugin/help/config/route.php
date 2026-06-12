<?php

use plugin\help\app\api\controller\CommonController;
use plugin\help\app\api\controller\LocalModelController;
use plugin\help\app\api\controller\MeController;
use plugin\help\app\api\controller\PushController;
use Webman\Route;

Route::group('/app/help', function () {
    Route::get('/common/app-config', [CommonController::class, 'appConfig']);
    Route::get('/common/onboarding', [CommonController::class, 'onboarding']);
    Route::post('/common/onboarding/seen', [MeController::class, 'onboardingSeen']);

    Route::get('/me/profile', [MeController::class, 'profile']);
    Route::put('/me/profile', [MeController::class, 'saveProfile']);
    Route::post('/me/doctor-certification', [MeController::class, 'doctorCertification']);

    Route::get('/local-model/catalog', [LocalModelController::class, 'catalog']);
    Route::get('/local-model/prompts', [LocalModelController::class, 'prompts']);

    Route::post('/push/device/register', [PushController::class, 'registerDevice']);
    Route::post('/push/device/unregister', [PushController::class, 'unregisterDevice']);
    Route::get('/push/preference', [PushController::class, 'preference']);
    Route::put('/push/preference', [PushController::class, 'savePreference']);
});
