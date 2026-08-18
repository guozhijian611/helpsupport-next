import { ref } from 'vue'
import { resolvePreviewMeta } from '@/components/sai/sa-file-viewer/utils'

export interface FileViewerItem {
  file: string | File | Blob
  fileName?: string
  mimeType?: string
  mediaType?: string
  fieldProp?: string
}

export interface FileViewerOptions {
  fileName?: string
  mimeType?: string
  mediaType?: string
  fieldProp?: string
  title?: string
  index?: number
}

type FileViewerInput = string | File | Blob | FileViewerItem

const visible = ref(false)
const items = ref<FileViewerItem[]>([])
const initialIndex = ref(0)
const title = ref('文件预览')

const toItem = (input: FileViewerInput, options?: FileViewerOptions): FileViewerItem => {
  const raw =
    typeof input === 'string' || input instanceof File || input instanceof Blob
      ? {
          file: input,
          fileName: options?.fileName || (input instanceof File ? input.name : undefined),
          mimeType: options?.mimeType || (input instanceof File ? input.type : undefined),
          mediaType: options?.mediaType,
          fieldProp: options?.fieldProp
        }
      : {
          file: input.file,
          fileName: input.fileName || options?.fileName,
          mimeType: input.mimeType || options?.mimeType,
          mediaType: input.mediaType || options?.mediaType,
          fieldProp: input.fieldProp || options?.fieldProp
        }

  const url = typeof raw.file === 'string' ? raw.file : ''
  const meta = resolvePreviewMeta({
    url,
    fileName: raw.fileName || (raw.file instanceof File ? raw.file.name : undefined),
    mimeType: raw.mimeType,
    mediaType: raw.mediaType,
    fieldProp: raw.fieldProp
  })

  return {
    file: raw.file,
    fileName: meta.fileName,
    mimeType: meta.mimeType,
    mediaType: meta.mediaType,
    fieldProp: raw.fieldProp
  }
}

export function useFileViewer() {
  const preview = (file: FileViewerInput | FileViewerInput[], options?: FileViewerOptions) => {
    const list = Array.isArray(file) ? file : [file]
    const nextItems = list
      .map((item) => toItem(item, options))
      .filter((item) => {
        if (typeof item.file === 'string') {
          return item.file.trim().length > 0
        }
        return Boolean(item.file)
      })

    if (nextItems.length === 0) {
      return
    }

    items.value = nextItems
    initialIndex.value = Math.min(Math.max(options?.index || 0, 0), nextItems.length - 1)
    title.value = options?.title || nextItems[0]?.fileName || '文件预览'
    visible.value = true
  }

  const close = () => {
    visible.value = false
  }

  const handleClosed = () => {
    items.value = []
    initialIndex.value = 0
    title.value = '文件预览'
  }

  return {
    visible,
    items,
    initialIndex,
    title,
    preview,
    close,
    handleClosed
  }
}
