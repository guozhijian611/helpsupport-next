<?php

declare(strict_types=1);

namespace app\command;

use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;

#[AsCommand('b8:migrate', '执行 B8AIadmin 数据库迁移')]
final class B8Migrate extends AbstractPhinxCommand
{
    protected function configure(): void
    {
        $this->addOption('target', 't', InputOption::VALUE_REQUIRED, '迁移到指定版本');
        $this->addOption('dry-run', null, InputOption::VALUE_NONE, '预览迁移 SQL，不写入数据库');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $arguments = ['migrate'];

        if ($target = $input->getOption('target')) {
            $arguments[] = '-t';
            $arguments[] = (string) $target;
        }

        if ($input->getOption('dry-run')) {
            $arguments[] = '--dry-run';
        }

        return $this->runPhinx($arguments, [0], $output);
    }
}
