<template>
  <div class="art-full-height">
    <!-- 搜索面板 -->
    <TableSearch v-model="searchForm" @search="handleSearch" @reset="resetSearchParams" />

    <ElCard class="art-table-card" shadow="never">
      <!-- 表格头部 -->
      <ArtTableHeader v-model:columns="columnChecks" :loading="loading" @refresh="refreshData" />

      <!-- 表格 -->
      <ArtTable
        ref="tableRef"
        rowKey="id"
        :loading="loading"
        :data="data"
        :columns="columns"
        :pagination="pagination"
        @sort-change="handleSortChange"
        @pagination:size-change="handleSizeChange"
        @pagination:current-change="handleCurrentChange"
      >
        <template #change_type="{ row }">
          <ElTag :type="changeTypeTag(row.change_type)">
            {{ changeTypeText(row.change_type) }}
          </ElTag>
        </template>
      </ArtTable>
    </ElCard>
  </div>
</template>

<script setup lang="ts">
  import { useTable } from '@/hooks/core/useTable'
  import api from '../../api/member/points'
  import TableSearch from './modules/table-search.vue'

  type TagType = 'success' | 'warning' | 'info'

  const changeTypeText = (value: string) => {
    const map: Record<string, string> = {
      income: '收入',
      expense: '支出',
      adjust: '调整'
    }
    return map[value] || value || '-'
  }

  const changeTypeTag = (value: string): TagType => {
    if (value === 'income') return 'success'
    if (value === 'expense') return 'warning'
    return 'info'
  }

  // 搜索表单
  const searchForm = ref({
    change_type: undefined,
    source_type: undefined,
    username: undefined,
    create_time: [],
    orderType: 'desc'
  })

  // 搜索处理
  const handleSearch = (params: Record<string, any>) => {
    Object.assign(searchParams, params)
    getData()
  }

  // 表格配置
  const {
    columns,
    columnChecks,
    data,
    loading,
    getData,
    searchParams,
    pagination,
    resetSearchParams,
    handleSortChange,
    handleSizeChange,
    handleCurrentChange,
    refreshData
  } = useTable({
    core: {
      apiFn: api.list,
      apiParams: {
        ...searchForm.value
      },
      columnsFactory: () => [
        { prop: 'id', label: '编号', width: 80 },
        { prop: 'create_time', label: '发生时间', width: 180 },
        { prop: 'username', label: '会员账号', width: 120 },
        {
          prop: 'change_type',
          label: '变动类型',
          width: 120,
          useSlot: true
        },
        { prop: 'source_type', label: '来源类型', width: 150 },
        { prop: 'title', label: '积分标题', minWidth: 180 },
        { prop: 'remark', label: '备注', minWidth: 180 },
        { prop: 'points', label: '积分变动', width: 120 },
        { prop: 'balance_after', label: '变动后积分', width: 120 }
      ]
    }
  })
</script>
