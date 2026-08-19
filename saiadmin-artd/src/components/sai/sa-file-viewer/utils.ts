const IMAGE_EXTENSIONS = [
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'avif',
  'svg',
  'bmp',
  'tiff',
  'tif',
  'heic',
  'heif'
]

const PREVIEWABLE_MEDIA_TYPES = [
  'image',
  'video',
  'audio',
  'txt',
  'lrc',
  'epub',
  'pdf',
  'mp4',
  'mov',
  'mp3'
]

const MIME_BY_EXT: Record<string, string> = {
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  png: 'image/png',
  gif: 'image/gif',
  webp: 'image/webp',
  avif: 'image/avif',
  svg: 'image/svg+xml',
  bmp: 'image/bmp',
  tiff: 'image/tiff',
  tif: 'image/tiff',
  heic: 'image/heic',
  heif: 'image/heif',
  mp4: 'video/mp4',
  webm: 'video/webm',
  mov: 'video/quicktime',
  m4v: 'video/x-m4v',
  mp3: 'audio/mpeg',
  wav: 'audio/wav',
  ogg: 'audio/ogg',
  aac: 'audio/aac',
  m4a: 'audio/mp4',
  flac: 'audio/flac',
  txt: 'text/plain',
  lrc: 'application/x-lrc',
  md: 'text/markdown',
  json: 'application/json',
  csv: 'text/csv',
  pdf: 'application/pdf',
  epub: 'application/epub+zip',
  doc: 'application/msword',
  docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  xls: 'application/vnd.ms-excel',
  xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ppt: 'application/vnd.ms-powerpoint',
  pptx: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  zip: 'application/zip',
  rar: 'application/vnd.rar',
  '7z': 'application/x-7z-compressed'
}

const EXT_BY_MIME: Record<string, string> = Object.fromEntries(
  Object.entries(MIME_BY_EXT).map(([ext, mime]) => [mime, ext])
)

const MEDIA_TYPE_META: Record<string, { ext: string; mime: string }> = {
  image: { ext: 'jpg', mime: 'image/jpeg' },
  video: { ext: 'mp4', mime: 'video/mp4' },
  audio: { ext: 'mp3', mime: 'audio/mpeg' },
  txt: { ext: 'txt', mime: 'text/plain' },
  lrc: { ext: 'lrc', mime: 'application/x-lrc' },
  epub: { ext: 'epub', mime: 'application/epub+zip' },
  pdf: { ext: 'pdf', mime: 'application/pdf' },
  mp4: { ext: 'mp4', mime: 'video/mp4' },
  mov: { ext: 'mov', mime: 'video/quicktime' },
  mp3: { ext: 'mp3', mime: 'audio/mpeg' }
}

const FIELD_PREVIEW_META: Record<string, { ext: string; mime: string; mediaType: string }> = {
  lyric_url: { ext: 'lrc', mime: 'application/x-lrc', mediaType: 'lrc' },
  cover_url: { ext: 'jpg', mime: 'image/jpeg', mediaType: 'image' },
  image_urls: { ext: 'jpg', mime: 'image/jpeg', mediaType: 'image' },
  badge_icon: { ext: 'png', mime: 'image/png', mediaType: 'image' }
}

const PREVIEWABLE_EXTENSIONS = [
  ...IMAGE_EXTENSIONS,
  'mp4',
  'webm',
  'mov',
  'm4v',
  'avi',
  'mkv',
  'flv',
  'wmv',
  'm3u8',
  'mp3',
  'wav',
  'ogg',
  'aac',
  'm4a',
  'flac',
  'opus',
  'mid',
  'wma',
  'txt',
  'lrc',
  'md',
  'json',
  'yaml',
  'yml',
  'xml',
  'csv',
  'pdf',
  'epub',
  'xps',
  'doc',
  'docx',
  'docm',
  'rtf',
  'odt',
  'xls',
  'xlsx',
  'xlsm',
  'xlsb',
  'ppt',
  'pps',
  'pptx',
  'pptm',
  'odp',
  'wps',
  'zip',
  'rar',
  '7z',
  'tar',
  'gz',
  'tgz',
  'eml',
  'msg'
]

export const fileExtension = (value: string): string => {
  const text = String(value || '').trim()
  if (!text) {
    return ''
  }
  const [pathPart, queryPart = ''] = text.split('?')
  const path = pathPart.split('#')[0]
  const pathMatch = path.match(/\.([a-z0-9]+)$/i)
  if (pathMatch) {
    return pathMatch[1].toLowerCase()
  }

  try {
    const params = new URLSearchParams(queryPart.split('#')[0])
    for (const key of ['filename', 'fileName', 'file', 'name', 'download']) {
      const param = params.get(key)
      if (!param) {
        continue
      }
      const nested = fileExtension(param)
      if (nested) {
        return nested
      }
    }
  } catch {
    return ''
  }
  return ''
}

