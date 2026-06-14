<template>
  <HelpCrudPage
    title="内容素材"
    :api="api"
    permission-prefix="help:material:content"
    :fields="fields"
    :actions="actions"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import api from '../../api/material/content'
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
      label: '作者会员ID',
      type: 'number',
      form: true,
      search: true,
      default: 0,
      width: 110
    },
    {
      prop: 'category_id',
      label: '分类ID',
      type: 'number',
      form: true,
      search: true,
      default: 0,
      width: 100
    },
    {
      prop: 'media_type',
      label: '素材类型',
      form: true,
      search: true,
      required: true,
      options: [
        {
          label: '图文',
          value: 'article'
        },
        {
          label: '视频',
          value: 'video'
        },
        {
          label: '音频',
          value: 'audio'
        },
        {
          label: 'PDF',
          value: 'pdf'
        },
        {
          label: 'EPUB',
          value: 'epub'
        },
        {
          label: '链接',
          value: 'link'
        }
      ],
      default: 'article',
      width: 100
    },
    {
      prop: 'material_type',
      label: '内容大类',
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
      default: 'education',
      width: 100
    },
    {
      prop: 'title',
      label: '素材标题',
      form: true,
      search: true,
      required: true,
      minWidth: 180
    },
    {
      prop: 'summary',
      label: '摘要',
      type: 'textarea',
      form: true,
      table: false
    },
    {
      prop: 'cover_url',
      label: '封面图',
      form: true,
      table: false
    },
    {
      prop: 'content_url',
      label: '内容地址',
      form: true,
      minWidth: 220
    },
    {
      prop: 'content_text',
      label: '富文本内容',
      type: 'textarea',
      rows: 8,
      form: true,
      table: false
    },
    {
      prop: 'tags',
      label: '标签JSON',
      type: 'json',
      form: true,
      table: false
    },
    {
      prop: 'duration_seconds',
      label: '时长秒',
      type: 'number',
      form: true,
      default: 0,
      width: 90
    },
    {
      prop: 'is_public',
      label: '公开',
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
      prop: 'is_recommended',
      label: '推荐',
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
      default: 2,
      width: 90
    },
    {
      prop: 'audit_status',
      label: '审核',
      form: true,
      search: true,
      options: [
        {
          label: '待审',
          value: 1,
          tagType: 'warning'
        },
        {
          label: '通过',
          value: 2,
          tagType: 'success'
        },
        {
          label: '拒绝',
          value: 3,
          tagType: 'danger'
        }
      ],
      default: 1,
      width: 100
    },
    {
      prop: 'audit_remark',
      label: '审核备注',
      type: 'textarea',
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
      prop: 'create_time',
      label: '创建时间',
      form: false,
      width: 170
    }
  ]

  const actions: HelpCrudAction[] = [
    {
      label: '通过',
      method: 'audit',
      type: 'success',
      permission: 'help:material:content:audit',
      visible: (row: Record<string, any>) => Number(row.audit_status) !== 2,
      payload: (row: Record<string, any>) => ({ id: row.id, audit_status: 2 })
    },
    {
      label: '拒绝',
      method: 'audit',
      type: 'warning',
      permission: 'help:material:content:audit',
      prompt: { field: 'audit_remark', label: '请输入拒绝原因', inputType: 'textarea' },
      visible: (row: Record<string, any>) => Number(row.audit_status) !== 3,
      payload: (row: Record<string, any>, value?: string) => ({
        id: row.id,
        audit_status: 3,
        audit_remark: value || ''
      })
    }
  ]
</script>
