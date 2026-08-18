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
        :theme="viewerTheme"
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
  import { useSettingStore } from '@/store/modules/setting'
  import { useFileViewer } from '@/composables/useFileViewer'
  import { getFileViewerPlugins } from './plugins'
  import { resolvePreviewMeta } from './utils'

  defineOptions({ name: 'SaFileViewer' })

  const settingStore = useSettingStore()
  const viewerTheme = computed(() => (settingStore.isDark ? 'dark' : 'light'))
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
        mediaType: item.mediaType,
        fieldProp: item.fieldProp
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
    background: var(--el-bg-color);

    .ofv-root,
    .ofv-root.ofv-theme-light,
    .ofv-root.ofv-theme-dark {
      --ofv-bg: var(--el-bg-color-page);
      --ofv-surface: var(--el-bg-color);
      --ofv-surface-muted: var(--el-fill-color-light);
      --ofv-text: var(--el-text-color-primary);
      --ofv-text-muted: var(--el-text-color-regular);
      --ofv-border: var(--el-border-color-lighter);
      --ofv-button-hover: var(--el-fill-color);
      --ofv-highlight: var(--el-color-warning-light-7);
      --ofv-accent: var(--el-color-primary);
      --ofv-accent-soft: var(--el-color-primary-light-8);
      --ofv-toolbar-bg: var(--el-bg-color);
      height: 100%;
      border-color: var(--el-border-color-lighter);
      background: var(--ofv-bg);
      color: var(--ofv-text);
      font-family: inherit;
    }

    .ofv-host {
      height: 100%;
    }

    .ofv-lrc-mode-button[aria-selected='true'],
    .ofv-theme-dark .ofv-lrc-mode-button[aria-selected='true'] {
      background: var(--el-color-primary-light-9);
      color: var(--el-color-primary);
    }

    .ofv-lrc-mode-button:focus-visible,
    .ofv-code-action:focus-visible {
      outline-color: var(--el-color-primary);
    }

    .ofv-image-stage {
      align-items: center;
      justify-content: center;
    }

    .ofv-image-scrollbox {
      width: 100%;
      height: 100%;
    }

    .ofv-image-content.ofv-media {
      width: 100%;
      height: 100%;
      max-width: 100%;
      max-height: 100%;
      object-fit: contain;
    }
  }
</style>
