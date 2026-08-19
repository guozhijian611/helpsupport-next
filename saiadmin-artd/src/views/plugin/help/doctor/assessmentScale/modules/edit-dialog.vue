<template>
  <el-drawer
    v-model="visible"
    :title="dialogType === 'add' ? '新增评估量表' : '编辑评估量表'"
    size="960px"
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <div v-loading="loading">
      <el-form ref="formRef" :model="formData" :rules="rules" label-width="96px">
        <el-tabs v-model="activeTab">
          <el-tab-pane label="基本信息" name="basic">
            <el-row :gutter="16">
              <el-col :span="24">
                <el-form-item label="量表名称" prop="title">
                  <el-input
                    v-model="formData.title"
                    maxlength="160"
                    show-word-limit
                    placeholder="例如：睡眠质量自评量表"
                  />
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="所属医生" prop="doctor_id">
                  <HelpRelationSelect
                    v-model="formData.doctor_id"
                    relation="doctor"
                    placeholder="系统量表可选择未指定"
                    include-zero
                    zero-label="#0 系统/未指定"
                  />
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="所属阶段" prop="stage">
                  <el-select
                    v-model="formData.stage"
                    placeholder="请选择阶段，也可输入自定义阶段"
                    filterable
                    allow-create
                    default-first-option
                  >
                    <el-option
                      v-for="option in SCALE_STAGE_OPTIONS"
                      :key="option.value"
                      :label="option.label"
                      :value="option.value"
                    />
                  </el-select>
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="状态" prop="status">
                  <el-select v-model="formData.status" placeholder="请选择状态">
                    <el-option
                      v-for="option in SCALE_STATUS_OPTIONS"
                      :key="option.value"
                      :label="option.label"
                      :value="option.value"
                    />
                  </el-select>
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="总分" prop="total_score">
                  <div class="scale-score-field">
                    <el-input-number
                      v-model="formData.total_score"
                      :min="0"
                      :precision="0"
                      controls-position="right"
                    />
                    <el-button @click="syncTotalScore">按题目重算</el-button>
                    <span class="scale-score-hint">按当前题目最高分合计为 {{ computedScore }}</span>
                  </div>
                </el-form-item>
              </el-col>
              <el-col :span="24">
                <el-form-item label="简介" prop="description">
                  <el-input
                    v-model="formData.description"
                    type="textarea"
                    :rows="4"
                    maxlength="500"
                    show-word-limit
                    placeholder="填写量表说明、适用场景或患者填写指导"
                  />
                </el-form-item>
              </el-col>
              <el-col :span="24">
                <el-form-item label="备注" prop="remark">
                  <el-input
                    v-model="formData.remark"
                    type="textarea"
                    :rows="2"
                    placeholder="仅后台可见，可记录来源或使用说明"
                  />
                </el-form-item>
              </el-col>
            </el-row>
          </el-tab-pane>

          <el-tab-pane name="questions">
            <template #label>
              <span>题目配置</span>
              <el-badge
                :value="formData.questions.length"
                :hidden="formData.questions.length === 0"
              />
            </template>
            <div class="scale-section-toolbar">
              <div>
                <div class="scale-section-title">题目列表</div>
                <p class="scale-section-desc">
                  直接编辑题干和选项，无需填写 JSON。新题目默认使用 4 级李克特选项。
                </p>
              </div>
              <el-space wrap>
                <el-button @click="addQuestion(FREQUENCY5_OPTIONS)">添加 5 级频率题</el-button>
                <el-button type="primary" @click="addQuestion()">添加题目</el-button>
              </el-space>
            </div>

            <ElEmpty
              v-if="formData.questions.length === 0"
              description="还没有题目，先添加一道题再发布"
              :image-size="80"
            />

            <article
              v-for="(question, questionIndex) in formData.questions"
              :key="question.id"
              class="scale-question-card"
            >
              <header class="scale-question-card__header">
                <strong>题目 {{ questionIndex + 1 }}</strong>
                <el-space>
                  <el-button
                    text
                    :disabled="questionIndex === 0"
                    @click="moveQuestion(questionIndex, -1)"
                  >
                    上移
                  </el-button>
                  <el-button
                    text
                    :disabled="questionIndex === formData.questions.length - 1"
                    @click="moveQuestion(questionIndex, 1)"
                  >
                    下移
                  </el-button>
                  <el-button text type="danger" @click="removeQuestion(questionIndex)"
                    >删除</el-button
                  >
                </el-space>
              </header>

              <el-form-item
                label="题目标题"
                :prop="`questions.${questionIndex}.title`"
                class="is-required"
              >
                <el-input
                  v-model="question.title"
                  maxlength="200"
                  placeholder="例如：近一周入睡通常需要较长时间"
                />
              </el-form-item>

              <div class="scale-option-toolbar">
                <span>选项</span>
                <el-space>
                  <el-button size="small" @click="applyOptionTemplate(question, LIKERT4_OPTIONS)">
                    套用 4 级
                  </el-button>
                  <el-button
                    size="small"
                    @click="applyOptionTemplate(question, FREQUENCY5_OPTIONS)"
                  >
                    套用 5 级
                  </el-button>
                  <el-button size="small" type="primary" plain @click="addOption(question)">
                    添加选项
                  </el-button>
                </el-space>
              </div>

              <div class="scale-option-list">
                <div
                  v-for="(option, optionIndex) in question.options"
                  :key="option.id"
                  class="scale-option-row"
                >
                  <span class="scale-option-index">选项 {{ optionIndex + 1 }}</span>
                  <el-input v-model="option.label" placeholder="选项文案" />
                  <el-input-number
                    v-model="option.score"
                    :min="0"
                    :precision="0"
                    controls-position="right"
                  />
                  <el-button
                    text
                    type="danger"
                    :disabled="question.options.length <= 2"
                    @click="removeOption(question, optionIndex)"
                  >
                    删除
                  </el-button>
                </div>
              </div>
            </article>
          </el-tab-pane>

          <el-tab-pane name="rules">
            <template #label>
              <span>计分规则</span>
              <el-badge
                :value="formData.scoring_rule.length"
                :hidden="formData.scoring_rule.length === 0"
              />
            </template>
            <div class="scale-section-toolbar">
              <div>
                <div class="scale-section-title">结果区间</div>
                <p class="scale-section-desc">
                  按得分区间给出等级和建议。可一键按总分生成轻度 / 中度 / 高风险三档。
                </p>
              </div>
              <el-space wrap>
                <el-button @click="generateRules">按总分生成</el-button>
                <el-button type="primary" @click="addRule">添加规则</el-button>
              </el-space>
            </div>

            <ElEmpty
              v-if="formData.scoring_rule.length === 0"
              description="还没有计分规则，可先按总分生成"
              :image-size="80"
            />

            <article
              v-for="(rule, ruleIndex) in formData.scoring_rule"
              :key="`rule-${ruleIndex}`"
              class="scale-question-card"
            >
              <header class="scale-question-card__header">
                <strong>规则 {{ ruleIndex + 1 }}</strong>
                <el-button text type="danger" @click="removeRule(ruleIndex)">删除</el-button>
              </header>
              <el-row :gutter="16">
                <el-col :span="12">
                  <el-form-item label="等级名称">
                    <el-input v-model="rule.label" placeholder="例如：睡眠受扰" />
                  </el-form-item>
                </el-col>
                <el-col :span="6">
                  <el-form-item label="最低分">
                    <el-input-number
                      v-model="rule.min_score"
                      :min="0"
                      :precision="0"
                      controls-position="right"
                      class="w-full"
                    />
                  </el-form-item>
                </el-col>
                <el-col :span="6">
                  <el-form-item label="最高分">
                    <el-input-number
                      v-model="rule.max_score"
                      :min="0"
                      :precision="0"
                      controls-position="right"
                      class="w-full"
                    />
                  </el-form-item>
                </el-col>
                <el-col :span="24">
                  <el-form-item label="结果建议">
                    <el-input
                      v-model="rule.suggestion"
                      type="textarea"
                      :rows="2"
                      placeholder="患者或医生看到该分数区间时的建议"
                    />
                  </el-form-item>
                </el-col>
              </el-row>
            </article>
          </el-tab-pane>

          <el-tab-pane label="预览" name="preview">
            <ScalePreview
              :title="formData.title"
              :description="formData.description"
              :stage="formData.stage"
              :status="formData.status"
              :total-score="formData.total_score"
              :doctor-id="formData.doctor_id"
              :questions="formData.questions"
              :scoring-rule="formData.scoring_rule"
              :remark="formData.remark"
              :published-at="formData.published_at"
            />
          </el-tab-pane>
        </el-tabs>
      </el-form>
    </div>

    <template #footer>
      <el-button @click="handleClose">取消</el-button>
      <el-button type="primary" :loading="submitLoading" @click="handleSubmit">保存</el-button>
    </template>
  </el-drawer>
