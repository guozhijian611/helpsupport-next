<template>
  <HelpCrudPage
    title="社区标签"
    :api="api"
    permission-prefix="help:community:tag"
    :fields="fields"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import type { HelpCrudField } from '../../components/helpCrudTypes'
  import api from '../../api/community/tag'

  defineOptions({ name: 'HelpCommunityTag' })

  const statusOptions = [
    { label: '启用', value: 1, tagType: 'success' as const },
    { label: '禁用', value: 2, tagType: 'info' as const }
  ]

  const fields: HelpCrudField[] = [
    { prop: 'id', label: 'ID', table: true, detail: true, width: 80, readonly: true },
    {
      prop: 'tag_name',
      label: '标签名称',
      search: true,
      form: true,
      required: true,
      minWidth: 150
    },
    { prop: 'tag_name_i18n', label: '多语言标签', type: 'json', form: true, table: false, rows: 4 },
    { prop: 'color', label: '颜色', form: true, default: '#409EFF', width: 110 },
    { prop: 'sort', label: '排序', type: 'number', form: true, default: 100, width: 90 },
    {
      prop: 'status',
      label: '状态',
      search: true,
      form: true,
      required: true,
      default: 1,
      options: statusOptions,
      width: 100
    }
  ]
</script>
