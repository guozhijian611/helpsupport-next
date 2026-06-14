<template>
  <HelpCrudPage
    title="回忆录配置"
    :api="api"
    permission-prefix="help:me:memoirConfig"
    :fields="fields"
    :actions="actions"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import type { HelpCrudField } from '../../components/helpCrudTypes'
  import api from '../../api/me/memoirConfig'

  defineOptions({ name: 'HelpMemoirConfig' })

  const statusOptions = [
    { label: '启用', value: 1, tagType: 'success' as const },
    { label: '禁用', value: 2, tagType: 'info' as const }
  ]

  const cycleOptions = [
    { label: '每周', value: 'weekly' },
    { label: '每月', value: 'monthly' },
    { label: '每季度', value: 'quarterly' }
  ]

  const sourceOptions = [
    { label: '日记', value: 'journal' },
    { label: '任务', value: 'task' },
    { label: '混合', value: 'mixed' }
  ]

  const actions = [
    {
      label: '生成回忆录',
      method: 'generate',
      type: 'success' as const,
      permission: 'help:me:memoirConfig:generate',
      prompt: {
        field: 'member_id',
        label: '会员ID，留空生成所有达标会员',
        placeholder: '默认生成所有达标会员'
      },
      visible: (row: Record<string, any>) => Number(row.status) === 1,
      payload: (row: Record<string, any>, value?: string) => {
        const memberId = String(value || '').trim()

        return {
          id: row.id,
          member_id: memberId === '' ? 0 : Number(memberId)
        }
      }
    }
  ]

  const fields: HelpCrudField[] = [
    { prop: 'id', label: 'ID', table: true, detail: true, width: 80, readonly: true },
    { prop: 'name', label: '配置名称', search: true, form: true, required: true, minWidth: 150 },
    { prop: 'code', label: '配置编码', search: true, form: true, required: true, minWidth: 150 },
    {
      prop: 'generation_cycle',
      label: '生成周期',
      search: true,
      form: true,
      required: true,
      default: 'monthly',
      options: cycleOptions,
      width: 110
    },
    {
      prop: 'source_type',
      label: '来源类型',
      form: true,
      required: true,
      default: 'journal',
      options: sourceOptions,
      width: 110
    },
    {
      prop: 'prompt_template',
      label: '提示词模板',
      type: 'textarea',
      form: true,
      rows: 6,
      minWidth: 220
    },
    {
      prop: 'min_journal_count',
      label: '最少日记数',
      type: 'number',
      form: true,
      default: 3,
      width: 120
    },
    { prop: 'start_day', label: '周期开始日', type: 'number', form: true, default: 1, width: 120 },
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
