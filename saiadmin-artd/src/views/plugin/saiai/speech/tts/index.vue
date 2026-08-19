<template>
  <div class="speech-test">
    <section class="toolbar-band">
      <div class="toolbar-inner">
        <div class="title-block">
          <h2>SAI TTS 合成测试</h2>
          <p>选择在线 TTS 配置，输入文本后生成语音，验证文字聊天用的播报通道。</p>
        </div>
        <div class="actions">
          <el-select v-model="selectedConfigId" placeholder="选择 TTS 配置" class="config-select">
            <el-option
              v-for="item in configs"
              :key="item.id"
              :label="`${item.name} / ${item.model}`"
              :value="item.id"
            />
          </el-select>
          <el-input v-model="voice" placeholder="音色，如 alloy / Ethan" class="voice-input" clearable />
          <el-button type="primary" :loading="loading" :disabled="!canSubmit" @click="handleSynthesize">
            开始合成
          </el-button>
        </div>
      </div>
    </section>

    <section class="control-grid">
      <div class="panel">
        <div class="panel-header">
          <h3>合成文本</h3>
          <el-tag>{{ text.trim().length }} 字</el-tag>
        </div>
        <el-input
          v-model="text"
          type="textarea"
          :rows="12"
          maxlength="4096"
          show-word-limit
          placeholder="输入一段要播报的中文或英文"
        />
      </div>

      <div class="panel">
        <div class="panel-header">
          <h3>合成结果</h3>
          <el-tag :type="audioUrl ? 'success' : 'info'">{{ audioUrl ? '可播放' : '等待合成' }}</el-tag>
        </div>
        <p class="meta">{{ resultMeta }}</p>
        <audio v-if="audioUrl" class="audio-player" :src="audioUrl" controls autoplay />
        <el-empty v-else description="合成后可在这里试听" />
        <p v-if="errorText" class="error-text">{{ errorText }}</p>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
  import { ElMessage } from 'element-plus'
  import speechApi, { type SpeechConfigItem } from '../../api/speech'

  const configs = ref<SpeechConfigItem[]>([])
  const selectedConfigId = ref<number>()
  const voice = ref('')
  const text = ref('你好，这是一段 TTS 测试。')
  const audioUrl = ref('')
  const resultMeta = ref('尚未合成')
  const loading = ref(false)
  const errorText = ref('')

  const canSubmit = computed(() => !!selectedConfigId.value && text.value.trim() !== '')

  onMounted(loadConfigs)

  async function loadConfigs() {
    configs.value = await speechApi.configs('tts')
    const first = configs.value[0]
    if (!selectedConfigId.value && first) {
      selectedConfigId.value = first.id
      if (!voice.value && first.voice) voice.value = first.voice
    }
  }

  watch(selectedConfigId, (id) => {
    const current = configs.value.find((item) => item.id === id)
    if (current?.voice) voice.value = current.voice
  })

  async function handleSynthesize() {
    if (!selectedConfigId.value || text.value.trim() === '') {
      ElMessage.warning('请先选择 TTS 配置并输入文本')
      return
    }

    loading.value = true
    errorText.value = ''
    try {
      const result = await speechApi.tts({
        config_id: selectedConfigId.value,
        text: text.value.trim(),
        voice: voice.value.trim()
      })
      audioUrl.value = result.audio_url
      resultMeta.value = `${result.model} / ${result.voice || '默认音色'}`
      ElMessage.success('合成完成')
    } catch (error: any) {
      errorText.value = error?.message || '合成失败'
    } finally {
      loading.value = false
    }
  }
</script>

<style scoped lang="scss">
  .speech-test {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .toolbar-band,
  .panel {
    border: 1px solid var(--el-border-color-light);
    border-radius: 12px;
    background: var(--el-bg-color);
  }

  .toolbar-inner,
  .panel-header,
  .actions {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
  }

  .toolbar-inner,
  .panel {
    padding: 20px;
  }

  .title-block h2,
  .panel-header h3 {
    margin: 0 0 6px;
  }

  .title-block p,
  .meta {
    margin: 0;
    color: var(--el-text-color-secondary);
  }

  .config-select {
    width: 280px;
  }

  .voice-input {
    width: 200px;
  }

  .control-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 16px;
  }

  .panel-header {
    margin-bottom: 16px;
  }

  .meta {
    margin-bottom: 16px;
  }

  .audio-player {
    width: 100%;
  }

  .error-text {
    margin-top: 12px;
    color: var(--el-color-danger);
  }

  @media (max-width: 960px) {
    .toolbar-inner,
    .actions {
      flex-direction: column;
      align-items: stretch;
    }

    .config-select,
    .voice-input,
    .control-grid {
      width: 100%;
      grid-template-columns: 1fr;
    }
  }
</style>
