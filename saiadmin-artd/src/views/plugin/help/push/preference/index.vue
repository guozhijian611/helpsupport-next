<template>
  <HelpCrudPage
    title="推送偏好"
    :api="api"
    permission-prefix="help:push:preference"
    :fields="fields"
    :actions="actions"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import api from '../../api/push/preference'
  import type { HelpCrudAction, HelpCrudField } from '../../components/helpCrudTypes'

  const fields: HelpCrudField[] = [
    {
      prop: 'id',
      label: 'ID',
      form: false,
      width: 80
    },
    {
      prop: 'member_id',
      label: '会员ID',
      type: 'number',
      form: true,
      search: true,
      required: true,
      width: 100
    },
    {
      prop: 'is_push_enabled',
      label: '总开关',
      form: true,
      search: true,
      options: [
        {
          label: '是',
          value: 1,
          tagType: 'success'
        },
        {
          label: '否',
          value: 2,
          tagType: 'info'
        }
      ],
      default: 1,
      width: 90
    },
    {
      prop: 'is_task_reminder_enabled',
      label: '任务提醒',
      form: true,
      search: true,
      options: [
        {
          label: '是',
          value: 1,
          tagType: 'success'
        },
        {
          label: '否',
          value: 2,
          tagType: 'info'
        }
      ],
      default: 1,
      width: 100
    },
    {
      prop: 'is_community_enabled',
      label: '社区互动',
      form: true,
      search: true,
      options: [
        {
          label: '是',
          value: 1,
          tagType: 'success'
        },
        {
          label: '否',
          value: 2,
          tagType: 'info'
        }
      ],
      default: 1,
      width: 100
    },
    {
      prop: 'is_appointment_enabled',
      label: '预约提醒',
      form: true,
      search: true,
      options: [
        {
          label: '是',
          value: 1,
          tagType: 'success'
        },
        {
          label: '否',
          value: 2,
          tagType: 'info'
        }
      ],
      default: 1,
      width: 100
    },
    {
      prop: 'is_audit_notice_enabled',
      label: '审核通知',
      form: true,
      search: true,
      options: [
        {
          label: '是',
          value: 1,
          tagType: 'success'
        },
        {
          label: '否',
          value: 2,
          tagType: 'info'
        }
      ],
      default: 1,
      width: 100
    },
    {
      prop: 'is_local_companion_enabled',
      label: '本地陪伴',
      form: true,
      search: true,
      options: [
        {
          label: '是',
          value: 1,
          tagType: 'success'
        },
        {
          label: '否',
          value: 2,
          tagType: 'info'
        }
      ],
      default: 1,
      width: 100
    },
    {
      prop: 'quiet_start_time',
      label: '免打扰开始',
      type: 'time',
      form: true,
      table: false
    },
    {
      prop: 'quiet_end_time',
      label: '免打扰结束',
      type: 'time',
      form: true,
      table: false
    },
    {
      prop: 'create_time',
      label: '创建时间',
      form: false,
      width: 170
    }
  ]

  const actions: HelpCrudAction[] = [
    {
      label: '启用',
      method: 'enable',
      type: 'success',
      permission: 'help:push:preference:enable',
      visible: (row: Record<string, any>) => Number(row.is_push_enabled) !== 1,
      payload: (row: Record<string, any>) => ({ id: row.id })
    },
    {
      label: '停用',
      method: 'disable',
      type: 'warning',
      permission: 'help:push:preference:disable',
      visible: (row: Record<string, any>) => Number(row.is_push_enabled) !== 2,
      payload: (row: Record<string, any>) => ({ id: row.id })
    }
  ]
</script>
