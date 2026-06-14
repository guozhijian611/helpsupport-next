<?php

declare(strict_types=1);

namespace app\command;

use PDO;
use PDOException;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Helper\QuestionHelper;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Question\ConfirmationQuestion;
use Symfony\Component\Console\Question\Question;

#[AsCommand('b8:install', '配置数据库并执行 B8AIadmin 首次安装')]
final class B8Install extends AbstractPhinxCommand
{
    protected function configure(): void
    {
        $this->addOption('force', 'f', InputOption::VALUE_NONE, '跳过 .env 更新确认');
        $this->addOption('no-import', null, InputOption::VALUE_NONE, '不导入 Database/b8aiadmin.sql');
        $this->addOption('no-migrate', null, InputOption::VALUE_NONE, '不执行 Phinx 迁移');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $envPath = base_path('.env');
        $examplePath = base_path('.env.example');

        if (!is_file($envPath)) {
            if (!is_file($examplePath)) {
                $output->writeln('<error>未找到 .env.example，无法生成 .env。</error>');
                return self::FAILURE;
            }
            copy($examplePath, $envPath);
            $output->writeln('<info>已从 .env.example 生成 .env。</info>');
        } elseif (!$input->getOption('force') && $input->isInteractive() && !$this->confirm($input, $output, '检测到 .env 已存在，是否更新数据库配置？', true)) {
            $output->writeln('<comment>已保留现有 .env。</comment>');
            return self::SUCCESS;
        }

        $env = $this->readEnv($envPath);
        $config = [
            'DB_TYPE' => 'mysql',
            'DB_HOST' => $this->ask($input, $output, '数据库主机', $env['DB_HOST'] ?? '127.0.0.1'),
            'DB_PORT' => $this->ask($input, $output, '数据库端口', $env['DB_PORT'] ?? '3306'),
            'DB_NAME' => $this->ask($input, $output, '数据库名称', $env['DB_NAME'] ?? 'b8aiadmin'),
            'DB_USER' => $this->ask($input, $output, '数据库用户', $env['DB_USER'] ?? 'root'),
            'DB_PASSWORD' => $this->askPassword($input, $output, $env['DB_PASSWORD'] ?? ''),
            'DB_PREFIX' => $this->ask($input, $output, '数据表前缀', $env['DB_PREFIX'] ?? ''),
            'DB_CHARSET' => $this->ask($input, $output, '数据库字符集', $env['DB_CHARSET'] ?? 'utf8mb4'),
            'DB_COLLATION' => $this->ask($input, $output, '数据库排序规则', $env['DB_COLLATION'] ?? 'utf8mb4_general_ci'),
        ];

        $this->writeEnv($envPath, $config);
        $output->writeln('<info>数据库配置已写入 .env。</info>');

        try {
            $pdo = $this->connectServer($config);
            $this->ensureDatabase($pdo, $config, $input, $output);
            $db = $this->connectDatabase($config);
        } catch (PDOException $e) {
            $output->writeln('<error>数据库连接失败：' . $e->getMessage() . '</error>');
            return self::FAILURE;
        }

        if (!$input->getOption('no-import')) {
            $this->importBaselineIfNeeded($db, $input, $output);
        }

        if (!$input->getOption('no-migrate')) {
            $output->writeln('<info>开始执行 Phinx 迁移...</info>');
            $exitCode = $this->runPhinx(['migrate']);
            if ($exitCode !== self::SUCCESS) {
                return $exitCode;
            }
        }

        $output->writeln('<info>B8AIadmin 首次安装流程完成。</info>');
        return self::SUCCESS;
    }

    private function ask(InputInterface $input, OutputInterface $output, string $label, string $default): string
    {
        if (!$input->isInteractive()) {
            return $default;
        }

        $question = new Question("<question>{$label} [{$default}]：</question> ", $default);
        $helper = $this->questionHelper();
        return (string) $helper->ask($input, $output, $question);
    }

    private function askPassword(InputInterface $input, OutputInterface $output, string $default): string
    {
        if (!$input->isInteractive()) {
            return $default;
        }

        $question = new Question('<question>数据库密码 [直接回车保留当前值]：</question> ', $default);
        $question->setHidden(true);
        $question->setHiddenFallback(false);
        $helper = $this->questionHelper();
        return (string) $helper->ask($input, $output, $question);
    }

