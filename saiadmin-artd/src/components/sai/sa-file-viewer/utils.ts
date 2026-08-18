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
  'epub',
  'pdf',
  'mp4',
  'mov',
  'mp3'
]

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

export const fileExtension = (url: string) => {
  const cleanUrl = url.split('?')[0].split('#')[0]
  const match = cleanUrl.match(/\.([a-z0-9]+)$/i)
  return match ? match[1].toLowerCase() : ''
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
    return value.map((item) => String(item || '').trim()).filter(Boolean)
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
      return [text]
    }
  }
  return [text]
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
