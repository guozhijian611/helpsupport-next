<?php

declare(strict_types=1);

namespace plugin\help\app\service;

/**
 * 语音聊天记录的转写文本约定：
 * content 存正文，语音消息的正文就是转写结果；ext.transcript 与之对齐。
 */
final class ChatRecordSpeech
{
    public static function transcriptText(string $contentType, string $content, mixed $ext): string
    {
        if ($contentType !== 'voice') {
            return '';
        }

        $fromExt = trim((string) (self::decodeExt($ext)['transcript'] ?? ''));
        if ($fromExt !== '') {
            return $fromExt;
        }

        return trim($content);
    }

    /**
     * @param array<string, mixed> $ext
     * @return array<string, mixed>
     */
    public static function withTranscript(array $ext, string $contentType, string $content): array
    {
        if ($contentType === 'voice') {
            $ext['transcript'] = trim($content);
        }

        return $ext;
    }

    /**
     * @param array<string, mixed> $row
     * @return array<string, mixed>
     */
    public static function present(array $row): array
    {
        $contentType = trim((string) ($row['content_type'] ?? 'text'));
        $content = (string) ($row['content'] ?? '');
        $ext = self::decodeExt($row['ext'] ?? null);
        $transcript = self::transcriptText($contentType, $content, $ext);
        if ($contentType === 'voice') {
            $ext['transcript'] = $transcript;
            $row['ext'] = $ext === [] ? null : json_encode($ext, JSON_UNESCAPED_UNICODE);
        }
        $row['transcript'] = $transcript;

        return $row;
    }

    /**
     * @return array<string, mixed>
     */
    public static function decodeExt(mixed $value): array
    {
        if (is_array($value)) {
            return $value;
        }
        if (!is_string($value) || trim($value) === '') {
            return [];
        }

        $decoded = json_decode($value, true);

        return is_array($decoded) ? $decoded : [];
    }
}
