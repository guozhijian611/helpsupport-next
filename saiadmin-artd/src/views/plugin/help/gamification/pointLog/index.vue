<template>
  <HelpCrudPage
    title="积分流水"
    :api="api"
    permission-prefix="help:gamification:pointLog"
    :fields="fields"
    :allow-edit="false"
    :allow-delete="false"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import type { HelpCrudField } from '../../components/helpCrudTypes'
  import api from '../../api/gamification/pointLog'

  defineOptions({ name: 'HelpPointLog' })

  const changeTypeOptions = [
    { label: '收入', value: 'income', tagType: 'success' as const },
    { label: '支出', value: 'expense', tagType: 'warning' as const },
    { label: '调整', value: 'adjust', tagType: 'info' as const }
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
    { prop: 'points', label: '积分变动', type: 'number', form: true, required: true, width: 100 },
    {
      prop: 'change_type',
      label: '变动类型',
      search: true,
      form: true,
      required: true,
      default: 'income',
      options: changeTypeOptions,
      width: 110
    },
    {
      prop: 'source_type',
      label: '来源类型',
      search: true,
      form: true,
      required: true,
      default: 'manual',
      width: 120
    },
    { prop: 'source_id', label: '来源ID', type: 'number', form: true, default: 0, width: 100 },
    { prop: 'title', label: '标题', search: true, form: true, required: true, minWidth: 180 },
    { prop: 'remark', label: '备注', type: 'textarea', form: true, rows: 3, minWidth: 180 },
    {
      prop: 'balance_after',
      label: '变动后余额',
      type: 'number',
      form: false,
      default: 0,
      width: 120
    },
    { prop: 'create_time', label: '创建时间', table: true, form: false, width: 170 }
  ]
</script>
