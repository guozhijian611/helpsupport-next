<template>
  <HelpCrudPage
    title="医生排班"
    :api="api"
    permission-prefix="help:appointment:doctorSchedule"
    :fields="fields"
    :actions="actions"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import api from '../../api/appointment/doctorSchedule'
  import type { HelpCrudAction, HelpCrudField } from '../../components/helpCrudTypes'

  const fields: HelpCrudField[] = [
    {
      prop: 'id',
      label: 'ID',
      form: false,
      width: 80
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
      prop: 'schedule_date',
      label: '排班日期',
      type: 'date',
      form: true,
      search: true,
      required: true,
      width: 120
    },
    {
      prop: 'time_slot',
      label: '时间段',
      form: true,
      required: true,
      minWidth: 130
    },
    {
      prop: 'start_time',
      label: '开始时间',
      type: 'time',
      form: true,
      table: false
    },
    {
      prop: 'end_time',
      label: '结束时间',
      type: 'time',
      form: true,
      table: false
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
      default: 'link',
      width: 100
    },
    {
      prop: 'meet_link',
      label: '接诊地址/链接',
      form: true,
      minWidth: 220
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
      prop: 'capacity',
      label: '容量',
      type: 'number',
      form: true,
      default: 1,
      width: 80
    },
    {
      prop: 'booked_count',
      label: '已预约',
      type: 'number',
      form: true,
      default: 0,
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
    },
    {
      prop: 'create_time',
      label: '创建时间',
      form: false,
      width: 170
    }
  ]

  const actions: HelpCrudAction[] = []
</script>
