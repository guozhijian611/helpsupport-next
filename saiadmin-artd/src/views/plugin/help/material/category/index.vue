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
      prop: 'name',
      label: '分类名称',
      form: true,
      search: true,
      required: true,
      minWidth: 160
    },
    {
      prop: 'type',
      label: '分类类型',
      form: true,
      search: true,
      required: true,
      options: [
        {
          label: '教育',
          value: 'education'
        },
        {
          label: '娱乐',
          value: 'entertainment'
        },
        {
          label: '私人',
          value: 'private'
        }
      ],
      default: 'education'
    },
    {
      prop: 'icon',
      label: '图标',
      form: true,
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
