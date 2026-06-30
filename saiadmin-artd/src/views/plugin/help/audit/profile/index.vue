<template>
  <div class="art-full-height">
    <!-- 搜索面板 -->
    <TableSearch v-model="searchForm" @search="handleSearch" @reset="resetSearchParams" />

    <ElCard class="art-table-card" shadow="never">
      <!-- 表格头部 -->
      <ArtTableHeader v-model:columns="columnChecks" :loading="loading" @refresh="refreshData">
        <template #left>
          <ElSpace wrap>
            <ElButton v-permission="'help:audit:profile:save'" @click="showDialog('add')" v-ripple>
              <template #icon>
                <ArtSvgIcon icon="ri:add-fill" />
              </template>
              新增
            </ElButton>
            <ElButton
              v-permission="'help:audit:profile:destroy'"
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
        <template #member_display="{ row }">
          <div class="profile-member">
            <ElAvatar
              v-if="normalizeImageUrl(row.member_avatar)"
              :size="28"
              :src="normalizeImageUrl(row.member_avatar)"
            />
            <div>
              <div>{{ row.member_name || `会员 #${row.member_id}` }}</div>
              <div class="profile-member__meta">#{{ row.member_id }}</div>
            </div>
          </div>
        </template>
        <template #certification_image_urls="{ row }">
          <ElSpace v-if="imageUrls(row).length" :size="6">
            <ElImage
              v-for="image in imageUrls(row).slice(0, 3)"
              :key="image"
              :src="image"
              :preview-src-list="imageUrls(row)"
              :initial-index="imageUrls(row).indexOf(image)"
              :preview-teleported="true"
              fit="cover"
              class="profile-cert-image"
            />
          </ElSpace>
          <span v-else class="profile-empty">暂无</span>
        </template>
        <template #audit_status="{ row }">
          <ElTag :type="auditStatusType(row.audit_status)">
            {{ auditStatusText(row.audit_status) }}
          </ElTag>
        </template>
        <template #status="{ row }">
          <ElTag :type="profileStatusType(row.status)">
            {{ profileStatusText(row.status) }}
          </ElTag>
        </template>
        <template #operation="{ row }">
          <div class="flex gap-2">
            <SaButton type="success" @click="showViewDialog('view', row)" />
            <ElButton
              v-if="Number(row.audit_status) !== 1"
              v-permission="'help:audit:profile:audit'"
              size="small"
              type="success"
              @click="auditProfile(row, 1)"
            >
              通过
            </ElButton>
            <ElButton
              v-if="Number(row.audit_status) !== 2"
              v-permission="'help:audit:profile:audit'"
              size="small"
              type="warning"
              @click="auditProfile(row, 2)"
            >
              拒绝
            </ElButton>
            <SaButton
              v-permission="'help:audit:profile:update'"
              type="secondary"
              @click="showDialog('edit', row)"
            />
            <SaButton
              v-permission="'help:audit:profile:destroy'"
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
  import { ElMessage, ElMessageBox } from 'element-plus'
  import { useTable } from '@/hooks/core/useTable'
  import { useSaiAdmin } from '@/composables/useSaiAdmin'
  import api from '../../api/audit/profile'
  import TableSearch from './modules/table-search.vue'
  import EditDialog from './modules/edit-dialog.vue'
  import ViewDialog from './modules/view-dialog.vue'

  // 搜索表单
  const searchForm = ref({
    real_name: undefined,
    title: undefined,
    audit_status: undefined,
    status: undefined
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
        { prop: 'member_display', label: '关联会员', width: 150, useSlot: true },
        { prop: 'real_name', label: '真实姓名' },
        { prop: 'title', label: '职称' },
        { prop: 'hospital', label: '医院/机构' },
        { prop: 'department', label: '科室' },
        { prop: 'specialty', label: '专业方向' },
        { prop: 'license_no', label: '执业证书编号' },
        { prop: 'certification_image_urls', label: '证书图片', width: 120, useSlot: true },
        { prop: 'audit_status', label: '审核', width: 110, useSlot: true },
        { prop: 'status', label: '状态', width: 90, useSlot: true },
        { prop: 'audit_remark', label: '审核备注' },
        { prop: 'audit_by_display', label: '审核人' },
        { prop: 'audit_time', label: '审核时间' },
        { prop: 'approved_time', label: '通过时间' },
        { prop: 'operation', label: '操作', width: 260, fixed: 'right', useSlot: true }
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

  const auditProfile = async (row: Record<string, any>, auditStatus: number) => {
    let auditRemark = ''
    if (auditStatus === 2) {
      const result = await ElMessageBox.prompt('请输入拒绝原因', '拒绝医生资质', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        inputPlaceholder: '必填',
        inputValidator: (value) => String(value || '').trim() !== '' || '请输入拒绝原因'
      })
      auditRemark = String(result.value || '').trim()
    } else {
      await ElMessageBox.confirm(`确定通过医生资质 #${row.id} 吗？`, '审核医生资质', {
        type: 'warning'
      })
    }
    await api.audit({ id: row.id, audit_status: auditStatus, audit_remark: auditRemark })
    ElMessage.success('审核成功')
    refreshData()
  }

  const auditStatusText = (status: number) => {
    const map: Record<number, string> = {
      0: '待审核',
      1: '已通过',
      2: '已拒绝'
    }
    return map[Number(status)] || '未知'
  }

  const auditStatusType = (status: number) => {
    const map: Record<number, 'success' | 'warning' | 'danger' | 'info'> = {
      0: 'warning',
      1: 'success',
      2: 'danger'
    }
    return map[Number(status)] || 'info'
  }

  const profileStatusText = (status: number) => {
    const map: Record<number, string> = {
      1: '正常',
      2: '禁用'
    }
    return map[Number(status)] || '未知'
  }

  const profileStatusType = (status: number) => {
    return Number(status) === 1 ? 'success' : 'info'
  }

  const imageUrls = (row: Record<string, any>) => {
    return parseImageList(row.certification_image_urls || row.certification_images).map(
      normalizeImageUrl
    )
  }

  const parseImageList = (value: unknown): string[] => {
    if (!value) return []
    if (Array.isArray(value)) return value.map(String).filter(Boolean)
    if (typeof value !== 'string') return []
    try {
      const parsed = JSON.parse(value)
      if (Array.isArray(parsed)) return parsed.map(String).filter(Boolean)
      if (typeof parsed === 'string' && parsed) return [parsed]
    } catch {
      return value ? [value] : []
    }
    return value ? [value] : []
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
  .profile-member {
    display: flex;
    align-items: center;
    gap: 8px;
    line-height: 1.25;
  }

  .profile-member__meta,
  .profile-empty {
    color: var(--el-text-color-secondary);
    font-size: 12px;
  }

  .profile-cert-image {
    width: 38px;
    height: 38px;
    border-radius: 6px;
  }
</style>
