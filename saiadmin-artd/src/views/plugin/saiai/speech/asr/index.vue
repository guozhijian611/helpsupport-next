<template>
  <div class="speech-test">
    <section class="toolbar-band">
      <div class="toolbar-inner">
        <div class="title-block">
          <h2>SAI ASR 转写测试</h2>
          <p>选择在线 ASR 配置，上传或录一段音频，验证文字聊天用的转写通道。</p>
        </div>
        <div class="actions">
          <el-select v-model="selectedConfigId" placeholder="选择 ASR 配置" class="config-select">
            <el-option
              v-for="item in configs"
              :key="item.id"
              :label="`${item.name} / ${item.model}`"
              :value="item.id"
            />
          </el-select>
          <el-button type="primary" :loading="loading" :disabled="!canSubmit" @click="handleTranscribe">
            开始转写
          </el-button>
        </div>
      </div>
    </section>

    <section class="control-grid">
      <div class="panel">
        <div class="panel-header">
          <h3>音频输入</h3>
          <el-tag :type="audioReady ? 'success' : 'info'">{{ audioReady ? '已就绪' : '待选择' }}</el-tag>
        </div>

        <el-upload
          drag
          :auto-upload="false"
          :limit="1"
          accept="audio/*,.mp3,.wav,.m4a,.webm,.ogg,.mp4"
          :on-change="handleFileChange"
          :on-remove="clearAudio"
        >
          <ArtSvgIcon icon="ri:upload-cloud-2-line" class="upload-icon" />
          <div class="el-upload__text">将音频拖到此处，或点击选择</div>
          <template #tip>
            <div class="el-upload__tip">支持 mp3 / wav / m4a / webm，不超过 20MB</div>
          </template>
        </el-upload>

        <div class="button-row">
          <el-button :type="recording ? 'danger' : 'default'" @click="toggleRecord">
            {{ recording ? '停止录音' : '麦克风录音' }}
          </el-button>
          <el-button :disabled="!audioFile" @click="clearAudio">清除</el-button>
        </div>

        <audio v-if="audioUrl" class="audio-player" :src="audioUrl" controls />
      </div>

      <div class="panel">
        <div class="panel-header">
          <h3>转写结果</h3>
          <el-tag :type="resultText ? 'success' : 'info'">{{ resultText ? '已完成' : '等待转写' }}</el-tag>
        </div>
        <el-input
          v-model="resultText"
          type="textarea"
          :rows="12"
          readonly
          placeholder="转写文本会显示在这里"
        />
        <p v-if="errorText" class="error-text">{{ errorText }}</p>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
  import { ElMessage } from 'element-plus'
  import type { UploadFile } from 'element-plus'
  import speechApi, { type SpeechConfigItem } from '../../api/speech'

  const configs = ref<SpeechConfigItem[]>([])
  const selectedConfigId = ref<number>()
  const audioFile = ref<File | null>(null)
  const audioUrl = ref('')
  const recording = ref(false)
  const loading = ref(false)
  const resultText = ref('')
  const errorText = ref('')

  let mediaRecorder: MediaRecorder | null = null
  let mediaStream: MediaStream | null = null
  let recordedChunks: Blob[] = []

  const audioReady = computed(() => !!audioFile.value)
  const canSubmit = computed(() => !!selectedConfigId.value && !!audioFile.value && !recording.value)

  onMounted(loadConfigs)
  onBeforeUnmount(() => {
    stopRecording(false)
    revokeAudioUrl()
  })

  async function loadConfigs() {
    configs.value = await speechApi.configs('asr')
    if (!selectedConfigId.value && configs.value.length > 0) {
      selectedConfigId.value = configs.value[0].id
    }
  }

  function handleFileChange(file: UploadFile) {
    setAudioFile(file.raw || null)
  }

  function setAudioFile(file: File | null) {
    revokeAudioUrl()
    audioFile.value = file
    audioUrl.value = file ? URL.createObjectURL(file) : ''
    resultText.value = ''
    errorText.value = ''
  }

  function clearAudio() {
    stopRecording(false)
    setAudioFile(null)
  }

  async function toggleRecord() {
    if (recording.value) {
      stopRecording(true)
      return
    }

    mediaStream = await navigator.mediaDevices.getUserMedia({ audio: true })
    recordedChunks = []
    mediaRecorder = new MediaRecorder(mediaStream)
    mediaRecorder.ondataavailable = (event) => {
      if (event.data.size > 0) recordedChunks.push(event.data)
    }
    mediaRecorder.onstop = () => {
      if (recordedChunks.length === 0) return
      setAudioFile(new File(recordedChunks, `asr-${Date.now()}.webm`, { type: 'audio/webm' }))
    }
    mediaRecorder.start()
    recording.value = true
  }

  function stopRecording(commit: boolean) {
    if (mediaRecorder && mediaRecorder.state !== 'inactive') {
      if (!commit) mediaRecorder.onstop = null
      mediaRecorder.stop()
    }
    mediaRecorder = null
    mediaStream?.getTracks().forEach((track) => track.stop())
    mediaStream = null
    recording.value = false
  }

  function revokeAudioUrl() {
    if (audioUrl.value) URL.revokeObjectURL(audioUrl.value)
    audioUrl.value = ''
  }

  async function handleTranscribe() {
    if (!selectedConfigId.value || !audioFile.value) {
      ElMessage.warning('请先选择 ASR 配置并准备音频')
      return
    }

    loading.value = true
    errorText.value = ''
    try {
      const formData = new FormData()
      formData.append('config_id', String(selectedConfigId.value))
      formData.append('file', audioFile.value)
      const result = await speechApi.asr(formData)
      resultText.value = result.text
      ElMessage.success('转写完成')
    } catch (error: any) {
      errorText.value = error?.message || '转写失败'
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
  .actions,
  .button-row {
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

  .title-block p {
    margin: 0;
    color: var(--el-text-color-secondary);
  }

  .config-select {
    width: 320px;
  }

  .control-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 16px;
  }

  .panel-header {
    margin-bottom: 16px;
  }

  .button-row {
    justify-content: flex-start;
    margin: 16px 0;
  }

  .audio-player {
    width: 100%;
  }

  .upload-icon {
    font-size: 36px;
    color: var(--el-text-color-secondary);
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
    .control-grid {
      width: 100%;
      grid-template-columns: 1fr;
    }
  }
</style>
