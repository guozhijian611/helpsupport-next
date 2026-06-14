<?php

declare(strict_types=1);

namespace app\command;

use Phinx\Console\PhinxApplication;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\ArgvInput;
use Symfony\Component\Console\Output\ConsoleOutput;
use Symfony\Component\Console\Output\OutputInterface;

abstract class AbstractPhinxCommand extends Command
{
    protected function runPhinx(array $arguments, array $successExitCodes = [0], ?OutputInterface $output = null): int
    {
        $command = array_merge([
            'phinx',
            '-c',
            $this->databaseFile('phinx.php'),
        ], $arguments);

        $application = new PhinxApplication();
        $application->setAutoExit(false);

        $exitCode = $application->doRun(new ArgvInput($command), $output ?? new ConsoleOutput());
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
