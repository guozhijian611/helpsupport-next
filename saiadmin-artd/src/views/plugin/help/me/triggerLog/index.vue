<template>
  <HelpCrudPage
    title="触发因素记录"
    :api="api"
    permission-prefix="help:me:triggerLog"
    :fields="fields"
    drawer-size="820px"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import type { HelpCrudField } from '../../components/helpCrudTypes'
  import api from '../../api/me/triggerLog'

  defineOptions({ name: 'HelpTriggerLog' })

  const triggerTypeOptions = [
    { label: '情绪', value: 'emotion' },
    { label: '地点', value: 'place' },
    { label: '人物', value: 'person' },
    { label: '自定义', value: 'custom' }
  ]

  const statusOptions = [
    { label: '有效', value: 1, tagType: 'success' as const },
    { label: '忽略', value: 2, tagType: 'info' as const }
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
      prop: 'trigger_name',
      label: '触发因素',
      search: true,
      form: true,
      required: true,
      minWidth: 160
    },
    {
      prop: 'trigger_type',
      label: '触发类型',
      search: true,
      form: true,
      required: true,
      default: 'custom',
      options: triggerTypeOptions,
      width: 110
    },
    { prop: 'intensity', label: '强度', type: 'number', form: true, default: 0, width: 90 },
    {
      prop: 'occurred_at',
      label: '发生时间',
      type: 'datetime',
      form: true,
      required: true,
      width: 170
    },
    {
      prop: 'response_action',
      label: '应对动作',
      type: 'textarea',
      form: true,
      rows: 3,
      minWidth: 200
    },
    { prop: 'note', label: '记录说明', type: 'textarea', form: true, rows: 4, table: false },
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
