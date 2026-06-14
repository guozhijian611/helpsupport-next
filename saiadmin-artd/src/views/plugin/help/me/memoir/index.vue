<template>
  <HelpCrudPage
    title="会员回忆录"
    :api="api"
    permission-prefix="help:me:memoir"
    :fields="fields"
    drawer-size="820px"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import type { HelpCrudField } from '../../components/helpCrudTypes'
  import api from '../../api/me/memoir'

  defineOptions({ name: 'HelpMemberMemoir' })

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
      prop: 'source_month',
      label: '来源月份',
      search: true,
      form: true,
      required: true,
      placeholder: 'YYYY-MM',
      width: 110
    },
    { prop: 'title', label: '标题', search: true, form: true, required: true, minWidth: 180 },
    { prop: 'description', label: '描述', type: 'textarea', form: true, rows: 3, minWidth: 220 },
    { prop: 'cover', label: '封面图', form: true, table: false },
    { prop: 'video_url', label: '视频地址', form: true, table: false },
    { prop: 'grant_level_id', label: '等级ID', type: 'number', form: true, default: 0, width: 90 },
    {
      prop: 'grant_level_rank',
      label: '等级序号',
      type: 'number',
      form: true,
      default: 0,
      width: 100
    },
    { prop: 'grant_level_name', label: '等级名称', form: true, table: false },
    { prop: 'journal_count', label: '日记数', type: 'number', form: true, default: 0, width: 90 },
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
