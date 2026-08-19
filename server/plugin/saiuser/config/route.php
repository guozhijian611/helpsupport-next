<?php

use plugin\saiuser\app\admin\controller\cms\ArticleController;
use plugin\saiuser\app\admin\controller\member\MemberController;
use Webman\Route;

Route::get('/app/saiuser/admin/cms/Article/manual', [ArticleController::class, 'manual']);
Route::get('/app/saiuser/admin/cms/Article/manualRead', [ArticleController::class, 'manualRead']);
Route::get('/app/saiuser/admin/member/Member/related', [MemberController::class, 'related']);
