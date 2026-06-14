<?php

declare(strict_types=1);

namespace app\command;

use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Helper\QuestionHelper;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Question\ConfirmationQuestion;

#[AsCommand('b8:migrate:rollback', '回滚 B8AIadmin 数据库迁移')]
final class B8MigrateRollback extends AbstractPhinxCommand
{
    protected function configure(): void
    {
        $this->addOption('target', 't', InputOption::VALUE_REQUIRED, '回滚到指定版本');
        $this->addOption('force', 'f', InputOption::VALUE_NONE, '跳过确认直接回滚');
        $this->addOption('dry-run', null, InputOption::VALUE_NONE, '预览回滚 SQL，不写入数据库');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        if (!$input->getOption('force')) {
            $helper = $this->getHelper('question');
            if (!$helper instanceof QuestionHelper) {
                return self::FAILURE;
            }

            $question = new ConfirmationQuestion('确认要回滚数据库迁移吗？[y/N] ', false);
            if (!$helper->ask($input, $output, $question)) {
                $output->writeln('<comment>已取消回滚。</comment>');
                return self::SUCCESS;
            }
        }

        $arguments = ['rollback'];

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
