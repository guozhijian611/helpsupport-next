<?php
$bool = static function (string $name, bool $default): bool {
    $value = env($name, $default);
    if (is_bool($value)) {
        return $value;
    }

    return filter_var($value, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE) ?? $default;
};

return [
    'enable' => true,

    'build_dir'  => BASE_PATH . DIRECTORY_SEPARATOR . 'build',

    'phar_filename' => 'webman.phar',

    'phar_format' => Phar::PHAR, // Phar archive format: Phar::PHAR, Phar::TAR, Phar::ZIP

    'phar_compression' => Phar::NONE, // Compression method for Phar archive: Phar::NONE, Phar::GZ, Phar::BZ2

    'bin_filename' => env('WEBMAN_BIN_FILENAME', 'server'),

    'cleanup_intermediate_files' => $bool('WEBMAN_BIN_CLEANUP', true),

    'bin_runtime_cache_dir' => env(
        'WEBMAN_BIN_RUNTIME_CACHE_DIR',
        BASE_PATH . DIRECTORY_SEPARATOR . 'runtime' . DIRECTORY_SEPARATOR . 'build-bin-cache'
    ),

    'signature_algorithm'=> Phar::SHA256, //set the signature algorithm for a phar and apply it. The signature algorithm must be one of Phar::MD5, Phar::SHA1, Phar::SHA256, Phar::SHA512, or Phar::OPENSSL.

    'private_key_file'  => '', // The file path for certificate or OpenSSL private key file.

    'exclude_pattern'   => '#^(?!.*(composer.json|/.github/|/.idea/|/.git/|/.setting/|/runtime/|/vendor-bin/|/build/|/vendor/webman/admin/))(.*)$#',

    'exclude_files'     => [
        '.env', 'LICENSE', 'composer.json', 'composer.lock', 'start.php', 'webman.phar', 'webman.bin',
        'app/command/BuildBinCommand.php',
    ],

    'custom_ini' => '
memory_limit = 256M
    ',
];
