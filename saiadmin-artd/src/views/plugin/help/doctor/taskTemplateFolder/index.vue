<template>
  <HelpCrudPage
    title="模板文件夹"
    :api="api"
    permission-prefix="help:doctor:taskTemplateFolder"
    :fields="fields"
    :actions="actions"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import api from '../../api/doctor/taskTemplateFolder'
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
      prop: 'name',
      label: '文件夹名称',
      form: true,
      search: true,
      required: true,
      minWidth: 160
    },
    {
      prop: 'color',
      label: '主题色',
      form: true,
      default: '#5E8FE6',
      width: 100
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