</template>

<script setup lang="ts">
  import { ElMessage } from 'element-plus'
  import type { FormInstance, FormRules } from 'element-plus'
  import HelpRelationSelect from '../../../components/HelpRelationSelect.vue'
  import api from '../../../api/doctor/assessmentScale'
  import ScalePreview from './scale-preview.vue'
  import {
    FREQUENCY5_OPTIONS,
    LIKERT4_OPTIONS,
    SCALE_STAGE_OPTIONS,
    SCALE_STATUS_OPTIONS,
    buildDefaultScoringRules,
    computeTotalScore,
    createEmptyQuestion,
    createEmptyRule,
    createOptions,
    createUid,
    normalizeQuestions,
    normalizeRules,
    serializeQuestions,
    validateScaleContent,
    type ScaleOption,
    type ScaleQuestion,
    type ScaleScoreRule
  } from './scaleHelpers'

  interface Props {
    modelValue: boolean
    dialogType: string
    data?: Record<string, any>
  }
  interface Emits {
    (e: 'update:modelValue', value: boolean): void
    (e: 'success'): void
  }

  const props = withDefaults(defineProps<Props>(), {
    modelValue: false,
    dialogType: 'add',
    data: undefined
  })
  const emit = defineEmits<Emits>()

  const formRef = ref<FormInstance>()
  const loading = ref(false)
  const submitLoading = ref(false)
  const activeTab = ref('basic')
  const visible = computed({
    get: () => props.modelValue,
    set: (value) => emit('update:modelValue', value)
  })

  const rules = reactive<FormRules>({
    title: [{ required: true, message: '量表名称必须填写', trigger: 'blur' }],
    status: [{ required: true, message: '状态必须填写', trigger: 'change' }]
  })

  const formData = reactive({
    id: '',
    doctor_id: 0,
    title: '',
    stage: 'intake',
    description: '',
    total_score: 0,
    questions: [] as ScaleQuestion[],
    scoring_rule: [] as ScaleScoreRule[],
    status: 'draft',
    remark: '',
    published_at: ''
  })

  const computedScore = computed(() => computeTotalScore(formData.questions))

  const resetForm = () => {
    formData.id = ''
    formData.doctor_id = 0
    formData.title = ''
    formData.stage = 'intake'
    formData.description = ''
    formData.total_score = 0
    formData.questions = []
    formData.scoring_rule = []
    formData.status = 'draft'
    formData.remark = ''
    formData.published_at = ''
    activeTab.value = 'basic'
  }

  const fillForm = (detail: Record<string, any>) => {
    formData.id = String(detail.id || '')
    formData.doctor_id = Number(detail.doctor_id || 0)
    formData.title = String(detail.title || '')
    formData.stage = String(detail.stage || 'intake')
    formData.description = String(detail.description || '')
    formData.total_score = Number(detail.total_score || 0)
    formData.questions = normalizeQuestions(detail.questions)
    formData.scoring_rule = normalizeRules(detail.scoring_rule)
    formData.status = String(detail.status || 'draft')
    formData.remark = String(detail.remark || '')
    formData.published_at = String(detail.published_at || '')
  }

  watch(
    () => props.modelValue,
    async (open) => {
      if (!open) {
        return
      }
      resetForm()
      if (props.dialogType !== 'edit' || props.data?.id === undefined) {
        formData.questions = [createEmptyQuestion()]
        formData.scoring_rule = []
        return
      }
      loading.value = true
      try {
        fillForm(await api.read(props.data.id))
      } finally {
        loading.value = false
      }
    }
  )

  const addQuestion = (templates = LIKERT4_OPTIONS) => {
    formData.questions.push(createEmptyQuestion(templates))
    if (formData.total_score === 0) {
      formData.total_score = computedScore.value
    }
    activeTab.value = 'questions'
  }

  const removeQuestion = (index: number) => {
    formData.questions.splice(index, 1)
  }

  const moveQuestion = (index: number, offset: number) => {
    const target = index + offset
    if (target < 0 || target >= formData.questions.length) {
      return
    }
    const [item] = formData.questions.splice(index, 1)
    formData.questions.splice(target, 0, item)
  }

  const addOption = (question: ScaleQuestion) => {
    question.options.push({
      id: createUid('opt'),
      label: '',
      score: 0
    })
    question.optionCount = question.options.length
  }

  const removeOption = (question: ScaleQuestion, index: number) => {
    if (question.options.length <= 2) {
      return
    }
    question.options.splice(index, 1)
    question.optionCount = question.options.length
  }

  const applyOptionTemplate = (
    question: ScaleQuestion,
    templates: Array<Pick<ScaleOption, 'label' | 'score'>>
  ) => {
    question.options = createOptions(templates)
    question.optionCount = question.options.length
  }

  const addRule = () => {
    formData.scoring_rule.push(createEmptyRule())
    activeTab.value = 'rules'
  }

  const removeRule = (index: number) => {
    formData.scoring_rule.splice(index, 1)
  }

  const generateRules = () => {
    const totalScore = formData.total_score || computedScore.value
    if (totalScore <= 0) {
      ElMessage.warning('请先填写总分或添加题目后再生成计分规则')
      return
    }
    formData.scoring_rule = buildDefaultScoringRules(totalScore)
    formData.total_score = totalScore
    activeTab.value = 'rules'
  }

  const syncTotalScore = () => {
    formData.total_score = computedScore.value
    ElMessage.success(`已按题目最高分重算为 ${formData.total_score}`)
  }

  const handleClose = () => {
    visible.value = false
    formRef.value?.clearValidate()
  }

  const handleSubmit = async () => {
    if (!formRef.value) {
      return
    }
    await formRef.value.validate()
    const contentError = validateScaleContent(formData.questions, formData.scoring_rule)
    if (contentError) {
      ElMessage.warning(contentError)
      activeTab.value = formData.questions.some((item) => !item.title.trim())
        ? 'questions'
        : 'rules'
      return
    }
    submitLoading.value = true
    try {
      const payload = {
        ...formData,
        questions: serializeQuestions(formData.questions),
        scoring_rule: formData.scoring_rule,
        total_score: formData.total_score || computedScore.value
      }
      if (props.dialogType === 'edit') {
        await api.update(payload)
      } else {
        await api.save(payload)
      }
      ElMessage.success('保存成功')
      emit('success')
      handleClose()
    } finally {
      submitLoading.value = false
    }
  }
