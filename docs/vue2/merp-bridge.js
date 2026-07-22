const READY_EVENT = 'MERPBridgeReady'
const DEFAULT_READY_TIMEOUT = 10000

function bridgeError(code, message, details) {
  return {
    code: code,
    message: message,
    details: details || {}
  }
}

function getNativeBridge() {
  if (typeof window === 'undefined') {
    return null
  }
  const bridge = window.MERPBridge
  return bridge && typeof bridge.call === 'function' ? bridge : null
}

function waitUntilReady(timeoutMs) {
  const bridge = getNativeBridge()
  if (bridge) {
    return Promise.resolve(bridge)
  }
  if (typeof window === 'undefined') {
    return Promise.reject(
      bridgeError('BRIDGE_UNAVAILABLE', '当前环境不支持手机端 Bridge')
    )
  }

  const waitMs = Number(timeoutMs) > 0
    ? Number(timeoutMs)
    : DEFAULT_READY_TIMEOUT

  return new Promise(function (resolve, reject) {
    let finished = false

    function cleanup() {
      window.removeEventListener(READY_EVENT, onReady)
      clearTimeout(timer)
    }

    function onReady() {
      const readyBridge = getNativeBridge()
      if (!readyBridge || finished) {
        return
      }
      finished = true
      cleanup()
      resolve(readyBridge)
    }

    const timer = setTimeout(function () {
      if (finished) {
        return
      }
      finished = true
      cleanup()
      reject(
        bridgeError(
          'BRIDGE_NOT_READY',
          '等待手机端 Bridge 注入超时，请在 MERP App 的 WebView 中打开页面',
          { timeoutMs: waitMs }
        )
      )
    }, waitMs)

    window.addEventListener(READY_EVENT, onReady)
    // 避免 Bridge 在首次检查与事件监听之间完成注入造成事件丢失。
    onReady()
  })
}

export const merpBridge = {
  isReady() {
    return Boolean(getNativeBridge())
  },

  waitUntilReady(timeoutMs) {
    return waitUntilReady(timeoutMs)
  },

  async call(action, payload) {
    if (typeof action !== 'string' || !action.trim()) {
      throw bridgeError('INVALID_ACTION', 'Bridge action 不能为空')
    }
    const bridge = await waitUntilReady()
    return bridge.call(action.trim(), payload || {})
  },

  getCurrentPosition(options) {
    return this.call('location.getCurrentPosition', options)
  },

  scanCode(options) {
    return this.call('scanner.scanCode', options)
  },

  takePhoto(options) {
    return this.call('camera.takePhoto', options)
  },

  pickFiles(options) {
    return this.call('file.pick', options)
  },

  getDeviceInfo() {
    return this.call('device.getInfo', {})
  },

  logout() {
    return this.call('auth.logout', {})
  },

  showSystemMessage(options) {
    return this.call('system.showMessage', options)
  },

  confirm(options) {
    return this.call('system.confirm', options)
  }
}

export default {
  install(Vue) {
    Object.defineProperty(Vue.prototype, '$merpBridge', {
      configurable: false,
      enumerable: false,
      value: merpBridge
    })
  }
}
