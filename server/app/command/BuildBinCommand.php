<?php

declare(strict_types=1);

namespace app\command;

use Phar;
use RuntimeException;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Webman\Console\Commands\BuildPharCommand;
use ZipArchive;

#[AsCommand('build:bin', '构建 Webman 独立二进制文件')]
final class BuildBinCommand extends BuildPharCommand
{
    private string $binFileName;

    public function __construct()
    {
        parent::__construct();
        $this->binFileName = (string)config('plugin.webman.console.app.bin_filename', 'server');
    }

    protected function configure(): void
    {
        $this->addArgument('version', InputArgument::OPTIONAL, 'PHP 版本');
        $this->addOption('name', null, InputOption::VALUE_REQUIRED, '输出文件名，不能包含目录分隔符');
        $this->addOption('keep-intermediate', null, InputOption::VALUE_NONE, '保留 webman.phar 与 php micro.sfx 中间文件');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $this->checkEnv();

        $name = $input->getOption('name');
        if (is_string($name) && $name !== '') {
            $this->binFileName = $this->normalizeBinFileName($name);
        } else {
            $this->binFileName = $this->normalizeBinFileName($this->binFileName);
        }

        $output->writeln($this->msg('phar_packing'));

        $version = $input->getArgument('version');
        if (!$version) {
            $version = (float)PHP_VERSION;
        }
        $version = max((float)$version, 8.1);

        $supportZip = class_exists(ZipArchive::class);
        $sfxFileName = "php$version.micro.sfx";
        $microZipFileName = $supportZip ? "$sfxFileName.zip" : $sfxFileName;
        $customIni = (string)config('plugin.webman.console.app.custom_ini', '');
        $runtimeCacheDir = $this->getRuntimeCacheDir();
        $this->ensureDirectory($runtimeCacheDir);

        $binFile = $this->buildDir . DIRECTORY_SEPARATOR . $this->binFileName;
        $pharFile = $this->buildDir . DIRECTORY_SEPARATOR . $this->getPharFileName();
        $zipFile = $runtimeCacheDir . DIRECTORY_SEPARATOR . $microZipFileName;
        $sfxFile = $runtimeCacheDir . DIRECTORY_SEPARATOR . $sfxFileName;
        $customIniHeaderFile = $this->buildDir . DIRECTORY_SEPARATOR . 'custominiheader.bin';

        $command = new BuildPharCommand();
        $command->execute($input, $output);
        $this->patchWorkermanProcessCheck($pharFile);

        if (!is_file($sfxFile) && !is_file($zipFile)) {
            $domain = 'download.workerman.net';
            $output->writeln($this->msg('downloading_php', ['{version}' => (string)$version]));
            if (extension_loaded('openssl')) {
                $context = stream_context_create([
                    'ssl' => [
                        'verify_peer' => false,
                        'verify_peer_name' => false,
                    ],
                ]);
                $client = stream_socket_client("ssl://$domain:443", $context);
            } else {
                $client = stream_socket_client("tcp://$domain:80");
            }
            if (!$client) {
                $output->writeln($this->msg('download_stream_failed'));
                return self::FAILURE;
            }

            fwrite($client, "GET /php/$microZipFileName HTTP/1.1\r\nAccept: text/html\r\nHost: $domain\r\nUser-Agent: webman/console\r\n\r\n");
            $bodyLength = 0;
            $bodyBuffer = '';
            $lastPercent = 0;
            while (true) {
                $buffer = fread($client, 65535);
                if ($buffer !== false) {
                    $bodyBuffer .= $buffer;
                    if (!$bodyLength && $pos = strpos($bodyBuffer, "\r\n\r\n")) {
                        if (!preg_match('/Content-Length: (\d+)\r\n/', $bodyBuffer, $match)) {
                            $output->writeln($this->msg('download_failed', ['{message}' => "php{$version}.micro.sfx.zip: missing Content-Length"]));
                            return self::FAILURE;
                        }
                        $firstLine = substr($bodyBuffer, 9, strpos($bodyBuffer, "\r\n") - 9);
                        if (!preg_match('/200 /', $bodyBuffer)) {
                            $output->writeln($this->msg('download_failed', ['{message}' => "php{$version}.micro.sfx.zip: {$firstLine}"]));
                            return self::FAILURE;
                        }
                        $bodyLength = (int)$match[1];
                        $bodyBuffer = substr($bodyBuffer, $pos + 4);
                    }
                }
                $receiveLength = strlen($bodyBuffer);
                $percent = (int)ceil($receiveLength * 100 / $bodyLength);
                if ($percent !== $lastPercent) {
                    echo '[' . str_pad('', $percent, '=') . '>' . str_pad('', 100 - $percent) . "$percent%]";
                    echo $percent < 100 ? "\r" : "\n";
                }
                $lastPercent = $percent;
                if ($bodyLength && $receiveLength >= $bodyLength) {
                    file_put_contents($zipFile, $bodyBuffer);
                    break;
                }
                if ($buffer === false || !is_resource($client) || feof($client)) {
                    $output->writeln($this->msg('download_failed', ['{message}' => "PHP{$version}"]));
                    return self::FAILURE;
                }
            }
        } else {
            $output->writeln($this->msg('use_php', ['{version}' => (string)$version]));
        }

        if (!is_file($sfxFile) && $supportZip) {
            $zip = new ZipArchive();
            $result = $zip->open($zipFile, ZipArchive::CHECKCONS);
            if ($result !== true) {
                unlink($zipFile);
                throw new RuntimeException("PHP{$version} micro.sfx 缓存压缩包损坏，请重新执行构建。");
            }
            $zip->extractTo($runtimeCacheDir);
            $zip->close();
        }

        file_put_contents($binFile, file_get_contents($sfxFile));
        if ($customIni !== '') {
            if (file_exists($customIniHeaderFile)) {
                unlink($customIniHeaderFile);
            }
            $handle = fopen($customIniHeaderFile, 'wb');
            fwrite($handle, "\xfd\xf6\x69\xe6");
            fwrite($handle, pack('N', strlen($customIni)));
            fwrite($handle, $customIni);
            fclose($handle);
            file_put_contents($binFile, file_get_contents($customIniHeaderFile), FILE_APPEND);
            unlink($customIniHeaderFile);
        }
        file_put_contents($binFile, file_get_contents($pharFile), FILE_APPEND);
        chmod($binFile, 0755);

        if (!$input->getOption('keep-intermediate') && config('plugin.webman.console.app.cleanup_intermediate_files', true)) {
            $this->cleanupIntermediateFiles([$pharFile]);
        }

        $output->writeln($this->msg('saved_bin', ['{name}' => $this->binFileName, '{path}' => $binFile]));

        return self::SUCCESS;
    }