</script>

<style scoped>
  .scale-score-field {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    align-items: center;
    width: 100%;
  }

  .scale-score-hint {
    font-size: 13px;
    color: var(--el-text-color-secondary);
  }

  .scale-section-toolbar {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    align-items: flex-start;
    justify-content: space-between;
    margin-bottom: 16px;
  }

  .scale-section-title {
    font-size: 15px;
    font-weight: 600;
  }

  .scale-section-desc {
    margin: 6px 0 0;
    font-size: 13px;
    line-height: 1.6;
    color: var(--el-text-color-secondary);
  }

  .scale-question-card {
    padding: 16px 16px 8px;
    margin-bottom: 14px;
    background: var(--el-fill-color-blank);
    border: 1px solid var(--el-border-color-lighter);
    border-radius: 10px;
  }

  .scale-question-card__header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 12px;
  }

  .scale-option-toolbar {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    align-items: center;
    justify-content: space-between;
    margin: 4px 0 12px;
    font-size: 13px;
    color: var(--el-text-color-regular);
  }

  .scale-option-list {
    display: flex;
    flex-direction: column;
    gap: 10px;
    margin-bottom: 8px;
  }

  .scale-option-row {
    display: grid;
    grid-template-columns: 72px minmax(0, 1fr) 140px auto;
    gap: 10px;
    align-items: center;
  }

  .scale-option-index {
    font-size: 13px;
    color: var(--el-text-color-secondary);
  }

  :deep(.el-badge) {
    margin-left: 6px;
  }

  :deep(.w-full) {
    width: 100%;
  }
</style>
