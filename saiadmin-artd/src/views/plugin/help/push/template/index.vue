<template>
  <HelpCrudPage
    title="推送模板"
    :api="api"
    permission-prefix="help:push:template"
    :fields="fields"
    :actions="actions"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import api from '../../api/push/template'
  import type { HelpCrudAction, HelpCrudField } from '../../components/helpCrudTypes'

  const fields: HelpCrudField[] = [
    {
      prop: 'id',
      label: 'ID',
      form: false,
      width: 80
    },
    {
      prop: 'template_code',
      label: '模板编码',
      form: true,
      search: true,
      required: true,
      minWidth: 160
    },
    {
      prop: 'template_name',
      label: '模板名称',
      form: true,
      search: true,
      required: true,
      minWidth: 160
    },
    {
      prop: 'scene',
      label: '场景',
      form: true,
      search: true,
      required: true,
      width: 130
    },
    {
      prop: 'locale',
      label: '语言',
      form: true,
      search: true,
      options: [
        {
          label: 'zh-CN',
          value: 'zh-CN'
        },
        {
          label: 'en-US',
          value: 'en-US'
        }
      ],
      default: 'en-US',
      width: 100
    },
    {
      prop: 'message_type',
      label: '消息类型',
      form: true,
      search: true,
      options: [
        {
          label: '关注',
          value: 1,
          tagType: 'primary'
        },
        {
          label: '回复',
          value: 2,
          tagType: 'success'
        },
        {
          label: '任务',
          value: 3,
          tagType: 'warning'
        },
        {
          label: '预约',
          value: 4,
          tagType: 'success'
        },
        {
          label: '系统',
          value: 5,
          tagType: 'info'
        }
      ],
      default: 5,
      width: 100
    },
    {
      prop: 'title',
      label: '标题模板',
      form: true,
      required: true,
      minWidth: 180
    },
    {
      prop: 'content',
      label: '内容模板',
      type: 'textarea',
      form: true,
      required: true,
      minWidth: 240
    },
    {
      prop: 'route',
      label: '跳转路由',
      form: true,
      minWidth: 180
    },
    {
      prop: 'payload',
      label: '默认载荷JSON',
      type: 'json',
      form: true,
      table: false
    },
    {
      prop: 'is_default',
      label: '默认',
      form: true,
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
      default: 2,
      width: 90
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
