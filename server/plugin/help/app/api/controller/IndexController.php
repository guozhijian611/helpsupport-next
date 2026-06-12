<?php

namespace plugin\help\app\api\controller;

use plugin\saiadmin\basic\OpenController;

class IndexController extends OpenController
{

    public function index()
    {
        return $this->success([
            'app' => 'help',
            'version' => '1.0.0',
        ]);
    }

}

