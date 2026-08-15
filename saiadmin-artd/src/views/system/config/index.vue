<!-- 左右页面 -->
<template>
  <div class="art-full-height">
    <div class="box-border flex gap-4 h-full max-md:block max-md:gap-0 max-md:h-auto">
      <div class="flex-shrink-0 h-full max-md:w-full max-md:h-auto max-md:mb-5">
        <ElCard class="left-card art-card-xs flex flex-col h-full mt-0" shadow="never">
          <template #header>
            <b>系统设置</b>
          </template>
          <ElSpace wrap>
            <SaButton type="primary" icon="ri:refresh-line" @click="reloadConfigData" />
            <SaButton v-permission="'core:config:edit'" type="primary" @click="showDialog('add')" />
            <SaButton
              v-permission="'core:config:edit'"
              type="secondary"
              @click="updateConfigDialog"
            />
            <SaButton v-permission="'core:config:edit'" type="error" @click="deleteConfigData" />
          </ElSpace>
          <ArtTable
            rowKey="id"
            :loading="loading"
            :data="groupData"
            :columns="groupColumns"
            :pagination="groupPagination"
            highlight-current-row
            @pagination:size-change="handleSizeChange"
            @pagination:current-change="handleCurrentChange"
          >
            <!-- 基础列 -->
            <template #name-header="{ column }">
              <ElPopover placement="bottom" :width="200" trigger="hover">
                <template #reference>
                  <div class="flex items-center gap-2 text-theme c-p custom-header">
                    <span>{{ column.label }}</span>
                    <ElIcon>
                      <Search />
                    </ElIcon>
                  </div>
                </template>
                <ElInput
                  v-model="configSearch.name"
                  placeholder="搜索配置名称"
                  size="small"
                  clearable
                  @input="handleConfigSearch"
                >
                  <template #prefix>
                    <ElIcon>
                      <Search />
                    </ElIcon>
                  </template>
                </ElInput>
              </ElPopover>
            </template>
            <template #code-header="{ column }">
              <ElPopover placement="bottom" :width="200" trigger="hover">
                <template #reference>
                  <div class="flex items-center gap-2 text-theme c-p custom-header">
                    <span>{{ column.label }}</span>
                    <ElIcon>
                      <Search />
                    </ElIcon>
                  </div>
                </template>
                <ElInput
                  v-model="configSearch.code"
                  placeholder="搜索配置标识"
                  size="small"
                  clearable
                  @input="handleConfigSearch"
                >
                  <template #prefix>
                    <ElIcon>
                      <Search />
                    </ElIcon>
                  </template>
                </ElInput>
              </ElPopover>
            </template>
            <template #id="{ row }">
              <ElRadio
                v-model="selectedId"
                :value="row.id"
                @update:modelValue="handleGroupChange(row.id, row)"
              />
            </template>
          </ArtTable>
        </ElCard>
      </div>

      <div class="flex flex-col flex-1 min-w-0">
        <ElCard class="art-card-xs flex flex-col h-full mt-0" shadow="never">
          <template #header>
            <div class="flex justify-between">
              <b>{{ selectedRow.name || '未选择配置' }}</b>
              <SaButton
                v-permission="'core:config:edit'"
                type="primary"
                icon="ri:settings-4-line"
                @click="handleConfigManage"
              />
            </div>
          </template>

          <div class="max-h-[calc(100vh-250px)] overflow-y-auto">
            <ElForm ref="formRef" :model="formData" label-width="140px">
              <template v-for="(item, index) in formArray" :key="index">
                <ElFormItem :label="item.name" :prop="item.key" v-show="item.display">
                  <div class="config-field">
                    <el-select
                      v-if="item.input_type === 'select'"
                      v-model="item.value"
                      class="config-control"
                      :options="item.config_select_data"
                      :no-data-text="selectNoDataText(item)"
                      @change="handleSelect($event, item)"
                      :placeholder="'请选择' + item.name"
                    />
                    <el-input
                      v-else-if="item.input_type === 'input'"
                      v-model="item.value"
                      class="config-control"
                      :placeholder="'请输入' + item.name"
                    />
                    <el-input
                      v-else-if="item.input_type === 'number'"
                      v-model="item.value"
                      class="config-control"
                      type="number"
                      v-bind="numberInputAttrs(item)"
                      :placeholder="'请输入' + item.name"
                    />
                    <el-radio-group
                      v-else-if="item.input_type === 'radio'"
                      v-model="item.value"
                      class="config-radio"
                      :options="item.config_select_data"
                    />
                    <sa-switch
                      v-else-if="item.input_type === 'switch'"
                      v-model="item.value"
                      active-value="1"
                      inactive-value="2"
                    />
                    <el-input
                      v-else-if="item.input_type === 'textarea'"
                      type="textarea"
                      v-model="item.value"
                      class="config-control"
                      :placeholder="'请输入' + item.name"
                    />
                    <sa-image-picker
                      v-else-if="item.input_type === 'uploadImage'"
                      v-model="item.value"
                    />
                    <sa-file-upload
                      v-else-if="item.input_type === 'uploadFile'"
                      v-model="item.value"
                    />
                    <sa-editor v-else-if="item.input_type === 'wangEditor'" v-model="item.value" />
                    <div v-if="formatConfigRemark(item.remark)" class="config-remark">
                      {{ formatConfigRemark(item.remark) }}
                    </div>
                  </div>
                </ElFormItem>
              </template>
              <ElFormItem v-permission="'core:config:update'" v-if="formArray.length > 0">
                <ElButton type="primary" @click="submit(formArray)">保存修改</ElButton>
              </ElFormItem>
              <ElFormItem
                v-permission="'core:config:update'"
                label="测试邮件"
                v-if="selectedRow.code === 'email_config'"
              >
                <div class="flex items-center gap-2">
                  <ElInput
                    v-model="email"
                    style="width: 300px"
                    placeholder="请输入正确的邮箱接收地址"
                  />
                  <ElButton @click="sendMail()">
                    <template #icon>
                      <ArtSvgIcon icon="ri:mail-line" />
                    </template>
                    发送
                  </ElButton>
                </div>
              </ElFormItem>
              <el-empty v-if="selectedId === 0" description="请先选择左侧配置" />
            </ElForm>
          </div>
        </ElCard>
      </div>
    </div>

    <!-- 配置编辑弹窗 -->
    <GroupEditDialog
      v-model="dialogVisible"
      :dialog-type="dialogType"
      :data="dialogData"
      @success="reloadConfigData()"
    />

    <!-- 配置项管理 -->
    <ConfigList v-model="configVisible" :data="selectedRow" @success="getConfigData()" />
  </div>
