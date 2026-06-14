<template>
  <HelpCrudPage
    title="任务模板"
    :api="api"
    permission-prefix="help:doctor:taskTemplate"
    :fields="fields"
    :actions="actions"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import api from '../../api/doctor/taskTemplate'
  import type { HelpCrudAction, HelpCrudField } from '../../components/helpCrudTypes'

  const fields: HelpCrudField[] = [
    {
      prop: 'id',
      label: 'ID',
      form: false,
      width: 160
    },
    {
      prop: 'doctor_id',
      label: '医生会员ID',
      type: 'number',
      form: true,
      search: true,
      default: 0,
      width: 110
    },
    {
      prop: 'folder_id',
      label: '文件夹ID',
      form: true,
      width: 140
    },
    {
      prop: 'stage',
      label: '所属阶段',
      form: true,
      search: true,
      width: 100
    },
    {
      prop: 'title',
      label: '模板名称',
      form: true,
      search: true,
      required: true,
      minWidth: 180
    },
    {
      prop: 'description',
      label: '模板描述',
      type: 'textarea',
      form: true,
      table: false
    },
    {
      prop: 'task_type',
      label: '任务类型',
      form: true,
      search: true,
      options: [
        {
          label: '每日',
          value: 'daily'
        },
        {
          label: '评估',
          value: 'assessment'
        },
        {
          label: '素材',
          value: 'material'
        },
        {
          label: '打卡',
          value: 'checkin'
        }
      ],
      default: 'daily',
      width: 100
    },
    {
      prop: 'priority',
      label: '优先级',
      form: true,
      options: [
        {
          label: '低',
          value: 'low'
        },
        {
          label: '普通',
          value: 'normal'
        },
        {
          label: '高',
          value: 'high'
        }
      ],
      default: 'normal',
      width: 90
    },
    {
      prop: 'start_time',
      label: '开始时间',
      form: true,
      default: '09:00',
      width: 90
    },
    {
      prop: 'end_time',
      label: '结束时间',
      form: true,
      default: '09:30',
      width: 90
    },
    {
      prop: 'frequency',
      label: '频率',
      form: true,
      options: [
        {
          label: '每日',
          value: 'daily'
        },
        {
          label: '每周',
          value: 'weekly'
        },
        {
          label: '一次',
          value: 'once'
        }
      ],
      default: 'daily',
      width: 90
    },
    {
      prop: 'reward_score',
      label: '奖励积分',
      type: 'number',
      form: true,
      default: 0,
      width: 90
    },
    {
      prop: 'color',
      label: '主题色',
      form: true,
      default: '#5E8FE6',
      width: 100
    },
    {
      prop: 'reminder_rule',
      label: '提醒规则JSON',
      type: 'json',
      form: true,
      table: false
    },
    {
      prop: 'attachments',
      label: '附件JSON',
      type: 'json',
      form: true,
      table: false
    },
    {
      prop: 'sort',
      label: '排序',
      type: 'number',
      form: true,
      default: 100,
      width: 90
    },
    {
      prop: 'status',
      label: '状态',
      form: true,
      search: true,
      options: [
        {
          label: '启用',
          value: 1,
          tagType: 'success'
        },
        {
          label: '禁用',
          value: 2,
          tagType: 'info'
        }
      ],
      default: 1,
      width: 90
    },
    {
      prop: 'remark',
      label: '备注',
      type: 'textarea',
      form: true,
      table: false
    }
  ]

  const actions: HelpCrudAction[] = []
</script>
