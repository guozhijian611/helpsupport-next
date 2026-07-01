<template>
  <div class="art-card signal-card p-5 mb-5 max-sm:mb-4">
    <div class="art-card-header">
      <div class="title">
        <h4>运营信号</h4>
        <p>管理员每天要扫的增长与风险信号</p>
      </div>
    </div>

    <div class="mt-2 overflow-hidden">
      <ElScrollbar>
        <div
          class="h-17.5 leading-17.5 border-b border-g-300 text-sm overflow-hidden last:border-b-0"
          v-for="(item, index) in list"
          :key="index"
        >
          <span class="text-g-800 font-medium">{{ item.module }}</span>
          <span class="mx-2 text-g-600">{{ item.action }}</span>
          <span class="text-theme">{{ item.target }}</span>
        </div>
      </ElScrollbar>
    </div>
  </div>
</template>

<script setup lang="ts">
  interface DynamicItem {
    module: string
    action: string
    target: string
  }

  const list = reactive<DynamicItem[]>([
    {
      module: '帖子',
      action: '关注',
      target: '浏览高但互动低的内容'
    },
    {
      module: '评论',
      action: '排查',
      target: 'AI 标记和待审核评论'
    },
    {
      module: '举报',
      action: '优先处理',
      target: '帖子和评论举报'
    },
    {
      module: '医生',
      action: '提升',
      target: '审核通过率和预约履约'
    },
    {
      module: '计划',
      action: '观察',
      target: '每日任务反馈质量'
    },
    {
      module: '素材',
      action: '优化',
      target: '教育与娱乐内容供给'
    },
    {
      module: '推送',
      action: '复盘',
      target: '失败率和未读消息'
    },
    {
      module: 'AI',
      action: '对比',
      target: '聊天模式和提示词效果'
    }
  ])
</script>

<style lang="scss" scoped>
  .signal-card {
    min-height: 360px;
  }
</style>
