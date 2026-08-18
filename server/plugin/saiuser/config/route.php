<?php

use plugin\saiuser\app\admin\controller\cms\ArticleController;
use Webman\Route;

Route::get('/app/saiuser/admin/cms/Article/manual', [ArticleController::class, 'manual']);
Route::get('/app/saiuser/admin/cms/Article/manualRead', [ArticleController::class, 'manualRead']);