</template>

<script setup lang="ts">
  import { useTable } from '@/hooks/core/useTable'
  import { useSaiAdmin } from '@/composables/useSaiAdmin'
  import { Search } from '@element-plus/icons-vue'
  import { ElMessage } from 'element-plus'
  import api from '@/api/system/config'
  import helpRuntimeApi from '@/views/plugin/help/api/config/runtime'
  import GroupEditDialog from './modules/group-edit-dialog.vue'
  import ConfigList from './modules/config-list.vue'

  defineOptions({ name: 'TreeTable' })

  // 刷新配置数据
  const reloadConfigData = () => {
    selectedId.value = 0
    selectedRow.value = {}
    formArray.value = []
    getGroupData()
  }

  // 修改配置
  const updateConfigDialog = () => {
    if (selectedId.value === 0) {
      ElMessage.error('请选择要修改的数据')
      return
    }
    showDialog('edit', selectedRow.value)
  }

  // 删除配置
  const deleteConfigData = () => {
    if (selectedId.value === 0) {
      ElMessage.error('请选择要修改的数据')
      return
    }
    deleteRow({ ...selectedRow.value }, api.delete, reloadConfigData)
  }

  // 配置数据
  const formData = ref({})
  const formArray = ref<any[]>([])
  const email = ref('')

  const configVisible = ref(false)

  const formatConfigRemark = (remark?: string) => {
    const value = String(remark || '').trim()
    if (!value.startsWith('phinx:')) {
      return value
    }

    const match = value.match(/^phinx:[^:|]+(?::|\s*\|\s*)(.*)$/)
    return match?.[1]?.trim() || ''
  }

  const isAiAuditGroup = () => selectedRow.value.code === 'help_ai_audit'

  const selectNoDataText = (item: Record<string, any>) => {
    if (isAiAuditGroup() && item.key === 'ai_config_id') {
      return '暂无可用于文本审核的已启用模型'
    }
    return '暂无数据'
  }

  const numberInputAttrs = (item: Record<string, any>) => {
    if (!isAiAuditGroup()) {
      return {}
    }
    const limits: Record<string, { min: number; max: number; step: number }> = {
      auto_pass_confidence: { min: 0.5, max: 1, step: 0.01 },
      auto_reject_confidence: { min: 0.8, max: 1, step: 0.01 },
      max_attempts: { min: 1, max: 5, step: 1 },
      retry_delay_seconds: { min: 1, max: 300, step: 1 }
    }
    return limits[item.key] || {}
  }

  // 配置选中行
  const selectedId = ref(0)
  const selectedRow = ref<any>({})
  const configSearch = ref({
    name: '',
    code: ''
  })

  // 配置搜索
  const handleConfigSearch = () => {
    Object.assign(searchConfigParams, configSearch.value)
    getGroupData()
  }

  const searchForm = ref({
    label: '',
    value: '',
    status: '',
    group_id: null
  })

  /**
   * 配置分组改变时，获取配置数据
   */
  const handleGroupChange = (val: any, row?: any) => {
    selectedId.value = val
    selectedRow.value = row
    searchForm.value.group_id = val
    getConfigData()
  }

  const getConfigData = async () => {
    const [data, aiModels] = await Promise.all([
      api.configList({ group_id: selectedId.value, saiType: 'all' }),
      isAiAuditGroup() ? helpRuntimeApi.aiOptions() : Promise.resolve([])
    ])
    formArray.value = data.map((item: any) => {
      if (isAiAuditGroup() && item.key === 'ai_config_id') {
        item.config_select_data = aiModels
        if (String(item.value || '') === '0') {
          item.value = ''
        }
      }
      if (
        item.key.indexOf('local_') !== -1 ||
        item.key.indexOf('qiniu_') !== -1 ||
        item.key.indexOf('cos_') !== -1 ||
        item.key.indexOf('oss_') !== -1 ||
        item.key.indexOf('s3_') !== -1
      ) {
        item.display = false
      } else {
        item.display = true
      }
      return item
    })
    if (selectedId.value === 2) {
      formArray.value.forEach((item) => {
        if (item.key === 'upload_mode') {
          handleSelect(item.value, item)
        }
      })
    }
  }

  // 配置名称
  const {
    data: groupData,
    columns: groupColumns,
    getData: getGroupData,
    searchParams: searchConfigParams,
    loading,
    pagination: groupPagination,
    handleSizeChange,
    handleCurrentChange
  } = useTable({
    core: {
      apiFn: api.groupList,
      apiParams: {
        ...configSearch.value
      },
      columnsFactory: () => [
        { prop: 'id', label: '选中', width: 80, align: 'center', useSlot: true },
        { prop: 'name', label: '配置名称', useHeaderSlot: true, width: 150 },
        { prop: 'code', label: '配置标识', useHeaderSlot: true, width: 150 }
      ]
    }
  })

  // 编辑配置
  const { dialogType, dialogVisible, dialogData, showDialog, deleteRow } = useSaiAdmin()

  const handleConfigManage = () => {
    if (selectedId.value === 0) {
      ElMessage.error('请选择要管理的配置')
      return
    }
    configVisible.value = true
  }

  // 发送测试邮件
  const sendMail = async () => {
    const reg = /^[a-z0-9]+([._\\-]*[a-z0-9])*@([a-z0-9]+[-a-z0-9]*[a-z0-9]+.){1,63}[a-z0-9]+$/
    if (!reg.test(email.value)) {
      ElMessage.warning('请输入正确的邮箱地址')
      return
    }
    await api.emailTest({ email: email.value })
    ElMessage.success('发送成功')
  }

  // 自定义处理切换显示
  const handleSelect = async (val: any, ele: any) => {
    if (ele.key === 'upload_mode') {
      if (val == 1) {
        formArray.value.map((item) => {
          if (item.key.indexOf('local_') !== -1) {
            item.display = true
          }
          if (
            item.key.indexOf('qiniu_') !== -1 ||
            item.key.indexOf('cos_') !== -1 ||
            item.key.indexOf('oss_') !== -1 ||
            item.key.indexOf('s3_') !== -1
          ) {
            item.display = false
          }
        })
      }
      if (val == 2) {
        formArray.value.map((item) => {
          if (item.key.indexOf('oss_') !== -1) {
            item.display = true
          }
          if (
            item.key.indexOf('qiniu_') !== -1 ||
            item.key.indexOf('cos_') !== -1 ||
            item.key.indexOf('local_') !== -1 ||
            item.key.indexOf('s3_') !== -1
          ) {
            item.display = false
          }
        })
      }
      if (val == 3) {
        formArray.value.map((item) => {
          if (item.key.indexOf('qiniu_') !== -1) {
            item.display = true
          }
          if (
            item.key.indexOf('local_') !== -1 ||
            item.key.indexOf('cos_') !== -1 ||
            item.key.indexOf('oss_') !== -1 ||
            item.key.indexOf('s3_') !== -1
          ) {
            item.display = false
          }
        })
      }
      if (val == 4) {
        formArray.value.map((item) => {
          if (item.key.indexOf('cos_') !== -1) {
            item.display = true
          }
          if (
            item.key.indexOf('qiniu_') !== -1 ||
            item.key.indexOf('local_') !== -1 ||
            item.key.indexOf('oss_') !== -1 ||
            item.key.indexOf('s3_') !== -1
          ) {
            item.display = false
          }
        })
      }
      if (val == 5) {
        formArray.value.map((item) => {
          if (item.key.indexOf('s3_') !== -1) {
            item.display = true
          }
          if (
            item.key.indexOf('qiniu_') !== -1 ||
            item.key.indexOf('cos_') !== -1 ||
            item.key.indexOf('local_') !== -1 ||
            item.key.indexOf('oss_') !== -1
          ) {
            item.display = false
          }
        })
      }
    }
  }

  const submit = async (params: any) => {
    if (isAiAuditGroup()) {
      const values = Object.fromEntries(
        params.map((item: Record<string, any>) => [item.key, item.value ?? ''])
      )
      await helpRuntimeApi.update({ configs: { help_ai_audit: values } })
      ElMessage.success('保存成功')
      await getConfigData()
      return
    }
    const data = {
      group_id: selectedId.value,
      config: params
    }
    await api.batchUpdate(data)
    ElMessage.success('保存成功')
  }
</script>

<style scoped>
  .left-card :deep(.el-card__body) {
    flex: 1;
    min-height: 0;
    padding: 10px 2px 10px 10px;
  }

  .config-field {
    display: flex;
    width: 100%;
    flex-direction: column;
    align-items: flex-start;
    gap: 6px;
  }

  .config-control {
    width: 100%;
    max-width: 720px;
  }

  .config-radio {
    min-height: 32px;
  }

  .config-remark {
    color: var(--el-text-color-secondary);
    font-size: 12px;
    line-height: 1.5;
  }
</style>
