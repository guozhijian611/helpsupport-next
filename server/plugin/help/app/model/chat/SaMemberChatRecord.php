<?php

namespace plugin\help\app\model\chat;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 会员聊天记录模型
 */
class SaMemberChatRecord extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_member_chat_record';

    protected $append = ['transcript', 'media_urls'];

    public function getTranscriptAttr($value, $data): string
    {
        $contentType = (string) ($data['content_type'] ?? 'text');
        if ($contentType !== 'voice') {
            return '';
        }
        $ext = $this->decodeExt($data['ext'] ?? null);
        $transcript = trim((string) (($ext['transcript'] ?? '') ?: ''));

        return $transcript !== '' ? $transcript : trim((string) ($data['content'] ?? ''));
    }

    /**
     * @return list<string>
     */
    public function getMediaUrlsAttr($value, $data): array
    {
        if ((string) ($data['content_type'] ?? 'text') !== 'image') {
            return [];
        }

        $ext = $this->decodeExt($data['ext'] ?? null);
        $urls = [];
        $candidates = $ext['media_urls'] ?? [];
        if (!is_array($candidates)) {
            $candidates = $candidates === '' || $candidates === null ? [] : [$candidates];
        }
        foreach ($candidates as $url) {
            $url = trim((string) $url);
            if ($url !== '') {
                $urls[] = $url;
            }
        }
        $single = trim((string) ($ext['media_url'] ?? ''));
        if ($urls === [] && $single !== '') {
            $urls[] = $single;
        }

        return array_values(array_unique($urls));
    }

    /**
     * @return array<string, mixed>
     */
    private function decodeExt(mixed $ext): array
    {
        if (is_array($ext)) {
            return $ext;
        }
        if (!is_string($ext) || $ext === '') {
            return [];
        }
        $decoded = json_decode($ext, true);

        return is_array($decoded) ? $decoded : [];
    }

    public function searchSessionIdAttr($query, $value): void
    {
        $query->where('session_id', (int) $value);
    }

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchChatModeAttr($query, $value): void
    {
        $query->where('chat_mode', (string) $value);
    }

    public function searchRoleAttr($query, $value): void
    {
        $query->where('role', (string) $value);
    }

    public function searchContentAttr($query, $value): void
    {
        $query->where('content', 'like', '%' . $value . '%');
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
