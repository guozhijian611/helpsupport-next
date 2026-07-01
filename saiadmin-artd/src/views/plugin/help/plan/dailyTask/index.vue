<template>
  <div class="art-full-height">
    <TableSearch v-model="searchForm" @search="handleSearch" @reset="resetSearchParams" />

    <ElCard class="art-table-card" shadow="never">
      <ArtTableHeader v-model:columns="columnChecks" :loading="loading" @refresh="refreshData">
        <template #left>
          <ElSpace wrap>
            <ElButton v-permission="'help:plan:dailyTask:save'" @click="showDialog('add')" v-ripple>
              <template #icon>
                <ArtSvgIcon icon="ri:add-fill" />
              </template>
              新增
            </ElButton>
            <ElButton
              v-permission="'help:plan:dailyTask:destroy'"
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
        <template #plan_id="{ row }">
          <HelpRelationText relation="treatmentPlan" :value="row.plan_id" />
        </template>
        <template #stage_id="{ row }">
          <HelpRelationText relation="treatmentStage" :value="row.stage_id" />
        </template>
        <template #task_type="{ row }">
          <ElTag>{{ taskTypeText(row.task_type) }}</ElTag>
        </template>
        <template #status="{ row }">
          <ElTag :type="taskStatusType(row.status)">
            {{ taskStatusText(row.status) }}
          </ElTag>
        </template>
        <template #operation="{ row }">
          <div class="flex gap-2">
            <SaButton type="success" @click="showViewDialog('view', row)" />
            <SaButton
              v-permission="'help:plan:dailyTask:update'"
              type="secondary"
              @click="showDialog('edit', row)"
            />
            <SaButton
              v-permission="'help:plan:dailyTask:destroy'"
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
  import api from '../../api/plan/dailyTask'
  import TableSearch from './modules/table-search.vue'
  import EditDialog from './modules/edit-dialog.vue'
  import ViewDialog from './modules/view-dialog.vue'
  import HelpRelationText from '../../components/HelpRelationText.vue'

  const searchForm = ref({
    member_id: undefined,
    plan_id: undefined,
    stage_id: undefined,
    task_date: undefined,
    title: undefined,
    task_type: undefined,
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
        { prop: 'plan_id', label: '计划', minWidth: 170, useSlot: true },
        { prop: 'stage_id', label: '阶段', minWidth: 150, useSlot: true },
        { prop: 'task_date', label: '任务日期', width: 120 },
        { prop: 'title', label: '任务标题', minWidth: 180 },
        { prop: 'task_type', label: '类型', width: 100, useSlot: true },
        { prop: 'points_reward', label: '积分', width: 80 },
        { prop: 'status', label: '状态', width: 100, useSlot: true },
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

  const taskTypeText = (value: string) => {
    const map: Record<string, string> = {
      daily: '日常',
      assessment: '评估',
      material: '素材',
      checkin: '打卡'
    }
    return map[value] || value || '未知'
  }

  const taskStatusText = (value: number) => {
    const map: Record<number, string> = {
      0: '待办',
      1: '完成',
      2: '跳过',
      3: '延期'
    }
    return map[Number(value)] || '未知'
  }

  const taskStatusType = (value: number) => {
    const map: Record<number, 'info' | 'success' | 'warning' | 'danger'> = {
      0: 'info',
      1: 'success',
      2: 'warning',
      3: 'danger'
    }
    return map[Number(value)] || 'info'
  }
</script>
