export function normalizeHelpMediaUrl(url: string): string {
  const trimmed = url.trim()
  if (!trimmed) {
    return ''
  }
  if (/^(https?:)?\/\//.test(trimmed) || trimmed.startsWith('data:') || trimmed.startsWith('blob:')) {
    return trimmed
  }
  const base = String(import.meta.env.VITE_API_URL || '').replace(/\/$/, '')
  if (trimmed.startsWith('/') && base) {
    return `${base}${trimmed}`
  }
  return trimmed
}

export function parseHelpMediaUrls(value: unknown): string[] {
  const raw: unknown[] = []
  if (Array.isArray(value)) {
    raw.push(...value)
  } else if (typeof value === 'string' && value.trim() !== '') {
    try {
      const parsed = JSON.parse(value)
      if (Array.isArray(parsed)) {
        raw.push(...parsed)
      } else {
        raw.push(parsed)
      }
    } catch {
      raw.push(value)
    }
  }

  const urls = raw
    .map((item) => normalizeHelpMediaUrl(String(item ?? '')))
    .filter((item) => item !== '')

  return Array.from(new Set(urls))
}

export function chatRecordImageUrls(record: Record<string, any>): string[] {
  if (String(record.content_type || '') !== 'image') {
    return []
  }
  const ext = parseHelpExt(record.ext)
  const urls = parseHelpMediaUrls(record.media_urls)
  if (urls.length > 0) {
    return urls
  }
  return parseHelpMediaUrls(ext.media_urls ?? ext.media_url)
}

function parseHelpExt(value: unknown): Record<string, any> {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return value as Record<string, any>
  }
  if (typeof value !== 'string' || value.trim() === '') {
    return {}
  }
  try {
    const parsed = JSON.parse(value)
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed : {}
  } catch {
    return {}
  }
}
