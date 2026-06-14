<?php

declare(strict_types=1);

namespace app\command;

use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

#[AsCommand('b8:migrate:status', '查看 B8AIadmin 数据库迁移状态')]
final class B8MigrateStatus extends AbstractPhinxCommand
{
    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        return $this->runPhinx(['status'], [0, 3], $output);
    }
}
