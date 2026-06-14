<template>
  <HelpCrudPage
    title="敏感词规则"
    :api="api"
    permission-prefix="help:risk:sensitiveWordRule"
    :fields="fields"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import type { HelpCrudField } from '../../components/helpCrudTypes'
  import api from '../../api/risk/sensitiveWordRule'

  defineOptions({ name: 'HelpSensitiveWordRule' })

  const statusOptions = [
    { label: '启用', value: 1, tagType: 'success' as const },
    { label: '禁用', value: 2, tagType: 'info' as const }
  ]

  const sceneOptions = [
    { label: '社区', value: 'community' },
    { label: '素材', value: 'material' },
    { label: '资料', value: 'profile' },
    { label: '聊天', value: 'chat' },
    { label: '全部', value: 'all' }
  ]

  const matchOptions = [
    { label: '包含', value: 'contains' },
    { label: '完全匹配', value: 'exact' },
    { label: '正则', value: 'regex' }
  ]

  const actionOptions = [
    { label: '进入审核', value: 'review', tagType: 'warning' as const },
    { label: '拒绝发布', value: 'reject', tagType: 'danger' as const },
    { label: '替换文本', value: 'replace', tagType: 'info' as const }
  ]

  const riskOptions = [
    { label: '低', value: 1, tagType: 'info' as const },
    { label: '中', value: 2, tagType: 'warning' as const },
    { label: '高', value: 3, tagType: 'danger' as const }
  ]

  const fields: HelpCrudField[] = [
    { prop: 'id', label: 'ID', table: true, detail: true, width: 80, readonly: true },
    {
      prop: 'scene',
      label: '场景',
      search: true,
      form: true,
      required: true,
      default: 'community',
      options: sceneOptions,
      width: 100
    },
    { prop: 'word', label: '规则内容', search: true, form: true, required: true, minWidth: 180 },
    {
      prop: 'match_type',
      label: '匹配方式',
      form: true,
      required: true,
      default: 'contains',
      options: matchOptions,
      width: 110
    },
    {
      prop: 'action',
      label: '动作',
      search: true,
      form: true,
      required: true,
      default: 'review',
      options: actionOptions,
      width: 110
    },
    { prop: 'replacement', label: '替换文本', form: true, minWidth: 150 },
    {
      prop: 'risk_level',
      label: '风险等级',
      type: 'select',
      search: true,
      form: true,
      required: true,
      default: 1,
      options: riskOptions,
      width: 110
    },
    { prop: 'hit_count', label: '命中次数', type: 'number', form: true, default: 0, width: 100 },
    { prop: 'remark', label: '备注', type: 'textarea', form: true, rows: 3, minWidth: 180 },
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
