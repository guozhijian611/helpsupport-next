<template>
  <el-drawer v-model="visible" size="620px" title="机器人形象详情" :footer="false">
    <el-descriptions :column="1" border>
      <el-descriptions-item label="聊天模式">{{
        helpChatModeLabel(data?.chat_mode) || '无'
      }}</el-descriptions-item>
      <el-descriptions-item label="运行模式">{{
        runtimeModeText(data?.runtime_mode)
      }}</el-descriptions-item>
      <el-descriptions-item label="显示名称">{{ data?.display_name || '无' }}</el-descriptions-item>
      <el-descriptions-item label="英文名称">{{
        data?.display_name_en || '无'
      }}</el-descriptions-item>
      <el-descriptions-item label="浅色头像">
        <el-image
          v-if="normalizeImageUrl(data?.avatar)"
          :src="normalizeImageUrl(data?.avatar)"
          :preview-src-list="[normalizeImageUrl(data?.avatar)]"
          :preview-teleported="true"
          fit="cover"
          class="robot-profile-image"
        />
        <span v-else>无</span>
      </el-descriptions-item>
      <el-descriptions-item label="深色头像">
        <el-image
          v-if="normalizeImageUrl(data?.dark_avatar)"
          :src="normalizeImageUrl(data?.dark_avatar)"
          :preview-src-list="[normalizeImageUrl(data?.dark_avatar)]"
          :preview-teleported="true"
          fit="cover"
          class="robot-profile-image"
        />
        <span v-else>无</span>
      </el-descriptions-item>
      <el-descriptions-item label="简介">{{ data?.description || '无' }}</el-descriptions-item>
      <el-descriptions-item label="英文简介">{{
        data?.description_en || '无'
      }}</el-descriptions-item>
      <el-descriptions-item label="排序">{{ data?.sort }}</el-descriptions-item>
      <el-descriptions-item label="状态">
        <el-tag :type="Number(data?.status) === 1 ? 'success' : 'info'">
          {{ Number(data?.status) === 1 ? '启用' : '禁用' }}
        </el-tag>
      </el-descriptions-item>
    </el-descriptions>
  </el-drawer>
</template>

<script setup lang="ts">
  import { helpChatModeLabel } from '../../../components/chatModeOptions'

  interface Props {
    modelValue: boolean
    data?: Record<string, any>
  }

  interface Emits {
    (e: 'update:modelValue', value: boolean): void
  }

  const props = withDefaults(defineProps<Props>(), {
    modelValue: false,
    data: undefined
  })

  const emit = defineEmits<Emits>()

  const visible = computed({
    get: () => props.modelValue,
    set: (value) => emit('update:modelValue', value)
  })

  const runtimeModeText = (mode?: string) => {
    const map: Record<string, string> = {
      online: '在线模式',
      local: '本地模式'
    }
    return mode ? map[mode] || mode : '无'
  }

  const normalizeImageUrl = (url?: string) => {
    if (!url) return ''
    if (/^(https?:)?\/\//.test(url) || url.startsWith('data:') || url.startsWith('blob:')) {
      return url
    }
    const base = import.meta.env.VITE_API_URL || ''
    if (url.startsWith('/') && base && base !== '/') {
      return `${base.replace(/\/$/, '')}${url}`
    }
    return url
  }
</script>

<style scoped>
  .robot-profile-image {
    width: 64px;
    height: 64px;
    border-radius: 50%;
  }
</style>
