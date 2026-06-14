<template>
  <HelpCrudPage
    title="医生患者关系"
    :api="api"
    permission-prefix="help:doctor:patient"
    :fields="fields"
    :actions="actions"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import api from '../../api/doctor/patient'
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
      prop: 'member_id',
      label: '患者会员ID',
      type: 'number',
      form: true,
      search: true,
      required: true,
      width: 110
    },
    {
      prop: 'status',
      label: '状态',
      form: true,
      search: true,
      options: [
        {
          label: '绑定中',
          value: 1,
          tagType: 'success'
        },
        {
          label: '已解绑',
          value: 2,
          tagType: 'info'
        }
      ],
      default: 1,
      width: 100
    },
    {
      prop: 'bind_source',
      label: '绑定来源',
      form: true,
      search: true,
      options: [
        {
          label: '手动',
          value: 'manual'
        },
        {
          label: '系统',
          value: 'system'
        },
        {
          label: '预约',
          value: 'appointment'
        }
      ],
      default: 'manual',
      width: 100
    },
    {
      prop: 'bind_time',
      label: '绑定时间',
      type: 'datetime',
      form: true,
      width: 170
    },
    {
      prop: 'unbind_time',
      label: '解绑时间',
      type: 'datetime',
      form: true,
      width: 170
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
