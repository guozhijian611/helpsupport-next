<template>
  <ElDialog
    v-model="visible"
    :title="title"
    width="90%"
    top="4vh"
    append-to-body
    destroy-on-close
    class="sa-file-viewer-dialog"
    @closed="handleClosed"
  >
    <div v-loading="pluginLoading" class="sa-file-viewer-body">
      <OpenFileViewer
        v-if="visible && plugins.length > 0 && viewerFiles.length > 0"
        :file="singleFile"
        :files="queueFiles"
        :initial-index="initialIndex"
        :file-name="currentFileName"
        :mime-type="currentMimeType"
        width="100%"
        height="100%"
        fit="contain"
        toolbar
        theme="auto"
        locale="zh-CN"
        :plugins="plugins"
      />
    </div>
  </ElDialog>
</template>

<script setup lang="ts">
  import { OpenFileViewer } from '@open-file-viewer/vue'
  import type { PreviewItem, PreviewPlugin } from '@open-file-viewer/core'
  import '@open-file-viewer/core/style.css'
  import { useFileViewer } from '@/composables/useFileViewer'
  import { getFileViewerPlugins } from './plugins'
  import { resolvePreviewMeta } from './utils'

  defineOptions({ name: 'SaFileViewer' })

  const { visible, items, initialIndex, title, handleClosed } = useFileViewer()
  const plugins = shallowRef<PreviewPlugin[]>([])
  const pluginLoading = ref(false)

  const viewerFiles = computed<PreviewItem[]>(() =>
    items.value.map((item) => {
      const url = typeof item.file === 'string' ? item.file : ''
      const meta = resolvePreviewMeta({
        url,
        fileName: item.fileName,
        mimeType: item.mimeType,
        mediaType: item.mediaType
      })
      return {
        file: item.file,
        fileName: meta.fileName,
        mimeType: meta.mimeType
      }
    })
  )

  const currentFile = computed(() => viewerFiles.value[initialIndex.value] || viewerFiles.value[0])
  const currentFileName = computed(() => currentFile.value?.fileName)
  const currentMimeType = computed(() => currentFile.value?.mimeType)
  const singleFile = computed(() =>
    viewerFiles.value.length === 1 ? viewerFiles.value[0]?.file : undefined
  )
  const queueFiles = computed(() => (viewerFiles.value.length > 1 ? viewerFiles.value : undefined))

  const loadPlugins = async () => {
    if (plugins.value.length > 0) {
      return
    }
    pluginLoading.value = true
    try {
      plugins.value = await getFileViewerPlugins()
    } finally {
      pluginLoading.value = false
    }
  }

  watch(visible, (open) => {
    if (open) {
      loadPlugins()
    }
  })
</script>

<style lang="scss">
  .sa-file-viewer-dialog {
    .el-dialog__body {
      padding-top: 8px;
    }
  }

  .sa-file-viewer-body {
    height: calc(86vh - 110px);
    min-height: 480px;
    overflow: hidden;
    border-radius: 8px;
    background: var(--el-fill-color-blank);
  }
</style>
