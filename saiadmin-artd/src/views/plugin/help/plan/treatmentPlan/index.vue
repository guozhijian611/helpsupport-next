<template>
  <div class="art-full-height">
    <TableSearch v-model="searchForm" @search="handleSearch" @reset="resetSearchParams" />

    <ElCard class="art-table-card" shadow="never">
      <ArtTableHeader v-model:columns="columnChecks" :loading="loading" @refresh="refreshData">
        <template #left>
          <ElSpace wrap>
            <ElButton
              v-permission="'help:plan:treatmentPlan:save'"
              @click="showDialog('add')"
              v-ripple
            >
              <template #icon>
                <ArtSvgIcon icon="ri:add-fill" />
              </template>
              新增
            </ElButton>
            <ElButton
              v-permission="'help:plan:treatmentPlan:destroy'"
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
        <template #member_id="{ row }">
          <HelpRelationText relation="member" :value="row.member_id" />
        </template>
        <template #doctor_id="{ row }">
          <HelpRelationText relation="doctor" :value="row.doctor_id" />
        </template>
        <template #source_type="{ row }">
          <ElTag>{{ sourceTypeText(row.source_type) }}</ElTag>
        </template>
        <template #status="{ row }">
          <ElTag :type="planStatusType(row.status)">
            {{ planStatusText(row.status) }}
          </ElTag>
        </template>
        <template #operation="{ row }">
          <div class="flex gap-2">
            <SaButton type="success" @click="showViewDialog('view', row)" />
            <SaButton
              v-permission="'help:plan:treatmentPlan:update'"
              type="secondary"
              @click="showDialog('edit', row)"
            />
            <SaButton
              v-permission="'help:plan:treatmentPlan:destroy'"
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
    <ViewDialog v-model="viewDialogVisible" :dialog-type="dialogType" :data="viewDialogData" />
  </div>
</template>

<script setup lang="ts">
  import { useTable } from '@/hooks/core/useTable'
  import { useSaiAdmin } from '@/composables/useSaiAdmin'
  import api from '../../api/plan/treatmentPlan'
  import TableSearch from './modules/table-search.vue'
  import EditDialog from './modules/edit-dialog.vue'
  import ViewDialog from './modules/view-dialog.vue'
  import HelpRelationText from '../../components/HelpRelationText.vue'

  const searchForm = ref({
    member_id: undefined,
    doctor_id: undefined,
    title: undefined,
    source_type: undefined,
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
        { prop: 'id', label: 'ID', width: 80 },
        { prop: 'member_id', label: '患者', minWidth: 160, useSlot: true },
        { prop: 'doctor_id', label: '医生', minWidth: 160, useSlot: true },
        { prop: 'title', label: '计划标题', minWidth: 180 },
        { prop: 'start_date', label: '开始日期', width: 120 },
        { prop: 'end_date', label: '结束日期', width: 120 },
        { prop: 'source_type', label: '来源', width: 100, useSlot: true },
        { prop: 'status', label: '状态', width: 100, useSlot: true },
        { prop: 'update_time', label: '更新时间', width: 170 },
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

  const sourceTypeText = (value: string) => {
    const map: Record<string, string> = {
      manual: '人工',
      ai: 'AI',
      template: '模板'
    }
    return map[value] || value || '未知'
  }

  const planStatusText = (value: number) => {
    const map: Record<number, string> = {
      1: '进行中',
      2: '已完成',
      3: '已终止'
    }
    return map[Number(value)] || '未知'
  }

  const planStatusType = (value: number) => {
    const map: Record<number, 'success' | 'info' | 'warning'> = {
      1: 'success',
      2: 'info',
      3: 'warning'
    }
    return map[Number(value)] || 'info'
  }
</script>
