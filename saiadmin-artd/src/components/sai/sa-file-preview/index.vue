<template>
  <span v-if="urls.length === 0">-</span>
  <ElLink v-else-if="isLink" :href="urls[0]" target="_blank" type="primary" :underline="false">
    打开外链
  </ElLink>
  <div v-else-if="showGallery" class="sa-file-preview" :class="{ 'is-detail': detail }">
    <button
      v-for="(url, index) in visibleUrls"
      :key="url + index"
      type="button"
      class="sa-file-preview-thumb"
      @click="openAt(index)"
    >
      <ElImage :src="url" fit="cover" class="sa-file-preview-image" />
    </button>
    <span v-if="!detail && urls.length > visibleUrls.length" class="sa-file-preview-count">
      {{ urls.length }}个
    </span>
  </div>
  <div v-else class="sa-file-preview" :class="{ 'is-detail': detail }">
    <button v-if="isImage" type="button" class="sa-file-preview-thumb" @click="openAt(0)">
      <ElImage :src="urls[0]" fit="cover" class="sa-file-preview-image" />
    </button>
    <ElButton v-else type="primary" link @click="openAt(0)">预览</ElButton>
  </div>
</template>

<script setup lang="ts">
  import { useFileViewer } from '@/composables/useFileViewer'
  import {
    fileNameFromUrl,
    isExternalLink,
    isImageFile,
    parseUrlList
  } from '@/components/sai/sa-file-viewer/utils'

  defineOptions({ name: 'SaFilePreview' })

  const props = withDefaults(
    defineProps<{
      url?: unknown
      fileName?: string
      mimeType?: string
      mediaType?: string
      fieldProp?: string
      detail?: boolean
    }>(),
    {
      detail: false
    }
  )

  const { preview } = useFileViewer()

  const urls = computed(() => parseUrlList(props.url))
  const isLink = computed(() => {
    if (urls.value.length === 0) {
      return false
    }
    return isExternalLink(urls.value[0], props.mediaType)
  })
  const isImage = computed(() => {
    return (
      urls.value.length > 0 &&
      (props.mediaType === 'image' || isImageFile(urls.value[0], props.mimeType))
    )
  })
  const showGallery = computed(() => {
    return props.fieldProp === 'image_urls' || (urls.value.length > 1 && isImage.value)
  })
  const visibleUrls = computed(() => (props.detail ? urls.value : urls.value.slice(0, 3)))

  const openAt = (index: number) => {
    preview(
      urls.value.map((item) => ({
        file: item,
        fileName: props.fileName || fileNameFromUrl(item),
        mimeType: props.mimeType || undefined,
        mediaType: props.mediaType
      })),
      {
        index,
        title: props.fileName || fileNameFromUrl(urls.value[index] || urls.value[0])
      }
    )
  }
</script>

<style scoped lang="scss">
  .sa-file-preview {
    position: relative;
    display: inline-flex;
    max-width: 100%;
    align-items: center;
    gap: 4px;
  }

  .sa-file-preview-thumb {
    padding: 0;
    cursor: pointer;
    border: 0;
    background: transparent;
  }

  .sa-file-preview-image {
    width: 38px;
    height: 38px;
    border: 1px solid var(--el-border-color-lighter);
    border-radius: 6px;
    background: var(--el-fill-color-light);
  }

  .sa-file-preview.is-detail .sa-file-preview-image {
    width: 160px;
    height: 120px;
  }

  .sa-file-preview-count {
    font-size: 12px;
    color: var(--el-text-color-secondary);
    white-space: nowrap;
  }
</style>
