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

  const sourceOptions = [
    { label: '后台手动', value: 'manual' },
    { label: '每日任务', value: 'daily_task' },
    { label: '日记', value: 'journal' },
    { label: '素材学习', value: 'material_history' },
    { label: '医生预约', value: 'appointment' },
    { label: '演示数据', value: 'demo_seed' }
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
      prop: 'rule_id',
      label: '规则ID',
      type: 'number',
      form: true,
      default: 0,
      placeholder: '选择规则后自动带出编码、名称、图片和说明',
      width: 90,
      fillFrom: {
        badge_code: 'code',
        badge_name: 'name',
        badge_icon: 'icon',
        rule_description: 'description'
      }
    },
    {
      prop: 'badge_icon',
      label: '徽章图片',
      type: 'image',
      table: true,
      form: true,
      detail: true,
      readonly: true,
      width: 110
    },
    {
      prop: 'badge_code',
      label: '徽章编码',
      search: true,
      form: true,
      editReadonly: true,
      placeholder: '选择规则后自动带出；无规则时请手动填写',
      minWidth: 150
    },
    {
      prop: 'badge_name',
      label: '徽章名称',
      search: true,
      form: true,
      editReadonly: true,
      placeholder: '选择规则后自动带出；无规则时请手动填写',
      minWidth: 150
    },
    {
      prop: 'rule_description',
      label: '规则说明',
      type: 'textarea',
      table: false,
      form: true,
      detail: true,
      readonly: true,
      rows: 3
    },
    {
      prop: 'source_type',
      label: '发放来源',
      search: true,
      form: true,
      options: sourceOptions,
      default: 'manual',
      minWidth: 120
    },
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
