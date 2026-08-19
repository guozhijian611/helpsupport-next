<template>
  <el-popover placement="bottom-start" :width="460" trigger="click" v-model:visible="visible">
    <template #reference>
      <div class="w-full relative cursor-pointer">
        <el-input :model-value="displayLabel" readonly placeholder="选择首页卡片图标">
          <template #prepend>
            <div class="w-8 flex items-center justify-center">
              <Icon v-if="modelValue" :icon="materialIconifyName(modelValue)" class="text-lg" />
            </div>
          </template>
        </el-input>
      </div>
    </template>
    <div>
      <el-input v-model="keyword" placeholder="搜索图标名称" clearable class="mb-3" />
      <div class="icon-grid">
        <button
          v-for="item in filteredIcons"
          :key="item.name"
          type="button"
          class="icon-item"
          :class="{ active: modelValue === item.name }"
          :title="item.label"
          @click="select(item.name)"
        >
          <Icon :icon="materialIconifyName(item.name)" class="text-2xl" />
          <span>{{ item.label }}</span>
        </button>
      </div>
    </div>
  </el-popover>
</template>

<script setup lang="ts">
  import { Icon } from '@iconify/vue'
  import { materialIconifyName, materialPersonaIcons } from './materialPersonaIcons'

  defineOptions({ name: 'HelpMaterialIconPicker' })

  const modelValue = defineModel<string>({ default: '' })
  const visible = ref(false)
  const keyword = ref('')

  const displayLabel = computed(() => {
    return materialPersonaIcons.find((item) => item.name === modelValue.value)?.label || modelValue.value
  })

  const filteredIcons = computed(() => {
    const text = keyword.value.trim().toLowerCase()
    if (!text) {
      return materialPersonaIcons
    }
    return materialPersonaIcons.filter((item) => {
      return (
        item.name.includes(text) ||
        item.label.toLowerCase().includes(text) ||
        item.keywords.toLowerCase().includes(text)
      )
    })
  })

  const select = (name: string) => {
    modelValue.value = name
    visible.value = false
  }
</script>

<style scoped>
  .icon-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 8px;
    max-height: 280px;
    overflow: auto;
  }

  .icon-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 6px;
    padding: 8px 4px;
    border: 1px solid var(--el-border-color-lighter);
    border-radius: 8px;
    background: var(--el-bg-color);
    color: var(--el-text-color-regular);
    font-size: 12px;
    line-height: 1.2;
    cursor: pointer;
  }

  .icon-item.active,
  .icon-item:hover {
    border-color: var(--el-color-primary);
    color: var(--el-color-primary);
    background: var(--el-color-primary-light-9);
  }
</style>
