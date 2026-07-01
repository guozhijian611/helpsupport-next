<template>
  <HelpCrudPage
    title="荣誉徽章规则"
    :api="api"
    permission-prefix="help:gamification:badgeRule"
    :fields="fields"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import type { HelpCrudField } from '../../components/helpCrudTypes'
  import api from '../../api/gamification/badgeRule'

  defineOptions({ name: 'HelpBadgeRule' })

  const statusOptions = [
    { label: '启用', value: 1, tagType: 'success' as const },
    { label: '禁用', value: 2, tagType: 'info' as const }
  ]

  const triggerOptions = [
    { label: '任务数量', value: 'task_count' },
    { label: '连续打卡', value: 'checkin_streak' },
    { label: '日记数量', value: 'journal_count' },
    { label: '素材学习', value: 'material_learn' },
    { label: '完成预约', value: 'appointment_done' },
    { label: '手动发放', value: 'manual' }
  ]

  const fields: HelpCrudField[] = [
    { prop: 'id', label: 'ID', table: true, detail: true, width: 80, readonly: true },
    { prop: 'name', label: '徽章名称', search: true, form: true, required: true, minWidth: 150 },
    {
      prop: 'code',
      label: '系统标识',
      table: false,
      detail: true,
      readonly: true
    },
    {
      prop: 'description',
      label: '规则说明',
      type: 'textarea',
      form: true,
      rows: 3,
      minWidth: 180,
      placeholder: '说明这个徽章的获得条件，会展示给前台用户'
    },
    { prop: 'icon', label: '徽章图片', type: 'image', form: true, table: true, width: 110 },
    {
      prop: 'trigger_type',
      label: '触发类型',
      search: true,
      form: true,
      required: true,
      options: triggerOptions,
      width: 130
    },
    {
      prop: 'trigger_value',
      label: '触发阈值',
      type: 'number',
      form: true,
      required: true,
      default: 1,
      placeholder: '达到该次数/数量后自动发放；手动发放填 1',
      width: 100
    },
    {
      prop: 'points_reward',
      label: '奖励积分',
      type: 'number',
      form: true,
      default: 0,
      width: 100
    },
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
