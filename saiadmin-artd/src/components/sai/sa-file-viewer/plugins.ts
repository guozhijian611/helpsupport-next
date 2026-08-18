import type { PreviewPlugin } from '@open-file-viewer/core'

let plugins: PreviewPlugin[] | null = null
let loading: Promise<PreviewPlugin[]> | null = null

export const getFileViewerPlugins = async (): Promise<PreviewPlugin[]> => {
  if (plugins) {
    return plugins
  }
  if (loading) {
    return loading
  }

  loading = (async () => {
    const [{ default: pdfWorkerSrc }, core] = await Promise.all([
      import('pdfjs-dist/build/pdf.worker.mjs?url'),
      import('@open-file-viewer/core')
    ])

    plugins = [
      core.imagePlugin(),
      core.videoPlugin(),
      core.audioPlugin(),
      core.textPlugin(),
      core.pdfPlugin({ workerSrc: pdfWorkerSrc }),
      core.epubPlugin(),
      core.officePlugin(),
      core.archivePlugin(),
      core.emailPlugin(),
      core.fallbackPlugin()
    ]
    return plugins
  })()

  try {
    return await loading
  } finally {
    loading = null
  }
}
