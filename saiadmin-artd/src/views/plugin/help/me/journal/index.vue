<template>
  <HelpCrudPage
    title="会员日记摘要"
    :api="api"
    permission-prefix="help:me:journal"
    :fields="fields"
    drawer-size="820px"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import type { HelpCrudField } from '../../components/helpCrudTypes'
  import api from '../../api/me/journal'

  defineOptions({ name: 'HelpMemberJournal' })

  const yesNoOptions = [
    { label: '是', value: 1, tagType: 'success' as const },
    { label: '否', value: 2, tagType: 'info' as const }
  ]

  const statusOptions = [
    { label: '正常', value: 1, tagType: 'success' as const },
    { label: '隐藏', value: 2, tagType: 'info' as const }
  ]

  const fields: HelpCrudField[] = [
    { prop: 'id', label: 'ID', table: true, detail: true, width: 80, readonly: true },
    {
      prop: 'member_id',
      label: '会员ID',
      type: 'number',
      search: true,
      form: true,
      required: true,
      width: 100
    },
    {
      prop: 'local_id',
      label: '本地ID',
      type: 'number',
      form: true,
      width: 140
    },
    {
      prop: 'entry_date',
      label: '记录日期',
      type: 'date',
      search: true,
      form: true,
      required: true,
      width: 120
    },
    { prop: 'entry_time', label: '记录时间', type: 'time', form: true, table: false },
    {
      prop: 'summary',
      label: '摘要',
      type: 'textarea',
      search: true,
      form: true,
      rows: 3,
      minWidth: 240
    },
    { prop: 'word_count', label: '字数', type: 'number', form: true, default: 0, width: 90 },
    { prop: 'mood_score', label: '心情分', type: 'number', form: true, default: 0, width: 90 },
    {
      prop: 'is_private',
      label: '私密',
      search: true,
      form: true,
      default: 1,
      options: yesNoOptions,
      width: 90
    },
    {
      prop: 'ai_access',
      label: 'AI访问',
      search: true,
      form: true,
      default: 2,
      options: yesNoOptions,
      width: 100
    },
    {
      prop: 'status',
      label: '状态',
      search: true,
      form: true,
      required: true,
      default: 1,
      options: statusOptions,
      width: 100
    },
    { prop: 'remark', label: '备注', type: 'textarea', form: true, table: false, rows: 3 }
  ]
</script>
