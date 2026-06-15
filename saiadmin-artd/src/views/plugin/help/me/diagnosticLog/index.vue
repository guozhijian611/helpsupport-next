<template>
  <HelpCrudPage
    title="诊断日志"
    :api="api"
    permission-prefix="help:me:diagnosticLog"
    :fields="fields"
    drawer-size="960px"
    :allow-create="false"
    :allow-edit="false"
    :allow-delete="false"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import type { HelpCrudField } from '../../components/helpCrudTypes'
  import api from '../../api/me/diagnosticLog'

  defineOptions({ name: 'HelpDiagnosticLog' })

  const platformOptions = [
    { label: 'iOS', value: 'ios', tagType: 'primary' as const },
    { label: 'Android', value: 'android', tagType: 'success' as const }
  ]

  const sourceOptions = [
    { label: '手动上传', value: 'manual', tagType: 'primary' as const },
    { label: '崩溃恢复', value: 'auto', tagType: 'warning' as const }
  ]

  const statusOptions = [
    { label: '有效', value: 1, tagType: 'success' as const },
    { label: '忽略', value: 2, tagType: 'info' as const }
  ]

  const fields: HelpCrudField[] = [
    {
      prop: 'member_keyword',
      label: '会员关键词',
      search: true,
      table: false,
      detail: false,
      form: false,
      placeholder: '昵称 / 账号 / 手机 / 邮箱'
    },
    {
      prop: 'id',
      label: 'ID',
      table: true,
      detail: true,
      width: 80,
      readonly: true
    },
    {
      prop: 'member_id',
      label: '会员ID',
      type: 'number',
      search: true,
      table: true,
      detail: true,
      width: 100
    },
    {
      prop: 'member_display',
      label: '会员信息',
      table: true,
      detail: true,
      minWidth: 220
    },
    {
      prop: 'member_username',
      label: '会员账号',
      table: false,
      detail: true
    },
    {
      prop: 'member_nickname',
      label: '会员昵称',
      table: false,
      detail: true
    },
    {
      prop: 'member_mobile',
      label: '手机号',
      table: false,
      detail: true
    },
    {
      prop: 'member_email',
      label: '邮箱',
      table: false,
      detail: true
    },
    {
      prop: 'device_id',
      label: '设备ID',
      search: true,
      table: true,
      detail: true,
      minWidth: 220
    },
    {
      prop: 'platform',
      label: '平台',
      search: true,
      table: true,
      detail: true,
      options: platformOptions,
      width: 100
    },
    {
      prop: 'app_version',
      label: '版本',
      table: true,
      detail: true,
      width: 120
    },
    {
      prop: 'locale',
      label: '语言',
      table: false,
      detail: true
    },
    {
      prop: 'timezone',
      label: '时区',
      table: false,
      detail: true
    },
    {
      prop: 'source',
      label: '来源',
      search: true,
      table: true,
      detail: true,
      options: sourceOptions,
      width: 120
    },
    {
      prop: 'entry_count',
      label: '日志条数',
      table: true,
      detail: true,
      width: 100
    },
    {
      prop: 'first_log_time',
      label: '首条时间',
      type: 'datetime',
      table: false,
      detail: true
    },
    {
      prop: 'last_log_time',
      label: '末条时间',
      type: 'datetime',
      table: true,
      detail: true,
      width: 170
    },
    {
      prop: 'log_summary',
      label: '摘要',
      table: true,
      detail: true,
      minWidth: 260
    },
    {
      prop: 'log_entries',
      label: '完整日志',
      type: 'json',
      table: false,
      detail: true
    },
    {
      prop: 'status',
      label: '状态',
      search: true,
      table: true,
      detail: true,
      options: statusOptions,
      width: 100
    },
    {
      prop: 'remark',
      label: '备注',
      type: 'textarea',
      table: false,
      detail: true
    },
    {
      prop: 'create_time',
      label: '上传时间',
      type: 'datetime',
      table: true,
      detail: true,
      width: 170
    }
  ]
</script>
