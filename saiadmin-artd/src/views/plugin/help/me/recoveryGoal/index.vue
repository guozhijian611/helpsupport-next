<template>
  <HelpCrudPage
    title="康复目标记录"
    :api="api"
    permission-prefix="help:me:recoveryGoal"
    :fields="fields"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import type { HelpCrudField } from '../../components/helpCrudTypes'
  import api from '../../api/me/recoveryGoal'

  defineOptions({ name: 'HelpRecoveryGoalLog' })

  const goalTypeOptions = [
    { label: '自定义', value: 'custom' },
    { label: '每周', value: 'weekly' },
    { label: '每月', value: 'monthly' }
  ]

  const statusOptions = [
    { label: '进行中', value: 1, tagType: 'success' as const },
    { label: '已完成', value: 2, tagType: 'primary' as const },
    { label: '已放弃', value: 3, tagType: 'info' as const }
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
      prop: 'goal_text',
      label: '恢复目标',
      type: 'textarea',
      search: true,
      form: true,
      required: true,
      rows: 3,
      minWidth: 220
    },
    {
      prop: 'goal_type',
      label: '目标类型',
      search: true,
      form: true,
      required: true,
      default: 'custom',
      options: goalTypeOptions,
      width: 110
    },
    { prop: 'target_date', label: '目标日期', type: 'date', form: true, width: 120 },
    { prop: 'completed_time', label: '完成时间', type: 'datetime', form: true, table: false },
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
