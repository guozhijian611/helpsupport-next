<?php

$serverPath = dirname(__DIR__) . '/server';
$autoload = $serverPath . '/vendor/autoload.php';

if (is_file($autoload)) {
    require_once $autoload;
}

if (class_exists(\Dotenv\Dotenv::class) && is_file($serverPath . '/.env')) {
    if (method_exists(\Dotenv\Dotenv::class, 'createUnsafeMutable')) {
        \Dotenv\Dotenv::createUnsafeMutable($serverPath)->load();
    } else {
        \Dotenv\Dotenv::createMutable($serverPath)->load();
    }
}

$env = static function (string $name, mixed $default = null): mixed {
    $value = getenv($name);
    if ($value === false || $value === '') {
        return $default;
    }
    return $value;
};

return [
    'paths' => [
        'migrations' => __DIR__ . '/migrations',
        'seeds' => __DIR__ . '/seeds',
    ],
    'environments' => [
        'default_migration_table' => 'phinxlog',
        'default_environment' => 'default',
        'default' => [
            'adapter' => $env('DB_TYPE', 'mysql'),
            'host' => $env('DB_HOST', '127.0.0.1'),
            'name' => $env('DB_NAME', 'saiadmin'),
            'user' => $env('DB_USER', 'root'),
            'pass' => $env('DB_PASSWORD', '123456'),
            'port' => (int) $env('DB_PORT', 3306),
            'charset' => $env('DB_CHARSET', 'utf8mb4'),
            'collation' => $env('DB_COLLATION', 'utf8mb4_general_ci'),
            'table_prefix' => $env('DB_PREFIX', ''),
        ],
    ],
    'version_order' => 'creation',
];