    private function normalizeBinFileName(string $name): string
    {
        $name = trim($name);
        if ($name === '' || $name === '.' || $name === '..' || basename($name) !== $name) {
            throw new RuntimeException('输出文件名不能为空，且不能包含目录分隔符。');
        }

        return $name;
    }

    private function getRuntimeCacheDir(): string
    {
        $default = base_path('runtime/build-bin-cache');
        $dir = trim((string)config('plugin.webman.console.app.bin_runtime_cache_dir', $default));
        if ($dir === '') {
            return $default;
        }

        if (!$this->isRuntimeCacheAbsolutePath($dir)) {
            $dir = base_path($dir);
        }

        return rtrim($dir, DIRECTORY_SEPARATOR);
    }

    private function isRuntimeCacheAbsolutePath(string $path): bool
    {
        return str_starts_with($path, DIRECTORY_SEPARATOR)
            || (bool)preg_match('#^[A-Za-z]:[\\\\/]#', $path);
    }

    private function ensureDirectory(string $dir): void
    {
        if (is_dir($dir)) {
            return;
        }

        if (!mkdir($dir, 0777, true) && !is_dir($dir)) {
            throw new RuntimeException("无法创建 PHP micro.sfx 缓存目录：{$dir}");
        }
    }

    private function patchWorkermanProcessCheck(string $pharFile): void
    {
        $path = 'vendor/workerman/workerman/src/Worker.php';
        $phar = new Phar($pharFile);
        $contents = $phar[$path]->getContent();

        if (str_contains($contents, 'basename(\Phar::running(false))')) {
            return;
        }

        $search = "        return str_contains(\$content, 'WorkerMan') || str_contains(\$content, 'php');";
        $replace = <<<'PHP'
        if (str_contains($content, 'WorkerMan') || str_contains($content, 'php')) {
            return true;
        }

        return class_exists(\Phar::class, false)
            && \Phar::running(false)
            && str_contains($content, basename(\Phar::running(false)));
PHP;

        if (!str_contains($contents, $search)) {
            throw new RuntimeException('未找到 Workerman 进程识别逻辑，无法保证任意二进制文件名的 status/stop 可用。');
        }

        $phar->startBuffering();
        $phar->addFromString($path, str_replace($search, $replace, $contents));
        $phar->stopBuffering();
    }

    /**
     * @param string[] $files
     */
    private function cleanupIntermediateFiles(array $files): void
    {
        foreach ($files as $file) {
            if (is_file($file)) {
                unlink($file);
            }
        }
    }
}
