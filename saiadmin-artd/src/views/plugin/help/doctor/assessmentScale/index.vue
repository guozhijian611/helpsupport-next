<template>
  <HelpCrudPage
    title="评估量表"
    :api="api"
    permission-prefix="help:doctor:assessmentScale"
    :fields="fields"
    :actions="actions"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import api from '../../api/doctor/assessmentScale'
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
      prop: 'title',
      label: '量表名称',
      form: true,
      search: true,
      required: true,
      minWidth: 180
    },
    {
      prop: 'stage',
      label: '所属阶段',
      form: true,
      search: true,
      width: 100
    },
    {
      prop: 'description',
      label: '简介',
      type: 'textarea',
      form: true,
      table: false
    },
    {
      prop: 'total_score',
      label: '总分',
      type: 'number',
      form: true,
      default: 0,
      width: 90
    },
    {
      prop: 'questions',
      label: '题目JSON',
      type: 'json',
      rows: 8,
      form: true,
      table: false
    },
    {
      prop: 'scoring_rule',
      label: '计分规则JSON',
      type: 'json',
      rows: 6,
      form: true,
      table: false
    },
    {
      prop: 'status',
      label: '状态',
      form: true,
      search: true,
      options: [
        {
          label: '草稿',
          value: 'draft',
          tagType: 'warning'
        },
        {
          label: '已发布',
          value: 'published',
          tagType: 'success'
        },
        {
          label: '已禁用',
          value: 'disabled',
          tagType: 'info'
        }
      ],
      default: 'draft',
      width: 100
    },
    {
      prop: 'published_at',
      label: '发布时间',
      type: 'datetime',
      form: false,
      width: 170
    },
    {
      prop: 'remark',
      label: '备注',
      type: 'textarea',
      form: true,
      table: false
    }
  ]

  const actions: HelpCrudAction[] = [
    {
      label: '发布',
      method: 'publish',
      type: 'success',
      permission: 'help:doctor:assessmentScale:publish',
      visible: (row: Record<string, any>) => row.status !== 'published',
      payload: (row: Record<string, any>) => ({ id: row.id })
    },
    {
      label: '禁用',
      method: 'disable',
      type: 'warning',
      permission: 'help:doctor:assessmentScale:disable',
      visible: (row: Record<string, any>) => row.status !== 'disabled',
      payload: (row: Record<string, any>) => ({ id: row.id })
    }
  ]
</script>
