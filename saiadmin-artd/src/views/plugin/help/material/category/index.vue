<template>
  <HelpCrudPage
    title="内容分类"
    :api="api"
    permission-prefix="help:material:category"
    :fields="fields"
    :actions="actions"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import api from '../../api/material/category'
  import type { HelpCrudAction, HelpCrudField } from '../../components/helpCrudTypes'

  const categoryTypeOptions = [
    { label: '教育素材', value: 'education' },
    { label: '娱乐', value: 'entertainment' },
    { label: '私人素材', value: 'private' }
  ]

  const fields: HelpCrudField[] = [
    {
      prop: 'id',
      label: 'ID',
      form: false,
      width: 80
    },
    {
      prop: 'parent_id',
      label: '父级分类ID',
      type: 'number',
      form: true,
      search: true,
      default: 0
    },
    {
      prop: 'member_id',
      label: '会员ID',
      type: 'number',
      form: true,
      search: true,
      default: 0,
      placeholder: '0为系统分类，私人用户分类填会员ID',
      width: 100
    },
    {
      prop: 'name',
      label: '分类名称',
      form: true,
      search: true,
      required: true,
      minWidth: 160
    },
    {
      prop: 'name_i18n',
      label: '多语言名称JSON',
      type: 'json',
      form: true,
      table: false,
      rows: 4,
      placeholder: '{"zh":"入门","en":"Getting Started"}'
    },
    {
      prop: 'type',
      label: '分类类型',
      form: true,
      search: true,
      required: true,
      options: categoryTypeOptions,
      default: 'education'
    },
    {
      prop: 'icon',
      label: '图标/标识',
      form: true,
      placeholder: '如 ri:book-2-line',
      minWidth: 180
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
      required: true,
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
