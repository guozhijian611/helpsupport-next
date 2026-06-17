<template>
  <HelpCrudPage
    title="娱乐素材"
    :api="api"
    permission-prefix="help:material:entertainment"
    :fields="fields"
    :actions="actions"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import api from '../../api/material/entertainment'
  import categoryApi from '../../api/material/category'
  import type { HelpCrudAction, HelpCrudField, HelpCrudOption } from '../../components/helpCrudTypes'

  const mediaTypeOptions = [
    { label: 'TXT 书籍', value: 'txt' },
    { label: 'EPUB 书籍', value: 'epub' },
    { label: 'PDF 书籍', value: 'pdf' },
    { label: 'MP4 电影', value: 'mp4' },
    { label: 'MOV 电影', value: 'mov' },
    { label: 'MP3 音乐', value: 'mp3' },
    { label: '游戏外链', value: 'link' }
  ]

  const categoryOptions = ref<HelpCrudOption[]>([{ label: '未分类', value: 0 }])

  const normalizeCategoryRows = (response: unknown): Record<string, any>[] => {
    if (Array.isArray(response)) {
      return response as Record<string, any>[]
    }
    const data = response as Record<string, any>
    const rows = data?.data || data?.list || data?.records || []
    return Array.isArray(rows) ? rows : []
  }

  const loadCategoryOptions = async () => {
    const rows = normalizeCategoryRows(
      await categoryApi.list({ type: 'entertainment', status: 1, saiType: 'all' })
    )
    categoryOptions.value = [
      { label: '未分类', value: 0 },
      ...rows.map((row) => ({
        label: String(row.name || '未命名分类'),
        value: Number(row.id)
      }))
    ]
  }

  onMounted(loadCategoryOptions)

  const fields = computed<HelpCrudField[]>(() => [
    {
      prop: 'id',
      label: 'ID',
      form: false,
      width: 80
    },
    {
      prop: 'author_label',
      label: '作者',
      form: false,
      search: false,
      minWidth: 120
    },
    {
      prop: 'member_id',
      label: '作者会员ID',
      type: 'number',
      form: true,
      search: true,
      default: 0,
      table: false,
      detail: false,
      placeholder: '0 为管理员上传',
      width: 110
    },
    {
      prop: 'category_name',
      label: '素材分类',
      form: false,
      search: false,
      minWidth: 120
    },
    {
      prop: 'category_id',
      label: '素材分类',
      type: 'number',
      form: true,
      search: true,
      table: false,
      detail: false,
      options: categoryOptions.value,
      placeholder: '娱乐: 书籍/电影/音乐/游戏',
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
      default: 'txt',
      width: 110
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
      prop: 'artist',
      label: '歌手',
      form: true,
      table: false,
      placeholder: '音乐素材填写歌手'
    },
    {
      prop: 'album',
      label: '专辑',
      form: true,
      table: false,
      placeholder: '音乐素材填写专辑'
    },
    {
      prop: 'cover_url',
      label: '封面图',
      type: 'image',
      form: true,
      table: false
    },
    {
      prop: 'content_url',
      label: '文件地址/游戏外链',
      type: 'file',
      form: true,
      accept: '.txt,.epub,.pdf,.mp4,.mov,.mp3',
      acceptHint: 'TXT、EPUB、PDF、MP4、MOV、MP3',
      maxSize: 1024,
      placeholder: '上传书籍/电影/音乐文件后自动填入；游戏填 https 外链',
      minWidth: 220
    },
    {
      prop: 'lyric_url',
      label: '歌词文件',
      type: 'file',
      form: true,
      table: false,
      accept: '.lrc',
      acceptHint: 'LRC',
      maxSize: 5,
      placeholder: '音乐素材上传 .lrc 歌词文件'
    },
    {
      prop: 'content_text',
      label: '正文/歌词备选',
      type: 'textarea',
      rows: 8,
      form: true,
      table: false,
      placeholder: '书籍正文，或音乐未上传 LRC 时的歌词备选'
    },
    {
      prop: 'content_text_i18n',
      label: '多语言正文/歌词备选JSON',
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
      placeholder: '["书籍","放松"]'
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
        { label: '是', value: 1, tagType: 'success' },
        { label: '否', value: 2, tagType: 'info' }
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
        { label: '是', value: 1, tagType: 'success' },
        { label: '否', value: 2, tagType: 'info' }
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
      options: [
        { label: '启用', value: 1, tagType: 'success' },
        { label: '禁用', value: 2, tagType: 'info' }
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
  ])

  const actions: HelpCrudAction[] = [
    {
      label: '通过',
      method: 'audit',
      type: 'success',
      permission: 'help:material:entertainment:audit',
      visible: (row: Record<string, any>) => Number(row.audit_status) !== 2,
      payload: (row: Record<string, any>) => ({ id: row.id, audit_status: 2 })
    },
    {
      label: '拒绝',
      method: 'audit',
      type: 'warning',
      permission: 'help:material:entertainment:audit',
      prompt: {
        field: 'audit_remark',
        label: '请输入拒绝原因',
        inputType: 'textarea',
        required: true
      },
      visible: (row: Record<string, any>) => Number(row.audit_status) !== 3,
      payload: (row: Record<string, any>, value?: string) => ({
        id: row.id,
        audit_status: 3,
        audit_remark: String(value || '').trim()
      })
    }
  ]
</script>
