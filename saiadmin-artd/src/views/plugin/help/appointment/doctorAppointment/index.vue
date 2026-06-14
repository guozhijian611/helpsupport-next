<template>
  <HelpCrudPage
    title="医生预约"
    :api="api"
    permission-prefix="help:appointment:doctorAppointment"
    :fields="fields"
    :actions="actions"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import api from '../../api/appointment/doctorAppointment'
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
      label: '患者会员ID',
      type: 'number',
      form: true,
      search: true,
      required: true,
      width: 110
    },
    {
      prop: 'doctor_id',
      label: '医生会员ID',
      type: 'number',
      form: true,
      search: true,
      required: true,
      width: 110
    },
    {
      prop: 'schedule_id',
      label: '排班ID',
      type: 'number',
      form: true,
      default: 0,
      width: 90
    },
    {
      prop: 'appoint_date',
      label: '预约日期',
      type: 'date',
      form: true,
      search: true,
      required: true,
      width: 120
    },
    {
      prop: 'appoint_time_slot',
      label: '时间段',
      form: true,
      required: true,
      minWidth: 130
    },
    {
      prop: 'price',
      label: '价格',
      type: 'number',
      precision: 2,
      form: true,
      default: 0,
      width: 90
    },
    {
      prop: 'currency',
      label: '币种',
      form: true,
      default: 'USD',
      width: 80
    },
    {
      prop: 'status',
      label: '状态',
      form: false,
      search: true,
      options: [
        {
          label: '待确认',
          value: 0,
          tagType: 'warning'
        },
        {
          label: '已确认',
          value: 1,
          tagType: 'success'
        },
        {
          label: '已完成',
          value: 2,
          tagType: 'success'
        },
        {
          label: '已取消',
          value: 3,
          tagType: 'info'
        },
        {
          label: '已拒绝',
          value: 4,
          tagType: 'danger'
        }
      ],
      default: 0,
      width: 100
    },
    {
      prop: 'meet_type',
      label: '接诊方式',
      form: true,
      search: true,
      options: [
        {
          label: '链接',
          value: 'link'
        },
        {
          label: '地址',
          value: 'address'
        },
        {
          label: '电话',
          value: 'phone'
        }
      ],
      table: false
    },
    {
      prop: 'meet_link',
      label: '接诊地址/链接',
      form: true,
      minWidth: 220
    },
    {
      prop: 'confirm_remark',
      label: '确认备注',
      type: 'textarea',
      form: true,
      table: false
    },
    {
      prop: 'remark',
      label: '预约备注',
      type: 'textarea',
      form: true,
      table: false
    },
    {
      prop: 'cancel_reason',
      label: '取消原因',
      type: 'textarea',
      form: true,
      table: false
    },
    {
      prop: 'cancel_by',
      label: '取消方',
      form: true,
      options: [
        {
          label: '会员',
          value: 'member'
        },
        {
          label: '医生',
          value: 'doctor'
        },
        {
          label: '系统',
          value: 'system'
        }
      ],
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
      label: '确认',
      method: 'confirm',
      type: 'success',
      permission: 'help:appointment:doctorAppointment:confirm',
      visible: (row: Record<string, any>) => Number(row.status) === 0,
      payload: (row: Record<string, any>) => ({
        id: row.id,
        meet_type: row.meet_type || '',
        meet_link: row.meet_link || '',
        confirm_remark: row.confirm_remark || ''
      })
    },
    {
      label: '完成',
      method: 'finish',
      type: 'success',
      permission: 'help:appointment:doctorAppointment:finish',
      visible: (row: Record<string, any>) => Number(row.status) === 1,
      payload: (row: Record<string, any>) => ({ id: row.id })
    },
    {
      label: '取消',
      method: 'cancel',
      type: 'warning',
      permission: 'help:appointment:doctorAppointment:cancel',
      prompt: { field: 'cancel_reason', label: '请输入取消原因', inputType: 'textarea', required: true },
      visible: (row: Record<string, any>) => [0, 1].includes(Number(row.status)),
      payload: (row: Record<string, any>, value?: string) => ({
        id: row.id,
        cancel_reason: value || '',
        cancel_by: 'system'
      })
    },
    {
      label: '拒绝',
      method: 'reject',
      type: 'danger',
      permission: 'help:appointment:doctorAppointment:reject',
      prompt: { field: 'confirm_remark', label: '请输入拒绝原因', inputType: 'textarea', required: true },
      visible: (row: Record<string, any>) => Number(row.status) === 0,
      payload: (row: Record<string, any>, value?: string) => ({
        id: row.id,
        confirm_remark: value || ''
      })
    }
  ]
</script>
