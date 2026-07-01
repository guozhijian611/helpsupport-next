<template>
  <div class="art-card p-5 mb-5 max-sm:mb-4">
    <div class="art-card-header">
      <div class="title">
        <h4>运营模块</h4>
        <p>从内容、服务、触达、增长四条线看当前系统</p>
      </div>
      <ElTag type="success" effect="light">运营视角</ElTag>
    </div>
    <ArtTable
      class="w-full"
      :data="tableData"
      style="width: 100%"
      size="large"
      :border="false"
      :stripe="false"
      :header-cell-style="{ background: 'transparent' }"
    >
      <template #default>
        <ElTableColumn label="运营域" prop="module" min-width="150">
          <template #default="scope">
            <div class="flex-c min-w-0">
              <span class="entry-icon" :class="scope.row.type">
                <ArtSvgIcon :icon="scope.row.icon" class="text-lg" />
              </span>
              <span class="ml-2 font-medium truncate">{{ scope.row.module }}</span>
            </div>
          </template>
        </ElTableColumn>
        <ElTableColumn label="观察重点" prop="description" min-width="260" show-overflow-tooltip />
        <ElTableColumn label="状态" prop="status" width="120">
          <template #default="scope">
            <ElTag :type="scope.row.tagType" effect="light">{{ scope.row.status }}</ElTag>
          </template>
        </ElTableColumn>
        <ElTableColumn label="运营成熟度" width="180">
          <template #default="scope">
            <ElProgress
              :percentage="scope.row.percent"
              :color="scope.row.color"
              :stroke-width="4"
            />
          </template>
        </ElTableColumn>
        <ElTableColumn label="操作" width="110" fixed="right">
          <template #default="scope">
            <ElButton type="primary" link @click="goPage(scope.row.path)">进入</ElButton>
          </template>
        </ElTableColumn>
      </template>
    </ArtTable>
  </div>
</template>

<script setup lang="ts">
  import type { TagProps } from 'element-plus'
  import { useRouter } from 'vue-router'

  interface OperationEntry {
    module: string
    description: string
    status: string
    tagType: TagProps['type']
    percent: number
    color: string
    icon: string
    type: 'primary' | 'success' | 'warning' | 'info'
    path: string
  }

  const router = useRouter()

  const tableData = reactive<OperationEntry[]>([
    {
      module: '社区内容',
      description: '帖子热度、评论互动、审核状态和举报联动',
      status: '内容增长',
      tagType: 'success',
      percent: 86,
      color: 'var(--art-primary)',
      icon: 'ri:article-line',
      type: 'primary',
      path: '/helpsupport/community/post'
    },
    {
      module: '社区安全',
      description: '举报处理、评论审核、敏感词规则和内容隐藏',
      status: '风控队列',
      tagType: 'warning',
      percent: 82,
      color: 'var(--art-warning)',
      icon: 'ri:shield-check-line',
      type: 'warning',
      path: '/helpsupport/community/report'
    },
    {
      module: '医生服务',
      description: '医生入驻审核、排班、预约确认和服务完成',
      status: '供给履约',
      tagType: 'primary',
      percent: 79,
      color: 'var(--art-success)',
      icon: 'ri:user-heart-line',
      type: 'success',
      path: '/helpsupport/appointment/doctorAppointment'
    },
    {
      module: '康复计划',
      description: '治疗计划、每日任务、评估结果和患者反馈',
      status: '留存主线',
      tagType: 'info',
      percent: 84,
      color: 'var(--art-info)',
      icon: 'ri:calendar-check-line',
      type: 'info',
      path: '/helpsupport/plan/dailyTask'
    },
    {
      module: 'AI 咨询',
      description: '会话规模、聊天模式、提示词和本地模型配置',
      status: '互动引擎',
      tagType: 'success',
      percent: 81,
      color: 'var(--art-primary)',
      icon: 'ri:chat-smile-3-line',
      type: 'primary',
      path: '/helpsupport/chat/session'
    },
    {
      module: '消息触达',
      description: '会员消息、推送状态、设备偏好和模板效果',
      status: '召回触达',
      tagType: 'warning',
      percent: 74,
      color: 'var(--art-warning)',
      icon: 'ri:notification-3-line',
      type: 'warning',
      path: '/helpsupport/message/memberMessage'
    }
  ])

  const goPage = (path: string) => {
    router.push(path)
  }
</script>

<style lang="scss" scoped>
  .entry-icon {
    flex: none;
    width: 34px;
    height: 34px;
    border-radius: 9px;
    display: flex;
    align-items: center;
    justify-content: center;

    &.primary {
      color: var(--art-primary);
      background: rgba(93, 135, 255, 0.1);
    }

    &.success {
      color: var(--art-success);
      background: rgba(64, 190, 88, 0.1);
    }

    &.warning {
      color: var(--art-warning);
      background: rgba(245, 166, 35, 0.12);
    }

    &.info {
      color: var(--art-info);
      background: rgba(56, 192, 252, 0.1);
    }
  }
</style>
