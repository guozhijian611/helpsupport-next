<template>
  <HelpCrudPage
    title="会员徽章"
    :api="api"
    permission-prefix="help:gamification:badge"
    :fields="fields"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import type { HelpCrudField } from '../../components/helpCrudTypes'
  import api from '../../api/gamification/badge'

  defineOptions({ name: 'HelpMemberBadge' })

  const statusOptions = [
    { label: '有效', value: 1, tagType: 'success' as const },
    { label: '撤销', value: 2, tagType: 'info' as const }
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
    { prop: 'rule_id', label: '规则ID', type: 'number', form: true, default: 0, width: 90 },
    {
      prop: 'badge_code',
      label: '徽章编码',
      search: true,
      form: true,
      required: true,
      minWidth: 150
    },
    {
      prop: 'badge_name',
      label: '徽章名称',
      search: true,
      form: true,
      required: true,
      minWidth: 150
    },
    { prop: 'source_type', label: '来源类型', search: true, form: true, minWidth: 120 },
    { prop: 'source_id', label: '来源ID', type: 'number', form: true, default: 0, width: 90 },
    { prop: 'award_time', label: '获得时间', type: 'datetime', form: true, width: 170 },
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
