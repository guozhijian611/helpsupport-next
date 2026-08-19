<template>
  <div v-if="urls.length" class="help-image-preview" :class="{ 'is-detail': detail }">
    <ElImage
      v-for="(url, index) in urls"
      :key="`${url}-${index}`"
      :src="url"
      :preview-src-list="urls"
      :initial-index="index"
      fit="cover"
      preview-teleported
    />
  </div>
  <span v-else-if="emptyText" class="help-image-empty">{{ emptyText }}</span>
</template>

<script setup lang="ts">
  import { parseHelpMediaUrls } from './chatMedia'

  defineOptions({ name: 'HelpImagePreview' })

  const props = withDefaults(
    defineProps<{
      value?: unknown
      detail?: boolean
      emptyText?: string
    }>(),
    {
      value: () => [],
      detail: false,
      emptyText: ''
    }
  )

  const urls = computed(() => parseHelpMediaUrls(props.value))
</script>

<style scoped>
  .help-image-preview {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }

  .help-image-preview :deep(.el-image) {
    width: 56px;
    height: 56px;
    border-radius: 8px;
    overflow: hidden;
    background: var(--el-fill-color-light);
  }

  .help-image-preview.is-detail :deep(.el-image) {
    width: 96px;
    height: 96px;
  }

  .help-image-empty {
    color: var(--el-text-color-secondary);
    font-size: 12px;
  }
</style>
