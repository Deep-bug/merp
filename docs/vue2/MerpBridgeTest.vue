<template>
  <div class="bridge-test">
    <header class="page-header">
      <h1>MERP 原生能力测试</h1>
      <span :class="['bridge-status', bridgeReady ? 'ready' : 'waiting']">
        {{ bridgeReady ? 'Bridge 已连接' : '等待手机端 Bridge' }}
      </span>
    </header>

    <main>
      <section class="action-grid">
        <button
          v-for="action in actions"
          :key="action.key"
          class="action-button"
          :disabled="!bridgeReady || loadingKey !== ''"
          @click="action.run"
        >
          <strong>{{ action.title }}</strong>
          <small>{{ loadingKey === action.key ? '调用中...' : action.note }}</small>
        </button>
      </section>

      <section v-if="photoPreview" class="preview-section">
        <h2>拍照预览</h2>
        <img :src="photoPreview" alt="手机拍照结果" />
      </section>

      <section class="result-section">
        <div class="result-header">
          <h2>调用结果</h2>
          <button class="clear-button" @click="logs = []">清空</button>
        </div>
        <p v-if="logs.length === 0" class="empty">点击上方按钮开始测试</p>
        <article
          v-for="item in logs"
          :key="item.id"
          :class="['result-item', item.ok ? 'success' : 'failure']"
        >
          <div>
            <strong>{{ item.title }}</strong>
            <time>{{ item.time }}</time>
          </div>
          <pre>{{ item.content }}</pre>
        </article>
      </section>
    </main>
  </div>
</template>

<script>
import { merpBridge } from './merp-bridge'

export default {
  name: 'MerpBridgeTest',

  data() {
    return {
      bridgeReady: merpBridge.isReady(),
      loadingKey: '',
      photoPreview: '',
      logs: []
    }
  },

  computed: {
    actions() {
      return [
        {
          key: 'location',
          title: '定位',
          note: '获取 BD-09 精确坐标',
          run: this.testLocation
        },
        {
          key: 'camera',
          title: '拍照',
          note: '启动系统相机并预览',
          run: this.testCamera
        },
        {
          key: 'file',
          title: '文件',
          note: '打开系统文件选择器',
          run: this.testFile
        },
        {
          key: 'device',
          title: '设备信息',
          note: '读取机型、系统及 App 版本',
          run: this.testDevice
        },
        {
          key: 'message',
          title: '系统消息',
          note: '显示原生消息对话框',
          run: this.testMessage
        },
        {
          key: 'confirm',
          title: '系统确认',
          note: '验证原生确认交互',
          run: this.testConfirm
        }
      ]
    }
  },

  mounted() {
    this.onBridgeReady = () => {
      this.bridgeReady = true
      this.appendLog('Bridge', true, {
        version: window.MERPBridge && window.MERPBridge.version
      })
    }
    window.addEventListener('MERPBridgeReady', this.onBridgeReady)
    if (this.bridgeReady) {
      this.onBridgeReady()
    }
  },

  beforeDestroy() {
    window.removeEventListener('MERPBridgeReady', this.onBridgeReady)
  },

  methods: {
    async invoke(key, title, action, payload) {
      this.loadingKey = key
      try {
        const result = await merpBridge.call(action, payload || {})
        this.appendLog(title, true, this.safeResult(result))
        return result
      } catch (error) {
        this.appendLog(title, false, error)
        return null
      } finally {
        this.loadingKey = ''
      }
    },

    testLocation() {
      return this.invoke(
        'location',
        '定位',
        'location.getCurrentPosition',
        { timeoutMs: 25000, maximumAccuracyMeters: 50 }
      )
    },

    async testCamera() {
      const result = await this.invoke(
        'camera',
        '拍照',
        'camera.takePhoto',
        { includeBase64: true, imageQuality: 82, maxWidth: 1440 }
      )
      this.photoPreview = result && result.dataUrl ? result.dataUrl : ''
    },

    testFile() {
      return this.invoke('file', '文件', 'file.pick', {
        allowMultiple: false,
        includeBase64: false,
        maximumFileBytes: 10 * 1024 * 1024,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'txt',
          'jpg',
          'jpeg',
          'png'
        ]
      })
    },

    testDevice() {
      return this.invoke('device', '设备信息', 'device.getInfo')
    },

    testMessage() {
      return this.invoke('message', '系统消息', 'system.showMessage', {
        mode: 'dialog',
        title: 'Vue2 Bridge 测试',
        message: '手机端系统消息调用成功'
      })
    },

    testConfirm() {
      return this.invoke('confirm', '系统确认', 'system.confirm', {
        title: '确认测试结果',
        message: '是否确认原生 Confirm 能力工作正常？'
      })
    },

    safeResult(value) {
      if (!value || typeof value !== 'object') {
        return value
      }
      const copy = JSON.parse(JSON.stringify(value))
      const hideBase64 = item => {
        if (item && item.base64) {
          item.base64 = `[Base64 ${item.base64.length} chars]`
        }
      }
      hideBase64(copy)
      if (Array.isArray(copy.files)) {
        copy.files.forEach(hideBase64)
      }
      return copy
    },

    appendLog(title, ok, value) {
      this.logs.unshift({
        id: `${Date.now()}_${Math.random()}`,
        title,
        ok,
        time: new Date().toLocaleTimeString(),
        content: JSON.stringify(value, null, 2)
      })
    }
  }
}
</script>

