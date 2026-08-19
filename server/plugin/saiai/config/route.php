<?php

use plugin\saiai\app\admin\controller\speech\SpeechTestController;
use Webman\Route;

Route::get('/app/saiai/admin/speech/SpeechTest/configs', [SpeechTestController::class, 'configs']);
Route::post('/app/saiai/admin/speech/SpeechTest/asr', [SpeechTestController::class, 'asr']);
Route::post('/app/saiai/admin/speech/SpeechTest/tts', [SpeechTestController::class, 'tts']);