    private function confirm(InputInterface $input, OutputInterface $output, string $message, bool $default): bool
    {
        if (!$input->isInteractive()) {
            return $default;
        }

        $question = new ConfirmationQuestion('<question>' . $message . '</question> ', $default);
        return (bool) $this->questionHelper()->ask($input, $output, $question);
    }

    private function questionHelper(): QuestionHelper
    {
        $helper = $this->getHelper('question');
        if (!$helper instanceof QuestionHelper) {
            throw new \RuntimeException('Question helper unavailable.');
        }
        return $helper;
    }

    private function readEnv(string $path): array
    {
        $values = [];
        foreach (file($path, FILE_IGNORE_NEW_LINES) ?: [] as $line) {
            if (preg_match('/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/', $line, $matches)) {
                $values[$matches[1]] = trim($matches[2], " \t\n\r\0\x0B'\"");
            }
        }
        return $values;
    }

    private function writeEnv(string $path, array $values): void
    {
        $lines = file($path, FILE_IGNORE_NEW_LINES) ?: [];
        $written = [];

        foreach ($lines as $index => $line) {
            if (!preg_match('/^\s*([A-Z0-9_]+)\s*=/', $line, $matches)) {
                continue;
            }

            $key = $matches[1];
            if (!array_key_exists($key, $values)) {
                continue;
            }

            $lines[$index] = $key . ' = ' . $values[$key];
            $written[$key] = true;
        }

        foreach ($values as $key => $value) {
            if (!isset($written[$key])) {
                $lines[] = $key . ' = ' . $value;
            }
        }

        file_put_contents($path, implode(PHP_EOL, $lines) . PHP_EOL);
    }

    private function connectServer(array $config): PDO
    {
        return new PDO(
            "mysql:host={$config['DB_HOST']};port={$config['DB_PORT']};charset={$config['DB_CHARSET']}",
            $config['DB_USER'],
            $config['DB_PASSWORD'],
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
        );
    }

    private function connectDatabase(array $config): PDO
    {
        return new PDO(
            "mysql:host={$config['DB_HOST']};port={$config['DB_PORT']};dbname={$config['DB_NAME']};charset={$config['DB_CHARSET']}",
            $config['DB_USER'],
            $config['DB_PASSWORD'],
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
        );
    }

    private function ensureDatabase(PDO $pdo, array $config, InputInterface $input, OutputInterface $output): void
    {
        $database = $config['DB_NAME'];
        $exists = $pdo->query("SHOW DATABASES LIKE " . $pdo->quote($database))->fetchColumn();
        if ($exists) {
            return;
        }

        if (!$this->confirm($input, $output, "数据库 {$database} 不存在，是否创建？", true)) {
            throw new PDOException("数据库 {$database} 不存在");
        }

        $quoted = '`' . str_replace('`', '``', $database) . '`';
        $charset = preg_replace('/[^a-zA-Z0-9_]/', '', $config['DB_CHARSET']) ?: 'utf8mb4';
        $collation = preg_replace('/[^a-zA-Z0-9_]/', '', $config['DB_COLLATION']) ?: 'utf8mb4_general_ci';
        $pdo->exec("CREATE DATABASE {$quoted} DEFAULT CHARACTER SET {$charset} COLLATE {$collation}");
        $output->writeln("<info>已创建数据库 {$database}。</info>");
    }

    private function importBaselineIfNeeded(PDO $db, InputInterface $input, OutputInterface $output): void
    {
        $installed = $db->query("SHOW TABLES LIKE 'sa_system_menu'")->fetchColumn();
        if ($installed) {
            $output->writeln('<comment>检测到数据库已包含 sa_system_menu，跳过基线 SQL 导入。</comment>');
            return;
        }

        if (!$this->confirm($input, $output, '是否导入 Database/b8aiadmin.sql 基线数据？', true)) {
            return;
        }

        $sqlFile = $this->databaseFile('b8aiadmin.sql');
        if (!is_file($sqlFile)) {
            throw new \RuntimeException('未找到 Database/b8aiadmin.sql。');
        }

        $output->writeln('<info>开始导入 Database/b8aiadmin.sql...</info>');
        $db->exec((string) file_get_contents($sqlFile));
        $output->writeln('<info>基线 SQL 导入完成。</info>');
    }
}