<style scoped>
.bridge-test {
  min-height: 100vh;
  padding: 16px;
  color: #253247;
  background: #f4f7fa;
  box-sizing: border-box;
}

.page-header,
.result-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.page-header h1 {
  margin: 0;
  font-size: 22px;
}

.bridge-status {
  padding: 6px 10px;
  border-radius: 4px;
  font-size: 12px;
}

.bridge-status.ready {
  color: #126a3a;
  background: #dff5e8;
}

.bridge-status.waiting {
  color: #8a5600;
  background: #fff0cf;
}

.action-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
  margin-top: 18px;
}

.action-button {
  min-height: 84px;
  padding: 12px;
  text-align: left;
  color: #1e3150;
  background: #fff;
  border: 1px solid #dce4ec;
  border-radius: 8px;
}

.action-button:disabled {
  opacity: 0.55;
}

.action-button strong,
.action-button small {
  display: block;
}

.action-button small {
  margin-top: 8px;
  color: #6c7889;
  line-height: 1.4;
}

.preview-section,
.result-section {
  margin-top: 18px;
}

.preview-section h2,
.result-section h2 {
  margin: 0 0 10px;
  font-size: 17px;
}

.preview-section img {
  display: block;
  width: 100%;
  max-height: 320px;
  object-fit: contain;
  background: #101820;
  border-radius: 8px;
}

.clear-button {
  padding: 6px 10px;
  color: #356da8;
  background: transparent;
  border: 1px solid #aac4df;
  border-radius: 4px;
}

.empty {
  padding: 28px 12px;
  text-align: center;
  color: #798596;
  background: #fff;
  border-radius: 8px;
}

.result-item {
  margin-bottom: 10px;
  padding: 12px;
  background: #fff;
  border-left: 4px solid;
  border-radius: 6px;
}

.result-item.success {
  border-color: #25a565;
}

.result-item.failure {
  border-color: #d24b4b;
}

.result-item > div {
  display: flex;
  justify-content: space-between;
}

.result-item time {
  color: #7d8794;
  font-size: 12px;
}

.result-item pre {
  overflow-x: auto;
  margin: 10px 0 0;
  font-size: 12px;
  line-height: 1.45;
  white-space: pre-wrap;
  word-break: break-word;
}

@media (min-width: 720px) {
  .action-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}
</style>
