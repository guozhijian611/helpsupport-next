<template>
  <HelpCrudPage
    title="消息管理"
    :api="api"
    permission-prefix="help:message:memberMessage"
    :fields="fields"
    :actions="actions"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import api from '../../api/message/memberMessage'
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
      label: '会员ID',
      type: 'number',
      form: true,
      search: true,
      required: true,
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
      label: '标题',
      form: true,
      search: true,
      required: true,
      minWidth: 180
    },
    {
      prop: 'content',
      label: '内容',
      type: 'textarea',
      form: true,
      required: true,
      minWidth: 240
    },
    {
      prop: 'device_token',
      label: '设备Token',
      form: true,
      table: false
    },
    {
      prop: 'is_pushed',
      label: '已推送',
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
      prop: 'push_status',
      label: '推送状态',
      form: true,
      search: true,
      options: [
        {
          label: '待推送',
          value: 0,
          tagType: 'warning'
        },
        {
          label: '成功',
          value: 1,
          tagType: 'success'
        },
        {
          label: '失败',
          value: 2,
          tagType: 'danger'
        }
      ],
      default: 0,
      width: 100
    },
    {
      prop: 'push_time',
      label: '推送时间',
      type: 'datetime',
      form: true,
      width: 170
    },
    {
      prop: 'is_read',
      label: '已读',
      form: true,
      search: true,
      options: [
        {
          label: '已读',
          value: 1,
          tagType: 'success'
        },
        {
          label: '未读',
          value: 2,
          tagType: 'warning'
        }
      ],
      default: 2,
      width: 90
    },
    {
      prop: 'read_time',
      label: '已读时间',
      type: 'datetime',
      form: true,
      width: 170
    },
    {
      prop: 'biz_type',
      label: '业务类型',
      form: true,
      search: true,
      width: 120
    },
    {
      prop: 'biz_id',
      label: '业务ID',
      type: 'number',
      form: true,
      default: 0,
      width: 100
    },
    {
      prop: 'route',
      label: '跳转路由',
      form: true,
      minWidth: 180
    },
    {
      prop: 'ext',
      label: '扩展JSON',
      type: 'json',
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

  const actions: HelpCrudAction[] = [
    {
      label: '已读',
      method: 'markRead',
      type: 'success',
      permission: 'help:message:memberMessage:markRead',
      visible: (row: Record<string, any>) => Number(row.is_read) !== 1,
      payload: (row: Record<string, any>) => ({ ids: [row.id] })
    },
    {
      label: '推送成功',
      method: 'markPushed',
      type: 'success',
      permission: 'help:message:memberMessage:markPushed',
      visible: (row: Record<string, any>) => Number(row.push_status) !== 1,
      payload: (row: Record<string, any>) => ({ ids: [row.id] })
    },
    {
      label: '推送失败',
      method: 'markFailed',
      type: 'warning',
      permission: 'help:message:memberMessage:markFailed',
      visible: (row: Record<string, any>) => Number(row.push_status) !== 2,
      payload: (row: Record<string, any>) => ({ ids: [row.id] })
    }
  ]
</script>
