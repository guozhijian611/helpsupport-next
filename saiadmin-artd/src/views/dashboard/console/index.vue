<!-- 工作台页面 -->
<template>
  <div class="console-page">
    <CardList />

    <ElRow :gutter="20">
      <ElCol :xs="24" :sm="24" :md="24" :lg="15">
        <SalesOverview />
      </ElCol>
      <ElCol :xs="24" :sm="24" :md="24" :lg="9">
        <ActiveUser />
      </ElCol>
    </ElRow>

    <ElRow :gutter="20">
      <ElCol :span="24">
        <NewUser />
      </ElCol>
    </ElRow>

    <ElRow :gutter="20">
      <ElCol :xs="24" :sm="24" :md="12" :lg="12">
        <Dynamic />
      </ElCol>
      <ElCol :xs="24" :sm="24" :md="12" :lg="12">
        <TodoList />
      </ElCol>
    </ElRow>

    <AboutProject />
  </div>
</template>

<script setup lang="ts">
  import CardList from './modules/card-list.vue'
  import ActiveUser from './modules/active-user.vue'
  import SalesOverview from './modules/sales-overview.vue'
  import AboutProject from './modules/about-project.vue'
  import NewUser from './modules/new-user.vue'
  import Dynamic from './modules/dynamic-stats.vue'
  import TodoList from './modules/todo-list.vue'
  import { useCommon } from '@/hooks/core/useCommon'

  defineOptions({ name: 'Console' })

  const { scrollToTop } = useCommon()
  scrollToTop()
</script>

<style lang="scss" scoped>
  .console-page {
    min-width: 0;
  }
</style>
