<?php

declare(strict_types=1);

namespace app\command;

use Symfony\Component\Console\Command\Command;

abstract class AbstractPhinxCommand extends Command
{
    protected function runPhinx(array $arguments, array $successExitCodes = [0]): int
    {
        $command = array_merge([
            PHP_BINARY,
            base_path('vendor/bin/phinx'),
            '-c',
            $this->databaseFile('phinx.php'),
        ], $arguments);

        $process = proc_open(
            $command,
            [
                0 => STDIN,
                1 => STDOUT,
                2 => STDERR,
            ],
            $pipes,
            base_path(false)
        );

        if (!is_resource($process)) {
            return self::FAILURE;
        }

        $exitCode = proc_close($process);
        return in_array($exitCode, $successExitCodes, true) ? self::SUCCESS : $exitCode;
    }

    protected function databaseFile(string $file): string
    {
        $candidates = [
            base_path(false) . DIRECTORY_SEPARATOR . 'Database' . DIRECTORY_SEPARATOR . $file,
            base_path('../Database/' . $file),
        ];

        foreach ($candidates as $candidate) {
            if (is_file($candidate)) {
                return $candidate;
            }
        }

        return $candidates[0];
    }
}
