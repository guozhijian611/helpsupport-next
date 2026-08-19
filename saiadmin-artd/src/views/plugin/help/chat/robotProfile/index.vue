<template>
  <div class="art-full-height">
    <TableSearch v-model="searchForm" @search="handleSearch" @reset="resetSearchParams" />

    <ElCard class="art-table-card" shadow="never">
      <ArtTableHeader v-model:columns="columnChecks" :loading="loading" @refresh="refreshData">
        <template #left>
          <ElSpace wrap>
            <ElButton
              v-permission="'help:chat:robotProfile:save'"
              @click="showDialog('add')"
              v-ripple
            >
              <template #icon>
                <ArtSvgIcon icon="ri:add-fill" />
              </template>
              新增
            </ElButton>
            <ElButton
              v-permission="'help:chat:robotProfile:destroy'"
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
        <template #avatar="{ row }">
          <ElAvatar
            v-if="normalizeImageUrl(row.avatar)"
            :size="38"
            :src="normalizeImageUrl(row.avatar)"
          />
          <span v-else class="robot-profile-empty">暂无</span>
        </template>
        <template #chat_mode="{ row }">
          <ElTag>{{ helpChatModeLabel(row.chat_mode) }}</ElTag>
        </template>
        <template #runtime_mode="{ row }">
          <ElTag :type="row.runtime_mode === 'local' ? 'warning' : 'success'">
            {{ runtimeModeText(row.runtime_mode) }}
          </ElTag>
        </template>
        <template #status="{ row }">
          <ElTag :type="Number(row.status) === 1 ? 'success' : 'info'">
            {{ Number(row.status) === 1 ? '启用' : '禁用' }}
          </ElTag>
        </template>
        <template #operation="{ row }">
          <div class="flex gap-2">
            <SaButton type="success" @click="showViewDialog('view', row)" />
            <SaButton
              v-permission="'help:chat:robotProfile:update'"
              type="secondary"
              @click="showDialog('edit', row)"
            />
            <SaButton
              v-permission="'help:chat:robotProfile:destroy'"
              type="error"
              @click="deleteRow(row, api.delete, refreshData)"
            />
          </div>
        </template>
      </ArtTable>
    </ElCard>

    <EditDialog
      v-model="dialogVisible"
      :dialog-type="dialogType"
      :data="dialogData"
      @success="refreshData"
    />
    <ViewDialog v-model="viewDialogVisible" :data="viewDialogData" />
  </div>
</template>

<script setup lang="ts">
  import { useTable } from '@/hooks/core/useTable'
  import { useSaiAdmin } from '@/composables/useSaiAdmin'
  import api from '../../api/chat/robotProfile'
  import TableSearch from './modules/table-search.vue'
  import EditDialog from './modules/edit-dialog.vue'
  import ViewDialog from './modules/view-dialog.vue'
  import { helpChatModeLabel } from '../../components/chatModeOptions'

  const searchForm = ref({
    chat_mode: undefined,
    runtime_mode: undefined,
    display_name: undefined,
    status: undefined
  })

  const handleSearch = (params: Record<string, any>) => {
    Object.assign(searchParams, params)
    getData()
  }

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
        { prop: 'avatar', label: '头像', width: 90, useSlot: true },
        { prop: 'chat_mode', label: '聊天模式', width: 110, useSlot: true },
        { prop: 'runtime_mode', label: '运行模式', width: 110, useSlot: true },
        { prop: 'display_name', label: '显示名称', minWidth: 140 },
        { prop: 'display_name_en', label: '英文名称', minWidth: 140 },
        { prop: 'description', label: '简介', minWidth: 220 },
        { prop: 'sort', label: '排序', width: 90 },
        { prop: 'status', label: '状态', width: 90, useSlot: true },
        { prop: 'operation', label: '操作', width: 140, fixed: 'right', useSlot: true }
      ]
    }
  })

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

  const {
    showDialog: showViewDialog,
    dialogVisible: viewDialogVisible,
    dialogData: viewDialogData
  } = useSaiAdmin()

  const runtimeModeText = (mode: string) => {
    const map: Record<string, string> = {
      online: '在线模式',
      local: '本地模式'
    }
    return map[mode] || mode
  }

  const normalizeImageUrl = (url: string) => {
    if (!url) return ''
    if (/^(https?:)?\/\//.test(url) || url.startsWith('data:') || url.startsWith('blob:')) {
      return url
    }
    const base = import.meta.env.VITE_API_URL || ''
    if (url.startsWith('/') && base && base !== '/') {
      return `${base.replace(/\/$/, '')}${url}`
    }
    return url
  }
</script>

<style scoped>
  .robot-profile-empty {
    color: var(--el-text-color-secondary);
    font-size: 12px;
  }
</style>
