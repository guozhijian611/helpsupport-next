<?php

declare(strict_types=1);

namespace app\command;

use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

#[AsCommand('b8:migrate:create', '创建 B8AIadmin 数据库迁移')]
final class B8MigrateCreate extends AbstractPhinxCommand
{
    protected function configure(): void
    {
        $this->addArgument('name', InputArgument::REQUIRED, '迁移类名，例如 AddUserStatus');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        return $this->runPhinx(['create', (string) $input->getArgument('name')], [0], $output);
    }
}
