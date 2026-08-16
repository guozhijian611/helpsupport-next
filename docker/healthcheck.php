<?php

declare(strict_types=1);

$port = isset($argv[1]) ? (int) $argv[1] : 8787;
$socket = @fsockopen('127.0.0.1', $port, $errorCode, $errorMessage, 2.0);

if (!is_resource($socket)) {
    fwrite(STDERR, "Webman is unavailable on port {$port}: {$errorCode} {$errorMessage}\n");
    exit(1);
}

fclose($socket);
exit(0);
