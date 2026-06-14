<template>
  <div class="art-full-height">
    <!-- 搜索面板 -->
    <TableSearch v-model="searchForm" @search="handleSearch" @reset="resetSearchParams" />

    <ElCard class="art-table-card" shadow="never">
      <!-- 表格头部 -->
      <ArtTableHeader v-model:columns="columnChecks" :loading="loading" @refresh="refreshData">
        <template #left>
          <ElSpace wrap>
            <ElButton v-permission="'help:localModel:catalog:save'" @click="showDialog('add')" v-ripple>
              <template #icon>
                <ArtSvgIcon icon="ri:add-fill" />
              </template>
              新增
            </ElButton>
            <ElButton
              v-permission="'help:localModel:catalog:destroy'"
              :disabled="selectedRows.length === 0"
              @click="deleteSelectedRows(api.delete, refreshData)"
              v-ripple
            >
              <template #icon>
                <ArtSvgIcon icon="ri:delete-bin-5-line" />
              </template>
              删除
            </ElButton>
          </ElSpace>
        </template>
      </ArtTableHeader>

      <!-- 表格 -->
      <ArtTable
        ref="tableRef"
        rowKey="id"
        :loading="loading"
        :data="data"
        :columns="columns"
        :pagination="pagination"
        @sort-change="handleSortChange"
        @selection-change="handleSelectionChange"
        @pagination:size-change="handleSizeChange"
        @pagination:current-change="handleCurrentChange"
      >
        <!-- 操作列 -->
        <template #operation="{ row }">
          <div class="flex gap-2">
            <SaButton type="success" @click="showViewDialog('view', row)" />
            <SaButton
              v-permission="'help:localModel:catalog:update'"
              type="secondary"
              @click="showDialog('edit', row)"
            />
            <SaButton
              v-permission="'help:localModel:catalog:destroy'"
              type="error"
              @click="deleteRow(row, api.delete, refreshData)"
            />
          </div>
        </template>
      </ArtTable>
    </ElCard>

    <!-- 编辑弹窗 -->
    <EditDialog
      v-model="dialogVisible"
      :dialog-type="dialogType"
      :data="dialogData"
      @success="refreshData"
    />

    <!-- 查看详情 -->
    <ViewDialog v-model="viewDialogVisible" :dialog-type="dialogType" :data="viewDialogData" />
  </div>
</template>

<script setup lang="ts">
  import { useTable } from '@/hooks/core/useTable'
  import { useSaiAdmin } from '@/composables/useSaiAdmin'
  import api from '../../api/localModel/catalog'
  import TableSearch from './modules/table-search.vue'
  import EditDialog from './modules/edit-dialog.vue'
  import ViewDialog from './modules/view-dialog.vue'

  // 搜索表单
  const searchForm = ref({
    name: undefined,
    code: undefined,
    status: undefined,
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
      columnsFactory: () => [
        { type: 'selection' },
        { prop: 'name', label: '模型显示名称', minWidth: 150 },
        { prop: 'code', label: '模型编码', minWidth: 140 },
        { prop: 'provider', label: '模型来源', width: 120 },
        { prop: 'model_family', label: '模型家族', width: 120 },
        { prop: 'quantization', label: '量化类型', width: 110 },
        { prop: 'file_size', label: '文件大小字节', width: 130 },
        { prop: 'download_url', label: '模型下载地址', minWidth: 220 },
        { prop: 'sha256', label: 'SHA256校验值', minWidth: 180 },
        { prop: 'min_memory_mb', label: '推荐最小内存MB', width: 150 },
        { prop: 'context_size', label: '默认上下文长度', width: 140 },
        { prop: 'default_temperature', label: '默认温度', width: 110 },
        { prop: 'default_top_p', label: '默认top_p', width: 110 },
        { prop: 'sort', label: '排序', width: 90 },
        { prop: 'status', label: '状态', saiType: 'dict', saiDict: 'data_status', width: 100 },
        { prop: 'operation', label: '操作', width: 140, fixed: 'right', useSlot: true }
      ]
    }
  })

  // 编辑配置
  const {
    dialogType,
    dialogVisible,
    dialogData,
    showDialog,
    deleteRow,
    deleteSelectedRows,
    handleSelectionChange,
    selectedRows
  } = useSaiAdmin()

  // 查看详情
  const {
    showDialog: showViewDialog,
    dialogVisible: viewDialogVisible,
    dialogData: viewDialogData
  } = useSaiAdmin()

</script>
