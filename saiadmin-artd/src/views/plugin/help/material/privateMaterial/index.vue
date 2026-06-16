<template>
  <HelpCrudPage
    title="私人素材审核"
    :api="api"
    permission-prefix="help:material:privateMaterial"
    :fields="fields"
    :actions="actions"
    :allow-create="false"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import api from '../../api/material/privateMaterial'
  import type { HelpCrudAction, HelpCrudField } from '../../components/helpCrudTypes'

  const mediaTypeOptions = [
    { label: '图文/文章', value: 'article' },
    { label: '视频（通用）', value: 'video' },
    { label: '音频（通用）', value: 'audio' },
    { label: 'TXT 书籍', value: 'txt' },
    { label: 'EPUB 书籍', value: 'epub' },
    { label: 'PDF 书籍', value: 'pdf' },
    { label: 'MP4 电影', value: 'mp4' },
    { label: 'MOV 电影', value: 'mov' },
    { label: 'MP3 音乐', value: 'mp3' },
    { label: '游戏外链', value: 'link' }
  ]

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
      options: mediaTypeOptions,
      default: 'article',
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
      prop: 'title_i18n',
      label: '多语言标题JSON',
      type: 'json',
      form: true,
      table: false,
      rows: 4,
      placeholder: '{"zh":"中文标题","en":"English title"}'
    },
    {
      prop: 'summary',
      label: '摘要',
      type: 'textarea',
      form: true,
      table: false
    },
    {
      prop: 'summary_i18n',
      label: '多语言摘要JSON',
      type: 'json',
      form: true,
      table: false,
      rows: 4,
      placeholder: '{"zh":"中文摘要","en":"English summary"}'
    },
    {
      prop: 'cover_url',
      label: '封面图',
      form: true,
      table: false
    },
    {
      prop: 'content_url',
      label: '文件地址/游戏外链',
      form: true,
      placeholder: '服务器文件地址或 https 外链',
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
      prop: 'content_text_i18n',
      label: '多语言正文JSON',
      type: 'json',
      rows: 8,
      form: true,
      table: false,
      placeholder: '{"zh":"<p>中文正文</p>","en":"<p>English body</p>"}'
    },
    {
      prop: 'tags',
      label: '标签JSON',
      type: 'json',
      form: true,
      table: false,
      placeholder: '["私人","书籍"]'
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
      prop: 'audit_status',
      label: '审核',
      form: true,
      search: true,
      required: true,
      options: [
        { label: '待审', value: 1, tagType: 'warning' },
        { label: '通过', value: 2, tagType: 'success' },
        { label: '拒绝', value: 3, tagType: 'danger' }
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
      prop: 'audit_by',
      label: '审核人',
      form: false,
      width: 100
    },
    {
      prop: 'audit_time',
      label: '审核时间',
      type: 'datetime',
      form: false,
      width: 170
    },
    {
      prop: 'audit_logs',
      label: '审核日志',
      type: 'json',
      form: false,
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
      required: true,
      options: [
        { label: '启用', value: 1, tagType: 'success' },
        { label: '禁用', value: 2, tagType: 'info' }
      ],
      default: 1,
      width: 90
    },
    {
      prop: 'create_time',
      label: '提交时间',
      form: false,
      width: 170
    }
  ]

  const actions: HelpCrudAction[] = [
    {
      label: '通过',
      method: 'audit',
      type: 'success',
      permission: 'help:material:privateMaterial:audit',
      visible: (row: Record<string, any>) => Number(row.audit_status) !== 2,
      payload: (row: Record<string, any>) => ({ id: row.id, audit_status: 2 })
    },
    {
      label: '拒绝',
      method: 'audit',
      type: 'warning',
      permission: 'help:material:privateMaterial:audit',
      prompt: { field: 'audit_remark', label: '请输入拒绝原因', inputType: 'textarea', required: true },
      visible: (row: Record<string, any>) => Number(row.audit_status) !== 3,
      payload: (row: Record<string, any>, value?: string) => ({
        id: row.id,
        audit_status: 3,
        audit_remark: String(value || '').trim()
      })
    }
  ]
</script>