export const normalizeAssetUrl = (url: string): string => {
  const trimmed = String(url || '').trim()
  if (!trimmed) {
    return ''
  }
  if (
    /^(https?:)?\/\//i.test(trimmed) ||
    trimmed.startsWith('data:') ||
    trimmed.startsWith('blob:')
  ) {
    return trimmed
  }
  const base = String(import.meta.env.VITE_API_URL || '').replace(/\/$/, '')
  if (trimmed.startsWith('/') && base) {
    return `${base}${trimmed}`
  }
  return trimmed
}

export const fileNameFromUrl = (url: string, fallback = '未命名文件') => {
  try {
    const path = url.split('?')[0].split('#')[0]
    const name = decodeURIComponent(path.split('/').pop() || '')
    return name || fallback
  } catch {
    return fallback
  }
}

export const parseUrlList = (value: unknown): string[] => {
  if (Array.isArray(value)) {
    return value.map((item) => normalizeAssetUrl(String(item || ''))).filter(Boolean)
  }
  if (typeof value !== 'string') {
    return []
  }
  const text = value.trim()
  if (!text) {
    return []
  }
  if (text.startsWith('[') && text.endsWith(']')) {
    try {
      return parseUrlList(JSON.parse(text))
    } catch {
      return [normalizeAssetUrl(text)].filter(Boolean)
    }
  }
  return [normalizeAssetUrl(text)].filter(Boolean)
}

export const isImageFile = (url: string, mimeType?: string) => {
  if (mimeType?.startsWith('image/')) {
    return true
  }
  return IMAGE_EXTENSIONS.includes(fileExtension(url))
}

export const isPreviewableFile = (url: string, mimeType?: string, mediaType?: string) => {
  if (mediaType === 'link') {
    return false
  }
  if (mediaType && PREVIEWABLE_MEDIA_TYPES.includes(mediaType)) {
    return true
  }
  if (mimeType && mimeType !== 'application/octet-stream') {
    return true
  }
  const extension = fileExtension(url)
  if (extension) {
    return PREVIEWABLE_EXTENSIONS.includes(extension)
  }
  return /^https?:\/\//i.test(url) === false
}

export const isExternalLink = (url: string, mediaType?: string) => {
  if (mediaType === 'link') {
    return true
  }
  return /^https?:\/\//i.test(url) && !isPreviewableFile(url, undefined, mediaType)
}

const cleanMimeType = (mimeType?: string) => {
  const mime = String(mimeType || '')
    .split(';')[0]
    .trim()
    .toLowerCase()
  if (!mime || mime === 'application/octet-stream' || mime === 'binary/octet-stream') {
    return ''
  }
  return mime
}

const ensureExtension = (fileName: string, extension: string) => {
  const name = fileName.replace(/[\\/]+/g, '_').trim() || '未命名文件'
  if (!extension) {
    return name
  }
  if (fileExtension(name) === extension) {
    return name
  }
  return `${name}.${extension}`
}

export const resolveFieldPreviewKind = (fieldProp?: string) => {
  return FIELD_PREVIEW_META[String(fieldProp || '').trim()]
}

export const resolvePreviewMeta = (input: {
  url?: string
  fileName?: string
  mimeType?: string
  mediaType?: string
  fieldProp?: string
}) => {
  const url = String(input.url || '').trim()
  const field = resolveFieldPreviewKind(input.fieldProp)
  const media =
    MEDIA_TYPE_META[
      String(field?.mediaType || input.mediaType || '')
        .trim()
        .toLowerCase()
    ]
  const urlExt = fileExtension(url)
  const nameExt = fileExtension(input.fileName || '')
  const mime = field ? '' : cleanMimeType(input.mimeType)
  const mimeExt = mime ? EXT_BY_MIME[mime] || '' : ''
  const extension = urlExt || nameExt || field?.ext || mimeExt || media?.ext || ''
  const mimeType =
    (extension ? MIME_BY_EXT[extension] || '' : '') || mime || field?.mime || media?.mime || ''
  const baseName = String(input.fileName || '').trim() || fileNameFromUrl(url)

  return {
    fileName: ensureExtension(baseName, extension),
    mimeType: mimeType || undefined,
    extension,
    mediaType: field?.mediaType || input.mediaType
  }
}
