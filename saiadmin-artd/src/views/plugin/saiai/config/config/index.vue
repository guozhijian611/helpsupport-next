<template>
  <div class="art-full-height">
    <!-- 搜索面板 -->
    <TableSearch v-model="searchForm" @search="handleSearch" @reset="resetSearchParams" />

    <ElAlert
      class="mb-4"
      type="info"
      show-icon
      :closable="false"
      title="App 在线聊天会读取这里已启用的文本模型"
      description="平台类型为 openai、gemini、deepseek、generic 且状态为启用的配置，会出现在 App 四种聊天模式（含 AI 医生）的模型选择器中。realtime 只用于音视频通话。temp_save 在本页每条 AI 配置中填写，App 会按所选模型读取该字符串。"
    />

    <ElCard class="art-table-card" shadow="never">
      <!-- 表格头部 -->
      <ArtTableHeader v-model:columns="columnChecks" :loading="loading" @refresh="refreshData">
        <template #left>
          <ElSpace wrap>
            <ElButton v-permission="'saiai:config:config:save'" @click="showDialog('add')" v-ripple>
              <template #icon>
                <ArtSvgIcon icon="ri:add-fill" />
              </template>
              新增
            </ElButton>
            <ElButton
              v-permission="'saiai:config:config:destroy'"
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
        <template #app_online="{ row }">
          <ElTag :type="isAppOnlineChatModel(row.type) ? 'success' : 'info'">
            {{ isAppOnlineChatModel(row.type) ? '可用' : '不用于文字聊天' }}
          </ElTag>
        </template>
        <!-- 操作列 -->
        <template #operation="{ row }">
          <div class="flex gap-2">
            <SaButton type="success" @click="showViewDialog('view', row)" />
            <SaButton
              v-permission="'saiai:config:config:update'"
              type="secondary"
              @click="showDialog('edit', row)"
            />
            <SaButton
              v-permission="'saiai:config:config:destroy'"
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
  import api from '../../api/config/config'
  import TableSearch from './modules/table-search.vue'
  import EditDialog from './modules/edit-dialog.vue'
  import ViewDialog from './modules/view-dialog.vue'

  // 搜索表单
  const searchForm = ref({
    name: undefined,
    type: undefined
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
        { prop: 'name', label: '配置名称' },
        { prop: 'type', label: '平台类型', saiType: 'dict', saiDict: 'crontab_task_type' },
        { prop: 'model', label: '模型名称', saiType: 'dict', saiDict: 'attachment_type' },
        { prop: 'is_default', label: '是否默认', saiType: 'dict', saiDict: 'yes_or_no' },
        { prop: 'temp_save', label: '临时配置', minWidth: 160 },
        { prop: 'app_online', label: 'App文字聊天', width: 140, useSlot: true },
        { prop: 'status', label: '状态', saiType: 'dict', saiDict: 'data_status' },
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

  const appOnlineChatTypes = ['openai', 'gemini', 'deepseek', 'generic']

  const isAppOnlineChatModel = (type?: string) => {
    return appOnlineChatTypes.includes(String(type || ''))
  }
</script>
