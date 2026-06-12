<?php
return [
    'enable'  => true,
    'apidoc' => [
        // （选配）文档标题，显示在左上角与首页
        'title'              => 'B8AIadmin 接口文档',
        // （选配）文档描述，显示在首页
        'desc'               => '基于 SaiAdmin/Webman 控制器注解生成，供接口调试与 uniapp 自动接口生成使用。',
        // （必须）设置文档的应用/版本
        'apps'           => [
            [
                'title'=>'AI 插件移动端接口',
                'path'=>'plugin\saiai\app\api\controller',
                'key'=>'saiai-api',
            ],
            [
                'title'=>'会员插件移动端接口',
                'path'=>'plugin\saiuser\app\api\controller',
                'key'=>'saiuser-api',
            ],
            [
                'title'=>'支付插件移动端接口',
                'path'=>'plugin\saipay\app\api\controller',
                'key'=>'saipay-api',
            ],
            [
                'title'=>'HelpSupport 移动端接口',
                'path'=>'plugin\help\app\api\controller',
                'key'=>'help-api',
            ]
        ],
        // （必须）指定通用注释定义的文件地址
        'definitions'        => "app\common\controller\Definitions",
        // （必须）自动生成url规则，当接口不添加@Apidoc\Url ("xxx")注解时，使用以下规则自动生成
        'auto_url' => [
            // 字母规则，lcfirst=首字母小写；ucfirst=首字母大写；
            'letter_rule' => "lcfirst",
            // url前缀
            'prefix'=>"",
            // Webman/SaiAdmin 插件控制器路径较深，自动 URL 时去掉固定命名空间片段。
            'filter_keys' => ['plugin', 'app', 'admin', 'api', 'controller'],
        ],
        // （选配）是否自动注册路由
        'auto_register_routes'=>false,
        // （必须）缓存配置
        'cache'              => [
            // 是否开启缓存
            'enable' => false,
        ],
        // （必须）权限认证配置
        'auth'               => [
            // 是否启用密码验证
            'enable'     => false,
            // 全局访问密码
            'password'   => "123456",
            // 密码加密盐
            'secret_key' => "apidoc#hg_code",
            // 授权访问后的有效期
            'expire' => 24*60*60
        ],
        // 全局参数
        'params'=>[
            // （选配）全局的请求Header
            'header'=>[
                // name=字段名，type=字段类型，require=是否必须，default=默认值，desc=字段描述
                ['name'=>'Authorization','type'=>'string','require'=>true,'desc'=>'身份令牌Token'],
            ],
            // （选配）全局的请求Query
            'query'=>[
                // 同上 header
            ],
            // （选配）全局的请求Body
            'body'=>[
                // 同上 header
            ],
        ],
        // 全局响应体
        'responses'=>[
            // 成功响应体
            'success'=>[
                ['name'=>'code','desc'=>'业务代码','type'=>'int','require'=>1],
                ['name'=>'message','desc'=>'业务信息','type'=>'string','require'=>1],
                //参数同上 headers；main=true来指定接口Returned参数挂载节点
                ['name'=>'data','desc'=>'业务数据','main'=>true,'type'=>'object','require'=>1],
            ],
            // 异常响应体
            'error'=>[
                ['name'=>'code','desc'=>'业务代码','type'=>'int','require'=>1,'md'=>'/docs/HttpError.md'],
                ['name'=>'message','desc'=>'业务信息','type'=>'string','require'=>1],
            ]
        ],
        // （选配）全局响应状态码
        'responses_status'=>[
            [
                'name'=>'200',
                'desc'=>'请求成功'
            ],
            [
                'name'=>'401',
                'desc'=>'登录令牌无效',
                'contentType'=>''
            ],
        ],
        //（选配）默认作者
        'default_author'=>'B8AIadmin',
        //（选配）默认请求类型
        'default_method'=>'GET',
        //（选配）Apidoc允许跨域访问
        'allowCrossDomain'=>true,
        /**
         * （选配）解析时忽略带@注解的关键词，当注解中存在带@字符并且非Apidoc注解，如 @key test，此时Apidoc页面报类似以下错误时:
         * [Semantical Error] The annotation "@key" in method xxx() was never imported. Did you maybe forget to add a "use" statement for this annotation?
         */
        'ignored_annitation'=>[],

        // （选配）解析时忽略的方法
        'ignored_methods'=>[],

        // （选配）数据库配置
        'database'=>[],
        // （选配）Markdown文档
        'docs'              => [],
        // （选配）接口生成器配置 注意：是一个二维数组
        'generator' =>[]
    ]
];
