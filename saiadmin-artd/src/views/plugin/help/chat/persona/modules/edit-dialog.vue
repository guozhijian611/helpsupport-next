<template>
  <el-drawer
    v-model="visible"
    :title="dialogType === 'add' ? '新增互动角色' : '编辑互动角色'"
    :size="920"
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form ref="formRef" :model="formData" :rules="rules" label-width="130px">
      <el-tabs v-model="activeTab">
        <el-tab-pane label="展示" name="display">
          <el-row :gutter="20">
            <el-col :span="12">
              <el-form-item label="角色编码" prop="code">
                <el-input
                  v-model="formData.code"
                  :disabled="Number(formData.is_system) === 1"
                  placeholder="例如 night_companion"
                />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="卡片图标" prop="icon">
                <HelpMaterialIconPicker v-model="formData.icon" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="状态" prop="status">
                <sa-radio v-model="formData.status" dict="data_status" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="中文标题" prop="title_zh">
                <el-input v-model="formData.title_zh" placeholder="App 卡片中文标题" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="英文标题" prop="title_en">
                <el-input v-model="formData.title_en" placeholder="English title" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="浅色封面" prop="cover">
                <sa-image-upload v-model="formData.cover" :limit="1" :multiple="false" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="深色封面" prop="cover_dark">
                <sa-image-upload v-model="formData.cover_dark" :limit="1" :multiple="false" />
              </el-form-item>
            </el-col>
            <el-col :span="24">
              <el-form-item label="中文简介" prop="description_zh">
                <el-input v-model="formData.description_zh" type="textarea" :rows="2" />
              </el-form-item>
            </el-col>
            <el-col :span="24">
              <el-form-item label="英文简介" prop="description_en">
                <el-input v-model="formData.description_en" type="textarea" :rows="2" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="中文标签" prop="tags_zh">
                <el-input v-model="formData.tags_zh" placeholder="逗号分隔，如 陪伴,夜间" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="英文标签" prop="tags_en">
                <el-input v-model="formData.tags_en" placeholder="comma separated" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="排序" prop="sort">
                <el-input-number v-model="formData.sort" :min="0" class="w-full" />
              </el-form-item>
            </el-col>
          </el-row>
        </el-tab-pane>
        <el-tab-pane label="能力" name="capability">
          <el-row :gutter="20">
            <el-col :span="12">
              <el-form-item label="在线模式">
                <sa-radio v-model="formData.allow_online" dict="yes_or_no" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="本地模式">
                <sa-radio v-model="formData.allow_local" dict="yes_or_no" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="实时音视频">
                <sa-radio v-model="formData.allow_realtime" dict="yes_or_no" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="语音消息">
                <sa-radio v-model="formData.allow_voice" dict="yes_or_no" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="用户改提示词">
                <sa-radio v-model="formData.allow_user_prompt" dict="yes_or_no" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="语音运行时" prop="speech_runtime">
                <el-select v-model="formData.speech_runtime" class="w-full">
                  <el-option label="在线" value="online" />
                  <el-option label="端侧" value="local" />
                  <el-option label="自动（端侧优先）" value="auto" />
                </el-select>
              </el-form-item>
            </el-col>
          </el-row>
        </el-tab-pane>
        <el-tab-pane label="模型" name="models">
          <el-row :gutter="20">
            <el-col :span="12">
              <el-form-item label="默认文本模型">
                <el-select v-model="formData.online_config_id" clearable class="w-full">
                  <el-option
                    v-for="item in textModels"
                    :key="item.value"
                    :label="item.label"
                    :value="item.value"
                  />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="实时音视频">
                <el-select v-model="formData.realtime_config_id" clearable class="w-full">
                  <el-option
                    v-for="item in realtimeModels"
                    :key="item.value"
                    :label="item.label"
                    :value="item.value"
                  />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="在线 ASR">
                <el-select v-model="formData.asr_config_id" clearable class="w-full">
                  <el-option
                    v-for="item in asrModels"
                    :key="item.value"
                    :label="item.label"
                    :value="item.value"
                  />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="在线 TTS">
                <el-select v-model="formData.tts_config_id" clearable class="w-full">
                  <el-option
                    v-for="item in ttsModels"
                    :key="item.value"
                    :label="item.label"
                    :value="item.value"
                  />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="TTS 音色">
                <el-input v-model="formData.tts_voice" placeholder="如 alloy / Ethan" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="默认本地模型">
                <el-select v-model="formData.local_model_id" clearable class="w-full">
                  <el-option label="未指定" :value="0" />
                  <el-option
                    v-for="item in localTextModels"
                    :key="item.value"
                    :label="item.label"
                    :value="item.value"
                  />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="端侧 ASR">
                <el-select v-model="formData.local_asr_id" clearable class="w-full">
                  <el-option label="未指定" :value="0" />
                  <el-option
                    v-for="item in localAsrModels"
                    :key="item.value"
                    :label="item.label"
                    :value="item.value"
                  />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="端侧 TTS">
                <el-select v-model="formData.local_tts_id" clearable class="w-full">
                  <el-option label="未指定" :value="0" />
                  <el-option
                    v-for="item in localTtsModels"
                    :key="item.value"
                    :label="item.label"
                    :value="item.value"
                  />
                </el-select>
              </el-form-item>
            </el-col>
          </el-row>
        </el-tab-pane>
        <el-tab-pane v-if="dialogType === 'edit' && formData.id" label="预设提示词" name="prompts">
          <div class="mb-3 flex justify-end">
            <ElButton type="primary" @click="showPromptDialog('add')">新增预设</ElButton>
          </div>
          <ElTable :data="prompts" size="small">
            <ElTableColumn prop="locale" label="语言" width="90" />
            <ElTableColumn prop="runtime_mode" label="运行模式" width="100" />
            <ElTableColumn prop="title" label="标题" min-width="140" />
            <ElTableColumn label="操作" width="140">
              <template #default="{ row }">
                <ElButton link type="primary" @click="showPromptDialog('edit', row)">编辑</ElButton>
                <ElButton link type="danger" @click="removePrompt(row)">删除</ElButton>
              </template>
            </ElTableColumn>
          </ElTable>
        </el-tab-pane>
      </el-tabs>
    </el-form>
    <template #footer>
      <el-button @click="handleClose">取消</el-button>
      <el-button type="primary" @click="handleSubmit">提交</el-button>
    </template>
  </el-drawer>

  <el-dialog v-model="promptVisible" :title="promptType === 'add' ? '新增预设提示词' : '编辑预设提示词'" width="640px">
    <el-form :model="promptForm" label-width="110px">
      <el-form-item label="运行模式">
        <el-select v-model="promptForm.runtime_mode" class="w-full">
          <el-option label="在线" value="online" />
          <el-option label="本地" value="local" />
        </el-select>
      </el-form-item>
      <el-form-item label="语言">
        <el-input v-model="promptForm.locale" placeholder="zh-CN / en" />
      </el-form-item>
      <el-form-item label="标题">
        <el-input v-model="promptForm.title" />
      </el-form-item>
      <el-form-item label="系统提示词">
        <el-input v-model="promptForm.system_prompt" type="textarea" :rows="6" />
      </el-form-item>
      <el-form-item label="开场白">
        <el-input v-model="promptForm.first_message" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="promptVisible = false">取消</el-button>
      <el-button type="primary" @click="savePrompt">保存</el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
  import { ElMessage } from 'element-plus'
  import type { FormInstance, FormRules } from 'element-plus'
  import api, { personaPromptApi } from '../../../api/chat/persona'
  import { loadAiConfigs } from '../../../api/chat/aiConfigOptions'
  import catalogApi from '../../../api/localModel/catalog'
  import HelpMaterialIconPicker from '../../../components/HelpMaterialIconPicker.vue'
  import { defaultPersonaIcon } from '../../../components/materialPersonaIcons'

  interface Props {
    modelValue: boolean
    dialogType: string
    data?: Record<string, any>
  }

  const props = withDefaults(defineProps<Props>(), {
    dialogType: 'add',
    data: undefined
  })
  const emit = defineEmits<{
    (e: 'update:modelValue', value: boolean): void
    (e: 'success'): void
  }>()

  const formRef = ref<FormInstance>()
  const activeTab = ref('display')
  const textModels = ref<Array<{ label: string; value: number }>>([])
  const realtimeModels = ref<Array<{ label: string; value: number }>>([])
  const asrModels = ref<Array<{ label: string; value: number }>>([])
  const ttsModels = ref<Array<{ label: string; value: number }>>([])
  const localCatalog = ref<Array<{ label: string; value: number; capability: string }>>([])
  const localTextModels = computed(() =>
    localCatalog.value.filter((item) => !item.capability || item.capability === 'llm')
  )
  const localAsrModels = computed(() => localCatalog.value.filter((item) => item.capability === 'asr'))
  const localTtsModels = computed(() => localCatalog.value.filter((item) => item.capability === 'tts'))
  const prompts = ref<any[]>([])
  const promptVisible = ref(false)
  const promptType = ref('add')
  const promptForm = reactive({
    id: 0,
    runtime_mode: 'online',
    locale: 'zh-CN',
    title: '',
    system_prompt: '',
    first_message: '',
    status: 1
  })

  const visible = computed({
    get: () => props.modelValue,
    set: (value) => emit('update:modelValue', value)
  })

  const formData = reactive<Record<string, any>>(emptyForm())
  const rules = reactive<FormRules>({
    code: [{ required: true, message: '请填写角色编码', trigger: 'blur' }],
    title_zh: [{ required: true, message: '请填写中文标题', trigger: 'blur' }],
    sort: [{ required: true, message: '请填写排序', trigger: 'blur' }],
    status: [{ required: true, message: '请选择状态', trigger: 'change' }]
  })

  watch(
    () => props.modelValue,
    async (open) => {
      if (!open) return
      activeTab.value = 'display'
      Object.assign(formData, emptyForm(), flattenPersona(props.data || {}))
      textModels.value = await loadAiConfigs()
      realtimeModels.value = await loadAiConfigs('realtime')
      asrModels.value = await loadAiConfigs('asr')
      ttsModels.value = await loadAiConfigs('tts')
      localCatalog.value = await loadLocalCatalog()
      if (formData.id) {
        await loadPrompts()
      }
    }
  )

  const handleClose = () => {
    visible.value = false
  }

  const handleSubmit = async () => {
    await formRef.value?.validate()
    const payload = { ...formData }
    if (props.dialogType === 'add') {
      await api.save(payload)
    } else {
      await api.update(payload)
    }
    ElMessage.success('保存成功')
    emit('success')
    handleClose()
  }

  const loadPrompts = async () => {
    const result = await personaPromptApi.list({ persona_id: formData.id, page: 1, limit: 50 })
    prompts.value = (result as any)?.data || []
  }

  const showPromptDialog = (type: string, row?: Record<string, any>) => {
    promptType.value = type
    Object.assign(promptForm, {
      id: row?.id || 0,
      runtime_mode: row?.runtime_mode || 'online',
      locale: row?.locale || 'zh-CN',
      title: row?.title || '',
      system_prompt: row?.system_prompt || '',
      first_message: row?.first_message || '',
      status: row?.status || 1
    })
    promptVisible.value = true
  }

  const savePrompt = async () => {
    const payload = { ...promptForm, persona_id: formData.id }
    if (promptType.value === 'add') {
      await personaPromptApi.save(payload)
    } else {
      await personaPromptApi.update(payload)
    }
    ElMessage.success('提示词已保存')
    promptVisible.value = false
    await loadPrompts()
  }

  const removePrompt = async (row: Record<string, any>) => {
    await personaPromptApi.delete({ ids: [row.id] })
    await loadPrompts()
  }

  function emptyForm() {
    return {
      id: 0,
      code: '',
      icon: defaultPersonaIcon(''),
      is_system: 2,
      title_zh: '',
      title_en: '',
      description_zh: '',
      description_en: '',
      tags_zh: '',
      tags_en: '',
      cover: '',
      cover_dark: '',
      allow_online: 1,
      allow_local: 1,
      allow_realtime: 2,
      allow_voice: 1,
      allow_user_prompt: 1,
      speech_runtime: 'online',
      online_config_id: 0,
      realtime_config_id: 0,
      asr_config_id: 0,
      tts_config_id: 0,
      tts_voice: '',
      local_model_id: 0,
      local_asr_id: 0,
      local_tts_id: 0,
      sort: 100,
      status: 1
    }
  }

  async function loadLocalCatalog() {
    const result = await catalogApi.list({ page: 1, limit: 200, saiType: 'all' })
    const list = Array.isArray(result) ? result : ((result as any)?.data ?? [])
    return (Array.isArray(list) ? list : []).map((item: any) => ({
      label: `${item.name} (#${item.id})`,
      value: Number(item.id),
      capability: String(item.capability || 'llm')
    }))
  }

  function flattenPersona(row: Record<string, any>) {
    const tags = row.tags_i18n || {}
    return {
      ...emptyForm(),
      ...row,
      title_zh: row.display_name || row.title_i18n?.['zh-CN'] || '',
      title_en: row.display_name_en || row.title_i18n?.en || '',
      description_zh: row.description || row.description_i18n?.['zh-CN'] || '',
      description_en: row.description_en || row.description_i18n?.en || '',
      tags_zh: Array.isArray(tags['zh-CN']) ? tags['zh-CN'].join(',') : '',
      tags_en: Array.isArray(tags.en) ? tags.en.join(',') : '',
      cover: row.cover || row.avatar || '',
      cover_dark: row.cover_dark || row.dark_avatar || '',
      icon: row.icon || defaultPersonaIcon(row.code || '')
    }
  }
</script>
